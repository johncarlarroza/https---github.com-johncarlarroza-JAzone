import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/report_detail_page.dart';

class ResponderHomePage extends StatelessWidget {
  const ResponderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Assigned Requests'),
      ),
      body: user == null
          ? const Center(child: Text('Please login', style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('assignedResponderUid', isEqualTo: user.uid)
                  .where('adminDecision', isEqualTo: 'accepted')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No assigned requests.', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final id = docs[i].id;

                    final incident = (d['incidentName'] ?? '').toString();
                    final urgency = (d['urgencyLevel'] ?? '').toString();
                    final status = (d['status'] ?? '').toString();
                    final locationText = (d['locationText'] ?? '').toString();

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
                            Text('Urgency: ${urgency.isEmpty ? '-' : urgency}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                            const SizedBox(height: 4),
                            Text('Location: ${locationText.isEmpty ? '-' : locationText}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                            const SizedBox(height: 4),
                            Text('Status: ${status.isEmpty ? '-' : status}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
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
