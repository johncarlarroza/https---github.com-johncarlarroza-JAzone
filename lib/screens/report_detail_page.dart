import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_tracking_service.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId; // incident doc id
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

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('incidents').doc(widget.reportId);

  Future<void> _markSolvedAsCitizen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _ref.update({
      'progress.solved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'solved',
      'message': 'Citizen marked the incident as solved.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'citizen',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked as solved.')));
  }

  Future<void> _responderAccept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _ref.update({
      'progress.accepted': true,
      'progress.onAction': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ref.collection('timeline').add({
      'type': 'responder_accept',
      'message': 'Responder accepted and is now on action.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    // tracking (optional)
    _trackingSub?.cancel();
    _trackingSub = _tracking.startTracking(responderUid: user.uid);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accepted. Tracking started.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Incident Details'),
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
                'Incident not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snap.data!.data() ?? {};

          final name = (data['name'] ?? '').toString();
          final desc = (data['description'] ?? '').toString();
          final address = (data['address'] ?? '').toString();
          final imageUrl = (data['imageUrl'] ?? '').toString();

          final lat = (data['latitude'] is num)
              ? (data['latitude'] as num).toDouble()
              : null;
          final lng = (data['longitude'] is num)
              ? (data['longitude'] as num).toDouble()
              : null;

          final progress = (data['progress'] is Map)
              ? Map<String, dynamic>.from(data['progress'])
              : <String, dynamic>{};

          final accepted = progress['accepted'] == true;
          final onAction = progress['onAction'] == true;
          final solved = progress['solved'] == true;

          final statusText = solved
              ? 'Solved'
              : accepted
              ? (onAction ? 'On Action' : 'Accepted')
              : 'Pending';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Incident' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row('Status', statusText),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _row('Address', address),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      desc.isEmpty ? '—' : desc,
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (imageUrl.isNotEmpty)
                _card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),

              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Geolocation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row('Latitude', lat?.toString() ?? '—'),
                    _row('Longitude', lng?.toString() ?? '—'),
                    const SizedBox(height: 8),
                    const Text(
                      'Map view disabled (no Google Maps API).',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (widget.viewerRole == 'citizen') ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: solved ? null : _markSolvedAsCitizen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Problem Solved'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: accepted ? null : _responderAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Accept'),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
