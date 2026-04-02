import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_tracking_service.dart';
import '../services/route_service.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  final String viewerRole; // 'citizen' | 'responder'

  const ReportDetailPage({
    super.key,
    required this.reportId,
    required this.viewerRole,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final LocationTrackingService _tracking = LocationTrackingService();
  final RouteService _routeService = RouteService();

  StreamSubscription? _trackingSub;

  bool _trackingStarted = false;
  bool _routeLoading = false;

  String? _lastRouteKey;
  Set<Polyline> _routePolylines = {};

  double? _distanceKm;
  String _etaText = '--';

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('reports').doc(widget.reportId);

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  String _statusLabelFromCode(String code) {
    switch (code) {
      case 'accepted_by_admin':
        return 'Accepted';
      case 'reported_to_lgu':
        return 'Reported to LGU';
      case 'under_surveillance':
        return 'Under Surveillance';
      case 'responder_dispatched':
        return 'Responder Dispatched';
      case 'problem_solved':
        return 'Solved';
      case 'denied_by_admin':
        return 'Denied';
      case 'pending_admin':
      default:
        return 'Pending Review';
    }
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
        _routePolylines = {
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
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('fallback'),
            width: 4,
            points: [citizen, responder],
          ),
        };
      });
    } finally {
      _routeLoading = false;
    }
  }

  Future<String?> _inputDialog({
    required String title,
    required String hint,
    required String buttonLabel,
    bool requiredField = false,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text;
              if (requiredField && text.trim().isEmpty) return;
              Navigator.pop(context, text);
            },
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _updateProgressAsResponder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msg = await _inputDialog(
      title: 'Update Progress',
      hint: 'Type your current action/progress...',
      buttonLabel: 'Save',
      requiredField: true,
    );
    if (msg == null || msg.trim().isEmpty) return;

    await _ref.update({
      'resolutionProgress': msg.trim(),
      'resolutionInProgress': 'in_progress',
      'statusCode': 'under_surveillance',
      'status': 'Under Surveillance',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'progress',
      'label': 'Progress Update',
      'message': msg.trim(),
      'statusCode': 'under_surveillance',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress updated.')));
  }

  Future<void> _markSolvedAsResponder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final resolution = await _inputDialog(
      title: 'Mark as Solved',
      hint: 'Resolution provided...',
      buttonLabel: 'Submit',
      requiredField: true,
    );
    if (resolution == null || resolution.trim().isEmpty) return;

    await _ref.update({
      'responderSolved': true,
      'citizenSolved': false,
      'resolutionProvidedByResponder': resolution.trim(),
      'resolutionText': resolution.trim(),
      'statusCode': 'problem_solved',
      'status': 'Resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'solved',
      'label': 'Solved',
      'message': 'Responder marked the problem as solved.',
      'statusCode': 'problem_solved',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked as solved.')));
  }

  Future<void> _confirmSolvedAsCitizen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _ref.update({
      'citizenSolved': true,
      'statusCode': 'problem_solved',
      'status': 'Resolved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'citizen_confirm',
      'label': 'Citizen Confirmed',
      'message': 'Citizen confirmed the report is solved.',
      'statusCode': 'problem_solved',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'citizen',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you! Confirmed solved.')),
    );
  }

  void _ensureResponderTracking({
    required bool assignedToMe,
    required bool responderSolved,
  }) {
    if (assignedToMe && !_trackingStarted && !responderSolved) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      _trackingStarted = true;
      _trackingSub?.cancel();
      _trackingSub = _tracking.startTracking(responderUid: currentUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Report Details'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text(
                'Report not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snap.data!.data() ?? <String, dynamic>{};

          final incidentName = _s(data['incidentName']);
          final description = _s(data['description']);
          final urgency = _s(data['urgencyLevel']);
          final locationText = _s(data['locationText']);

          final adminDecision = _s(data['adminDecision']).isEmpty
              ? 'pending'
              : _s(data['adminDecision']);
          final adminComment = _s(data['adminComment']);

          final statusCode = _s(data['statusCode']).isEmpty
              ? 'pending_admin'
              : _s(data['statusCode']);
          final statusLabel = _statusLabelFromCode(statusCode);

          final assignedResponderUid =
              _s(data['assignedResponderUid']).isNotEmpty
              ? _s(data['assignedResponderUid'])
              : _s(data['assignedResponderId']);

          final assignedResponderName = _s(data['assignedResponderName']);
          final assignedResponderPhone = _s(data['assignedResponderPhone']);

          final resolutionProgress = _s(data['resolutionProgress']);
          final resolutionProvided =
              _s(data['resolutionProvidedByResponder']).isNotEmpty
              ? _s(data['resolutionProvidedByResponder'])
              : _s(data['resolutionText']);

          final citizenSolved = data['citizenSolved'] == true;
          final responderSolved = data['responderSolved'] == true;
          final responderArrived =
              data['responderArrived'] == true ||
              data['responderOnLocation'] == true;

          final rawImages = data['imageUrls'];
          final imageUrls = (rawImages is List)
              ? rawImages.map((e) => _s(e)).where((e) => e.isNotEmpty).toList()
              : <String>[];

          LatLng? citizenLatLng;
          final loc = data['location'];
          if (loc is GeoPoint) {
            citizenLatLng = LatLng(loc.latitude, loc.longitude);
          }

          final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          final isResponderViewer = widget.viewerRole == 'responder';
          final assignedToMe =
              isResponderViewer &&
              assignedResponderUid.isNotEmpty &&
              assignedResponderUid == currentUid;

          _ensureResponderTracking(
            assignedToMe: assignedToMe,
            responderSolved: responderSolved,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrls.first,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      alignment: Alignment.center,
                      color: const Color(0xFF1A1F3A),
                      child: const Text(
                        'Image failed to load',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              if (imageUrls.isNotEmpty) const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incidentName.isEmpty ? 'Report' : incidentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row('Urgency', urgency),
                    _row('Location', locationText),
                    _row('Status', statusLabel),
                    _row('Admin', adminDecision),
                    if (responderArrived) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Responder is on the location',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (adminDecision.toLowerCase() == 'denied' &&
                        adminComment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Admin Comment: $adminComment',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      resolutionProgress.isEmpty
                          ? 'No update yet.'
                          : resolutionProgress,
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                    ),
                    if (responderSolved && resolutionProvided.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Resolution: $resolutionProvided',
                        style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (assignedResponderUid.isNotEmpty) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Responder',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${assignedResponderName.isEmpty ? 'Responder' : assignedResponderName}'
                        '${assignedResponderPhone.isEmpty ? '' : ' • $assignedResponderPhone'}',
                        style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (assignedResponderUid.isNotEmpty &&
                  citizenLatLng != null &&
                  !(citizenSolved || responderSolved)) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        responderArrived
                            ? 'Responder is on the Location'
                            : 'Responder is En Route',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 320,
                        child:
                            StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: FirebaseFirestore.instance
                                  .collection('responderLocations')
                                  .doc(assignedResponderUid)
                                  .snapshots(),
                              builder: (context, locSnap) {
                                LatLng? liveResponder;

                                if (locSnap.hasData && locSnap.data!.exists) {
                                  final locData =
                                      locSnap.data!.data() ??
                                      <String, dynamic>{};
                                  final rloc = locData['location'];

                                  if (rloc is GeoPoint) {
                                    liveResponder = LatLng(
                                      rloc.latitude,
                                      rloc.longitude,
                                    );

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _updateRoute(
                                            responder: liveResponder!,
                                            citizen: citizenLatLng!,
                                          );
                                        });
                                  }
                                }

                                final markers = <Marker>{
                                  Marker(
                                    markerId: const MarkerId('citizen'),
                                    position: citizenLatLng!,
                                    infoWindow: const InfoWindow(
                                      title: 'Citizen',
                                    ),
                                  ),
                                  if (liveResponder != null)
                                    Marker(
                                      markerId: const MarkerId('responder'),
                                      position: liveResponder,
                                      infoWindow: const InfoWindow(
                                        title: 'Responder',
                                      ),
                                    ),
                                };

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: liveResponder ?? citizenLatLng!,
                                      zoom: 15,
                                    ),
                                    markers: markers,
                                    polylines: _routePolylines,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                  ),
                                );
                              },
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        responderArrived
                            ? 'The responder has arrived at your location.'
                            : 'The responder is on the way to your location.',
                        style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Distance: ${_distanceKm == null ? '--' : _formatDistanceKm(_distanceKm!)} • ETA: $_etaText',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (widget.viewerRole == 'citizen') ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (responderSolved && !citizenSolved)
                        ? _confirmSolvedAsCitizen
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      responderSolved
                          ? 'Confirm Problem Solved'
                          : responderArrived
                          ? 'Responder is on Location'
                          : 'Responder En Route',
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        assignedToMe && !(citizenSolved || responderSolved)
                        ? _updateProgressAsResponder
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Update Progress'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        assignedToMe && !(citizenSolved || responderSolved)
                        ? _markSolvedAsResponder
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Mark as Solved'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? '-' : v,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
