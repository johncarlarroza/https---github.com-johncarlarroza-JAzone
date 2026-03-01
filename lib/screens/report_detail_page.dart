import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_tracking_service.dart';

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
  final _tracking = LocationTrackingService();
  StreamSubscription? _trackingSub;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('reports').doc(widget.reportId);

  bool _trackingStarted = false;

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

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
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'progress',
      'label': 'Progress Update',
      'message': msg.trim(),
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
      'resolutionProvidedByResponder': resolution.trim(),
      'status': 'solved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'solved',
      'label': 'Solved',
      'message': 'Responder marked the problem as solved.',
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
      'status': 'solved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'citizen_confirm',
      'label': 'Citizen Confirmed',
      'message': 'Citizen confirmed the report is solved.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'citizen',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you! Confirmed solved.')),
    );
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

          final data = snap.data!.data() ?? {};

          final incidentName = _s(data['incidentName']);
          final description = _s(data['description']);
          final urgency = _s(data['urgencyLevel']);
          final locationText = _s(data['locationText']);

          final adminDecision = _s(data['adminDecision']).isEmpty
              ? 'pending'
              : _s(data['adminDecision']);
          final adminComment = _s(data['adminComment']);

          final assignedResponderUid = _s(data['assignedResponderUid']);
          final assignedResponderName = _s(data['assignedResponderName']);
          final assignedResponderPhone = _s(data['assignedResponderPhone']);

          final resolutionProgress = _s(data['resolutionProgress']);
          final resolutionProvided = _s(data['resolutionProvidedByResponder']);

          final citizenSolved = data['citizenSolved'] == true;
          final responderSolved = data['responderSolved'] == true;

          // images
          final rawImages = data['imageUrls'];
          final imageUrls = (rawImages is List)
              ? rawImages.map((e) => _s(e)).where((e) => e.isNotEmpty).toList()
              : <String>[];

          // location
          LatLng? citizenLatLng;
          final loc = data['location'];
          if (loc is GeoPoint) {
            citizenLatLng = LatLng(loc.latitude, loc.longitude);
          }

          // Start responder tracking if responder is viewing AND is assigned
          final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          final isResponderViewer = widget.viewerRole == 'responder';
          final assignedToMe =
              isResponderViewer &&
              assignedResponderUid.isNotEmpty &&
              assignedResponderUid == currentUid;

          if (assignedToMe && !_trackingStarted && !responderSolved) {
            _trackingStarted = true;
            _trackingSub?.cancel();
            _trackingSub = _tracking.startTracking(responderUid: currentUid);
          }

          // status label (simple + based on your fields)
          String statusLabel;
          if (citizenSolved || responderSolved) {
            statusLabel = 'Solved';
          } else if (adminDecision.toLowerCase() == 'denied') {
            statusLabel = 'Denied';
          } else if (assignedResponderUid.isNotEmpty) {
            statusLabel = 'Responder Assigned';
          } else if (adminDecision.toLowerCase() == 'accepted') {
            statusLabel = 'Approved by Admin';
          } else {
            statusLabel = 'Pending Review';
          }

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
                    const SizedBox(height: 10),
                    _row('Admin', adminDecision),
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
                      'Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusLabel,
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

              // Tracking map for citizen (and also responder can view)
              if (assignedResponderUid.isNotEmpty &&
                  citizenLatLng != null &&
                  !(citizenSolved || responderSolved)) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Responder Tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 280,
                        child: _trackingMap(
                          citizen: citizenLatLng,
                          responderUid: assignedResponderUid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Buttons
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
                          ? 'Confirm Solved'
                          : 'Waiting for Responder',
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

  Widget _trackingMap({required LatLng citizen, required String responderUid}) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('responderLocations')
          .doc(responderUid)
          .snapshots(),
      builder: (context, snap) {
        LatLng? responder;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() ?? {};
          final loc = d['location'];
          if (loc is GeoPoint) responder = LatLng(loc.latitude, loc.longitude);
        }

        final markers = <Marker>{
          Marker(markerId: const MarkerId('citizen'), position: citizen),
          if (responder != null)
            Marker(markerId: const MarkerId('responder'), position: responder),
        };

        final camera = CameraPosition(target: responder ?? citizen, zoom: 15);

        return GoogleMap(
          initialCameraPosition: camera,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      },
    );
  }
}
