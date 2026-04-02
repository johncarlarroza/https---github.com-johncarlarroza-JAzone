import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jazone_1/screens/report_detail_page.dart';
import 'package:jazone_1/screens/responder_en_route_page.dart';

import '../services/location_tracking_service.dart';

class ResponderHomePage extends StatefulWidget {
  const ResponderHomePage({super.key});

  @override
  State<ResponderHomePage> createState() => _ResponderHomePageState();
}

class _ResponderHomePageState extends State<ResponderHomePage>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocationTrackingService _trackingService = LocationTrackingService();

  bool _availabilityOn = false;
  bool _loadingAvailability = true;
  bool _changingAvailability = false;

  String? _openedEnRouteForReportId;

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_availabilityOn) return;

    if (state == AppLifecycleState.resumed) {
      _setOnlineBecauseActive();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _setOfflineBecauseInactive();
    }
  }

  Future<void> _loadAvailability() async {
    final user = _user;
    if (user == null) {
      if (mounted) {
        setState(() {
          _availabilityOn = false;
          _loadingAvailability = false;
        });
      }
      return;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};

      final enabled = data['locationEnabled'] == true;
      final availabilityStatus = (data['availabilityStatus'] ?? '')
          .toString()
          .toLowerCase();

      if (!mounted) return;
      setState(() {
        _availabilityOn =
            enabled ||
            availabilityStatus == 'available' ||
            availabilityStatus == 'on_dispatch';
        _loadingAvailability = false;
      });

      if (_availabilityOn) {
        await _setOnlineBecauseActive();
      } else {
        await _updateAvailability(
          locationEnabled: false,
          availabilityStatus: 'offline',
          isOnline: false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availabilityOn = false;
        _loadingAvailability = false;
      });
    }
  }

  Future<void> _updateAvailability({
    required bool locationEnabled,
    required String availabilityStatus,
    required bool isOnline,
  }) async {
    final user = _user;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'locationEnabled': locationEnabled,
      'availabilityStatus': availabilityStatus,
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _setOnlineBecauseActive() async {
    final user = _user;
    if (user == null) return;

    final currentDoc = await _db.collection('users').doc(user.uid).get();
    final currentData = currentDoc.data() ?? <String, dynamic>{};
    final currentStatus = (currentData['availabilityStatus'] ?? '')
        .toString()
        .toLowerCase();

    final nextStatus = currentStatus == 'on_dispatch'
        ? 'on_dispatch'
        : 'available';

    await _updateAvailability(
      locationEnabled: true,
      availabilityStatus: nextStatus,
      isOnline: true,
    );

    try {
      await _trackingService.startTracking(responderUid: user.uid);
    } catch (_) {}
  }

  Future<void> _setOfflineBecauseInactive() async {
    final user = _user;
    if (user == null) return;

    try {
      await _trackingService.stopTracking();
    } catch (_) {}

    await _updateAvailability(
      locationEnabled: false,
      availabilityStatus: 'offline',
      isOnline: false,
    );
  }

  Future<void> _setOnDispatch() async {
    final user = _user;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'locationEnabled': true,
      'availabilityStatus': 'on_dispatch',
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _toggleAvailability(bool value) async {
    final user = _user;
    if (user == null) return;

    setState(() => _changingAvailability = true);

    try {
      if (value) {
        await _updateAvailability(
          locationEnabled: true,
          availabilityStatus: 'available',
          isOnline: true,
        );

        await _trackingService.startTracking(responderUid: user.uid);
      } else {
        try {
          await _trackingService.stopTracking();
        } catch (_) {}

        await _updateAvailability(
          locationEnabled: false,
          availabilityStatus: 'offline',
          isOnline: false,
        );
      }

      if (!mounted) return;
      setState(() {
        _availabilityOn = value;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _changingAvailability = false);
      }
    }
  }

  String _availabilityLabel(Map<String, dynamic> data) {
    final isOnline = data['isOnline'] == true;
    final status = (data['availabilityStatus'] ?? '').toString().toLowerCase();

    if (!isOnline || status == 'offline') return 'Offline';
    if (status == 'on_dispatch') return 'On Dispatch';
    if (status == 'available') return 'Online';
    return 'Offline';
  }

  Color _availabilityColor(String label) {
    switch (label) {
      case 'Online':
        return const Color(0xFF22C55E);
      case 'On Dispatch':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

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

  bool _shouldShowOnHome(Map<String, dynamic> d) {
    final responderDecision = (d['responderDecision'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final assignedResponderStatus = (d['assignedResponderStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final statusCode = (d['statusCode'] ?? '').toString().trim().toLowerCase();

    final adminDecision = (d['adminDecision'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    // Only assigned and admin-approved requests should ever be considered here
    if (adminDecision != 'accepted') return false;

    // Remove from homepage once responder already accepted or denied
    if (responderDecision == 'accepted' || responderDecision == 'denied') {
      return false;
    }

    if (assignedResponderStatus == 'accepted' ||
        assignedResponderStatus == 'denied') {
      return false;
    }

    // Optional safety: solved/closed/denied items should not stay on home
    if (statusCode == 'problem_solved' || statusCode == 'denied_by_admin') {
      return false;
    }

    return true;
  }

  Future<void> _acceptAndOpenEnRoute(String reportId) async {
    final user = _user;
    if (user == null) return;

    await _db.collection('reports').doc(reportId).set({
      'responderDecision': 'accepted',
      'assignedResponderStatus': 'accepted',
      'responderDecisionAt': FieldValue.serverTimestamp(),
      'statusCode': 'responder_dispatched',
      'status': 'Responder Dispatched',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('reports').doc(reportId).collection('timeline').add({
      'type': 'responder_accept',
      'label': 'Responder Accepted',
      'message': 'Responder accepted and is now en route.',
      'statusCode': 'responder_dispatched',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    await _setOnDispatch();

    if (!mounted) return;
    _openedEnRouteForReportId = reportId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResponderEnRoutePage(reportId: reportId, responderUid: user.uid),
      ),
    );
  }

  Future<void> _denyRequest(String reportId) async {
    final user = _user;
    if (user == null) return;

    await _db.collection('reports').doc(reportId).set({
      'responderDecision': 'denied',
      'assignedResponderStatus': 'denied',
      'responderDecisionAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('reports').doc(reportId).collection('timeline').add({
      'type': 'responder_deny',
      'label': 'Responder Denied',
      'message': 'Responder denied this assigned request.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user.uid,
      'createdByRole': 'responder',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request denied. It has been removed from Home.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Assigned Requests'),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please login',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('users').doc(user.uid).snapshots(),
                  builder: (context, userSnap) {
                    final userData =
                        userSnap.data?.data() ?? <String, dynamic>{};
                    final availabilityText = _availabilityLabel(userData);
                    final availabilityColor = _availabilityColor(
                      availabilityText,
                    );

                    return Container(
                      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Availability',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  availabilityText,
                                  style: TextStyle(
                                    color: availabilityColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_loadingAvailability || _changingAvailability)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Switch(
                              value: _availabilityOn,
                              onChanged: _toggleAvailability,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collection('reports')
                        .where('assignedResponderUid', isEqualTo: user.uid)
                        .where('adminDecision', isEqualTo: 'accepted')
                        .orderBy('updatedAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allDocs = snap.data?.docs ?? [];

                      final docs = allDocs.where((doc) {
                        return _shouldShowOnHome(doc.data());
                      }).toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No pending assigned requests.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
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
                          final locationText = (d['locationText'] ?? '')
                              .toString();
                          final citizenName = (d['citizenName'] ?? '')
                              .toString();
                          final citizenPhone = (d['citizenPhone'] ?? '')
                              .toString();

                          final statusCode =
                              (d['statusCode'] ?? '').toString().trim().isEmpty
                              ? 'pending_admin'
                              : (d['statusCode'] ?? '').toString().trim();

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailPage(
                                    reportId: id,
                                    viewerRole: 'responder',
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1F3A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFF6B35,
                                          ).withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: const Text(
                                          'New Assignment',
                                          style: TextStyle(
                                            color: Color(0xFFFFB089),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    incident.isEmpty
                                        ? 'Unnamed Incident'
                                        : incident,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Urgency: ${urgency.isEmpty ? '-' : urgency}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Location: ${locationText.isEmpty ? '-' : locationText}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${_statusLabelFromCode(statusCode)}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                    ),
                                  ),
                                  if (citizenName.isNotEmpty ||
                                      citizenPhone.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Citizen: ${citizenName.isEmpty ? 'Unknown' : citizenName}'
                                      '${citizenPhone.isEmpty ? '' : ' • $citizenPhone'}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.82),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _acceptAndOpenEnRoute(id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF22C55E,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Accept'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _denyRequest(id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFF87171,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFF87171),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: const Icon(Icons.close_rounded),
                                          label: const Text('Deny'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
