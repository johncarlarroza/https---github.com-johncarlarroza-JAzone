import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        title: const Text('About Us'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// APP LOGO & NAME
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      size: 60,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'JAZone Alert',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            /// ABOUT SECTION
            _buildSectionTitle('About JAZone Alert'),
            const SizedBox(height: 12),
            Text(
              'JAZone Alert is a real-time emergency incident reporting system designed to help communities respond quickly to emergencies. Our platform enables citizens to report incidents with photo evidence and track the resolution progress in real-time.',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            /// FEATURES SECTION
            _buildSectionTitle('Key Features'),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.camera_alt,
              title: 'Photo Evidence',
              description: 'Capture incident photos with GPS coordinates',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.location_on,
              title: 'Location Tracking',
              description:
                  'Automatic location detection for accurate reporting',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.notifications_active,
              title: 'Real-time Updates',
              description: 'Track incident status and resolution progress',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.priority_high,
              title: 'Urgency Levels',
              description:
                  'Report incidents with appropriate urgency classification',
            ),
            const SizedBox(height: 32),

            /// MISSION SECTION
            _buildSectionTitle('Our Mission'),
            const SizedBox(height: 12),
            Text(
              'To empower communities with timely emergency response capabilities and create a safer environment for everyone through transparent incident reporting and collaborative emergency management.',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            /// CONTACT SECTION
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.email,
              label: 'Email',
              value: 'support@jazonealert.com',
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.phone,
              label: 'Phone',
              value: '+63-123-456-7890',
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.location_on,
              label: 'Address',
              value: 'Januan, Philippines',
            ),
            const SizedBox(height: 40),

            /// FOOTER
            Center(
              child: Text(
                '© 2024 JAZone Alert. All rights reserved.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
