import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_tracking_service.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  final String viewerRole; // 'citizen' | 'responder'
  const ReportDetailPage({super.key, required this.reportId, required this.viewerRole});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _tracking = LocationTrackingService();
  StreamSubscription? _trackingSub;

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('reports').doc(widget.reportId);

  Future<void> _markSolvedAsCitizen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _ref.update({
      'citizenSolved': true,
      'status': 'problem_solved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'solved',
      'label': 'Problem Solved',
      'message': 'Citizen marked the problem as solved.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'citizen',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as solved.')));
  }

  Future<void> _responderAccept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _ref.update({
      'responderDecision': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'responder_decision',
      'label': 'Responder Accepted',
      'message': 'Responder accepted the assignment.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    // Start tracking responder location
    _trackingSub?.cancel();
    _trackingSub = _tracking.startTracking(responderUid: user.uid);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted. Tracking started.')));
  }

  Future<void> _responderDeny() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reason = await _inputDialog(
      title: 'Deny request',
      hint: 'Optional reason',
      buttonLabel: 'Deny',
    );

    await _ref.update({
      'responderDecision': 'denied',
      'responderDenyReason': (reason ?? '').trim().isEmpty ? null : reason!.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'responder_decision',
      'label': 'Responder Denied',
      'message': (reason ?? '').trim().isEmpty ? 'Responder denied the assignment.' : reason!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denied. Admin will be notified by dashboard.')));
  }

  Future<void> _markSolvedAsResponder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final resolution = await _inputDialog(
      title: 'Problem Solved',
      hint: 'Resolution provided',
      buttonLabel: 'Submit',
      requiredField: true,
    );
    if (resolution == null || resolution.trim().isEmpty) return;

    await _ref.update({
      'responderSolved': true,
      'resolutionProvidedByResponder': resolution.trim(),
      'status': 'problem_solved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'solved',
      'label': 'Problem Solved',
      'message': 'Responder marked the problem as solved.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as solved.')));
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
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
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
            return const Center(child: Text('Report not found', style: TextStyle(color: Colors.white)));
          }

          final data = snap.data!.data() ?? {};
          final incidentName = (data['incidentName'] ?? '').toString();
          final urgency = (data['urgencyLevel'] ?? '').toString();
          final locationText = (data['locationText'] ?? '').toString();
          final status = (data['status'] ?? '').toString();
          final adminDecision = (data['adminDecision'] ?? 'pending').toString();
          final adminComment = (data['adminComment'] ?? '').toString();
          final resolutionProgress = (data['resolutionProgress'] ?? '').toString();

          final assignedResponderName = (data['assignedResponderName'] ?? '').toString();
          final assignedResponderPhone = (data['assignedResponderPhone'] ?? '').toString();
          final assignedResponderUid = (data['assignedResponderUid'] ?? '').toString();

          final citizenSolved = data['citizenSolved'] == true;
          final responderSolved = data['responderSolved'] == true;

          final location = data['location'];
          LatLng? citizenLatLng;
          if (location is GeoPoint) {
            citizenLatLng = LatLng(location.latitude, location.longitude);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incidentName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _row('Urgency', urgency),
                    _row('Location', locationText),
                    const SizedBox(height: 10),
                    _row('Admin Decision', adminDecision),
                    if (adminDecision == 'denied' && adminComment.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Admin Comment: $adminComment', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resolution progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      resolutionProgress.trim().isEmpty ? 'No update yet.' : resolutionProgress,
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _statusTracker(status),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (status == 'responder_dispatched' && assignedResponderUid.isNotEmpty && citizenLatLng != null) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Responder Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      if (assignedResponderName.isNotEmpty || assignedResponderPhone.isNotEmpty)
                        Text(
                          '${assignedResponderName.isEmpty ? 'Responder' : assignedResponderName}  ${assignedResponderPhone.isEmpty ? '' : '• $assignedResponderPhone'}',
                          style: TextStyle(color: Colors.white.withOpacity(0.85)),
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

              if (widget.viewerRole == 'citizen') ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (status == 'problem_solved' || citizenSolved || responderSolved) ? null : _markSolvedAsCitizen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Problem Solved'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _responderDeny,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.25)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Deny'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _responderAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (status == 'problem_solved' || citizenSolved || responderSolved) ? null : _markSolvedAsResponder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Problem Solved'),
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
          SizedBox(width: 120, child: Text(k, style: TextStyle(color: Colors.white.withOpacity(0.7)))),
          Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _statusTracker(String status) {
    final steps = const [
      ('accepted_by_admin', 'Accepted by the Admin'),
      ('reported_to_lgu', 'Reported to LGU'),
      ('under_surveillance', 'Under Surveillance'),
      ('responder_dispatched', 'Responder Dispatched'),
      ('problem_solved', 'Problem Solved'),
    ];

    int currentIndex = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].$1 == status) currentIndex = i;
    }

    return Column(
      children: List.generate(steps.length, (i) {
        final done = currentIndex >= i && currentIndex != -1;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? const Color(0xFFFF6B35) : Colors.white.withOpacity(0.35)),
          title: Text(steps[i].$2, style: TextStyle(color: Colors.white.withOpacity(done ? 1 : 0.7))),
        );
      }),
    );
  }

  Widget _trackingMap({required LatLng citizen, required String responderUid}) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('responderLocations').doc(responderUid).snapshots(),
      builder: (context, snap) {
        LatLng? responder;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() ?? {};
          final loc = d['location'];
          if (loc is GeoPoint) responder = LatLng(loc.latitude, loc.longitude);
        }

        final markers = <Marker>{
          Marker(markerId: const MarkerId('citizen'), position: citizen),
          if (responder != null) Marker(markerId: const MarkerId('responder'), position: responder),
        };

        final center = responder ?? citizen;

        return GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 15),
          markers: markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      },
    );
  }
}
