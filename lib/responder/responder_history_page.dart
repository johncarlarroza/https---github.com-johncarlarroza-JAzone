import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/report_detail_page.dart';

class ResponderHistoryPage extends StatelessWidget {
  const ResponderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('History'),
      ),
      body: user == null
          ? const Center(child: Text('Please login', style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('assignedResponderUid', isEqualTo: user.uid)
                  .orderBy('updatedAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text('No history.', style: TextStyle(color: Colors.white.withOpacity(0.75))));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final id = docs[i].id;

                    final incident = (d['incidentName'] ?? '').toString();
                    final status = (d['status'] ?? '').toString();
                    final decision = (d['adminDecision'] ?? '').toString();
                    final responderDecision = (d['responderDecision'] ?? '').toString();
                    final denyReason = (d['responderDenyReason'] ?? '').toString();
                    final adminComment = (d['adminComment'] ?? '').toString();

                    final subtitle = responderDecision == 'denied'
                        ? 'Denied • ${denyReason.isEmpty ? 'No reason provided' : denyReason}'
                        : 'Admin: $decision • Status: ${status.isEmpty ? '-' : status}';

                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportDetailPage(reportId: id, viewerRole: 'responder')),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F3A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(incident.isEmpty ? 'Unnamed Incident' : incident,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                            if (decision == 'denied' && adminComment.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Admin comment: $adminComment', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                            ],
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
