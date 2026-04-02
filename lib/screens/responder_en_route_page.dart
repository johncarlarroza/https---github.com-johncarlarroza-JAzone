import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_tracking_service.dart';
import '../services/route_service.dart';

class ResponderEnRoutePage extends StatefulWidget {
  final String reportId;
  final String responderUid;

  const ResponderEnRoutePage({
    super.key,
    required this.reportId,
    required this.responderUid,
  });

  @override
  State<ResponderEnRoutePage> createState() => _ResponderEnRoutePageState();
}

class _ResponderEnRoutePageState extends State<ResponderEnRoutePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RouteService _routeService = RouteService();
  final LocationTrackingService _trackingService = LocationTrackingService();

  StreamSubscription? _trackingSub;

  bool _routeLoading = false;
  bool _busyAction = false;
  String? _lastRouteKey;

  Set<Polyline> _polylines = {};
  double? _distanceKm;
  String _etaText = '--';

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    _trackingSub = _trackingService.startTracking(
      responderUid: widget.responderUid,
    );
  }

  double _directDistanceKm(LatLng a, LatLng b) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final x =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.latitude)) *
            math.cos(_degToRad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  String _formatDistanceKm(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  String _formatEtaFromKm(double km) {
    const avgSpeedKmh = 30.0;
    final hours = km / avgSpeedKmh;
    final mins = (hours * 60).ceil();
    return '$mins min';
  }

  Future<void> _updateRoute({
    required LatLng responder,
    required LatLng citizen,
  }) async {
    final key =
        '${responder.latitude},${responder.longitude}->${citizen.latitude},${citizen.longitude}';

    if (_routeLoading || _lastRouteKey == key) return;
    _routeLoading = true;

    try {
      final points = await _routeService.getRoute(
        startLat: responder.latitude,
        startLng: responder.longitude,
        endLat: citizen.latitude,
        endLng: citizen.longitude,
      );

      final distanceKm = _directDistanceKm(responder, citizen);

      if (!mounted) return;

      setState(() {
        _lastRouteKey = key;
        _distanceKm = distanceKm;
        _etaText = _formatEtaFromKm(distanceKm);
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            width: 5,
            points: points.map((p) => LatLng(p.lat, p.lng)).toList(),
          ),
        };
      });
    } catch (_) {
      final distanceKm = _directDistanceKm(responder, citizen);

      if (!mounted) return;

      setState(() {
        _lastRouteKey = key;
        _distanceKm = distanceKm;
        _etaText = _formatEtaFromKm(distanceKm);
        _polylines = {
          Polyline(
            polylineId: const PolylineId('fallback'),
            width: 4,
            points: [responder, citizen],
          ),
        };
      });
    } finally {
      _routeLoading = false;
    }
  }

  Future<void> _markOnLocation() async {
    if (_busyAction) return;
    setState(() => _busyAction = true);

    try {
      await _db.collection('reports').doc(widget.reportId).set({
        'responderArrived': true,
        'responderOnLocation': true,
        'responderArrivedAt': FieldValue.serverTimestamp(),
        'statusCode': 'under_surveillance',
        'status': 'Responder On Location',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db
          .collection('reports')
          .doc(widget.reportId)
          .collection('timeline')
          .add({
            'type': 'arrived',
            'label': 'Responder On Location',
            'message': 'Responder has arrived at the citizen location.',
            'statusCode': 'under_surveillance',
            'createdAt': FieldValue.serverTimestamp(),
            'createdByUid': widget.responderUid,
            'createdByRole': 'responder',
          });

      final reportDoc = await _db
          .collection('reports')
          .doc(widget.reportId)
          .get();
      final data = reportDoc.data() ?? <String, dynamic>{};
      final citizenUid = (data['citizenUid'] ?? '').toString().trim();

      if (citizenUid.isNotEmpty) {
        await _db
            .collection('users')
            .doc(citizenUid)
            .collection('notifications')
            .add({
              'title': 'Responder arrived',
              'body': 'The responder is now on the location.',
              'type': 'responder_arrived',
              'reportId': widget.reportId,
              'incidentId': widget.reportId,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Citizen has been informed: On the Location'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update arrival: $e')));
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
  }

  Future<void> _markProblemSolved() async {
    if (_busyAction) return;

    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Problem Solved'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter the resolution details...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final resolution = controller.text.trim();
    if (resolution.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the resolution details.')),
      );
      return;
    }

    setState(() => _busyAction = true);

    try {
      await _db.collection('reports').doc(widget.reportId).set({
        'responderSolved': true,
        'citizenSolved': false,
        'resolutionProvidedByResponder': resolution,
        'resolutionText': resolution,
        'solvedBy': 'responder',
        'resolvedAt': FieldValue.serverTimestamp(),
        'statusCode': 'problem_solved',
        'status': 'Resolved',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db
          .collection('reports')
          .doc(widget.reportId)
          .collection('timeline')
          .add({
            'type': 'solved',
            'label': 'Problem Solved',
            'message': 'Responder marked the problem as solved.',
            'statusCode': 'problem_solved',
            'createdAt': FieldValue.serverTimestamp(),
            'createdByUid': widget.responderUid,
            'createdByRole': 'responder',
          });

      final reportDoc = await _db
          .collection('reports')
          .doc(widget.reportId)
          .get();
      final data = reportDoc.data() ?? <String, dynamic>{};
      final citizenUid = (data['citizenUid'] ?? '').toString().trim();

      if (citizenUid.isNotEmpty) {
        await _db
            .collection('users')
            .doc(citizenUid)
            .collection('notifications')
            .add({
              'title': 'Problem solved',
              'body': 'The responder marked your report as solved.',
              'type': 'solved',
              'reportId': widget.reportId,
              'incidentId': widget.reportId,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      await _db.collection('users').doc(widget.responderUid).set({
        'availabilityStatus': 'available',
        'isOnline': true,
        'locationEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem marked as solved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark solved: $e')));
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportRef = _db.collection('reports').doc(widget.reportId);
    final responderRef = _db
        .collection('responderLocations')
        .doc(widget.responderUid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('En Route'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: reportRef.snapshots(),
        builder: (context, reportSnap) {
          if (!reportSnap.hasData || !reportSnap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = reportSnap.data!.data() ?? <String, dynamic>{};
          final loc = report['location'];

          if (loc is! GeoPoint) {
            return const Center(child: Text('Citizen location not found'));
          }

          final citizen = LatLng(loc.latitude, loc.longitude);
          final responderArrived =
              report['responderArrived'] == true ||
              report['responderOnLocation'] == true;
          final responderSolved = report['responderSolved'] == true;
          final citizenSolved = report['citizenSolved'] == true;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: responderRef.snapshots(),
            builder: (context, responderSnap) {
              LatLng? responder;

              if (responderSnap.hasData && responderSnap.data!.exists) {
                final data = responderSnap.data!.data() ?? {};
                final rloc = data['location'];
                if (rloc is GeoPoint) {
                  responder = LatLng(rloc.latitude, rloc.longitude);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateRoute(responder: responder!, citizen: citizen);
                  });
                }
              }

              final markers = <Marker>{
                Marker(
                  markerId: const MarkerId('citizen'),
                  position: citizen,
                  infoWindow: const InfoWindow(title: 'Citizen'),
                ),
                if (responder != null)
                  Marker(
                    markerId: const MarkerId('responder'),
                    position: responder,
                    infoWindow: const InfoWindow(title: 'You'),
                  ),
              };

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: responder ?? citizen,
                      zoom: 15,
                    ),
                    markers: markers,
                    polylines: _polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(blurRadius: 12, color: Colors.black26),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'En Route',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            responderArrived
                                ? 'You are now on the location.'
                                : 'Proceed to the citizen location.',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Distance: ${_distanceKm == null ? '--' : _formatDistanceKm(_distanceKm!)} • ETA: $_etaText',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          if (!responderArrived && !responderSolved)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _busyAction ? null : _markOnLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('On the Location'),
                              ),
                            ),
                          if (!responderSolved)
                            Padding(
                              padding: EdgeInsets.only(
                                top: responderArrived ? 0 : 10,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _busyAction
                                      ? null
                                      : _markProblemSolved,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Problem Solved'),
                                ),
                              ),
                            ),
                          if (responderSolved || citizenSolved) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'This report is already marked as solved.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
