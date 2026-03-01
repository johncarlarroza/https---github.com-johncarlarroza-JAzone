import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/report_detail_page.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  String _safeStr(dynamic v) => (v ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Alerts'),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please login',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('citizenUid', isEqualTo: user.uid)
                  .orderBy('updatedAt', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No alerts yet.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final docId = docs[i].id;

                    final incident = _safeStr(d['incidentName']);
                    final status = _safeStr(d['status']);
                    final adminDecision = _safeStr(
                      d['adminDecision'],
                    ).toLowerCase(); // pending/accepted/denied
                    final adminComment = _safeStr(d['adminComment']);

                    final resolverInProgress = _safeStr(
                      d['resolutionInProgress'],
                    );
                    final responderSolved = d['responderSolved'] == true;
                    final citizenSolved = d['citizenSolved'] == true;

                    String headline;
                    IconData icon;

                    if (adminDecision == 'denied') {
                      headline = 'Denied';
                      icon = Icons.cancel;
                    } else if (adminDecision == 'accepted') {
                      headline = 'Accepted';
                      icon = Icons.check_circle;
                    } else {
                      headline = 'Pending';
                      icon = Icons.hourglass_bottom;
                    }

                    final details = <String>[];

                    if (status.isNotEmpty) details.add('Status: $status');
                    if (resolverInProgress.isNotEmpty)
                      details.add('Progress: $resolverInProgress');
                    if (responderSolved) details.add('Responder marked solved');
                    if (citizenSolved) details.add('You confirmed solved');
                    if (adminDecision == 'denied' && adminComment.isNotEmpty) {
                      details.add('Reason: $adminComment');
                    }

                    final sub = details.isEmpty
                        ? 'Tap to view details.'
                        : details.join(' • ');

                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailPage(
                            reportId: docId,
                            viewerRole: 'citizen',
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F3A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: const Color(0xFFFF6B35)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    incident.isEmpty
                                        ? 'Report Update'
                                        : incident,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$headline • $sub',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
