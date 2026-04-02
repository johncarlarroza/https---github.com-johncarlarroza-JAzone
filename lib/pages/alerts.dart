import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/report_detail_page.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  String _safeStr(dynamic v) => (v ?? '').toString().trim();

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
        return 'Pending';
    }
  }

  IconData _iconForStatus(String code) {
    switch (code) {
      case 'accepted_by_admin':
        return Icons.check_circle;
      case 'reported_to_lgu':
        return Icons.account_balance;
      case 'under_surveillance':
        return Icons.visibility;
      case 'responder_dispatched':
        return Icons.local_shipping;
      case 'problem_solved':
        return Icons.verified;
      case 'denied_by_admin':
        return Icons.cancel;
      case 'pending_admin':
      default:
        return Icons.hourglass_bottom;
    }
  }

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
                    final adminComment = _safeStr(d['adminComment']);
                    final resolutionProgress = _safeStr(
                      d['resolutionProgress'],
                    );
                    final resolutionProvided = _safeStr(
                      d['resolutionProvidedByResponder'],
                    );
                    final assignedResponderName = _safeStr(
                      d['assignedResponderName'],
                    );

                    final adminDecision = _safeStr(
                      d['adminDecision'],
                    ).toLowerCase();
                    final statusCode = _safeStr(d['statusCode']).isNotEmpty
                        ? _safeStr(d['statusCode'])
                        : 'pending_admin';

                    final responderSolved = d['responderSolved'] == true;
                    final citizenSolved = d['citizenSolved'] == true;

                    final label = _statusLabelFromCode(statusCode);
                    final icon = _iconForStatus(statusCode);

                    final details = <String>[];

                    if (assignedResponderName.isNotEmpty &&
                        statusCode == 'responder_dispatched') {
                      details.add('Assigned: $assignedResponderName');
                    }

                    if (resolutionProgress.isNotEmpty) {
                      details.add('Progress: $resolutionProgress');
                    }

                    if (resolutionProvided.isNotEmpty && responderSolved) {
                      details.add('Resolution: $resolutionProvided');
                    }

                    if (citizenSolved) {
                      details.add('You confirmed solved');
                    } else if (responderSolved) {
                      details.add('Responder marked solved');
                    }

                    if ((statusCode == 'denied_by_admin' ||
                            adminDecision == 'denied') &&
                        adminComment.isNotEmpty) {
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
                                    '$label • $sub',
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
