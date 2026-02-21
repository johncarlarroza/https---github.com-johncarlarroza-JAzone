import 'package:flutter/material.dart';
import 'report_detail_page.dart';

/// Backwards compatible wrapper for older navigation.
/// Use [ReportDetailPage] going forward.
class IncidentDashboardPage extends StatelessWidget {
  final String incidentId;
  const IncidentDashboardPage({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return ReportDetailPage(reportId: incidentId, viewerRole: 'citizen');
  }
}
