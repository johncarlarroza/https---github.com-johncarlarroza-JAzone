import 'package:flutter/material.dart';
import 'pages/citizen_base_page.dart';

/// Backwards compatible entry page.
/// In JAzone, the actual routing is handled by AuthGate.
class BasePage extends StatelessWidget {
  const BasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CitizenBasePage();
  }
}
