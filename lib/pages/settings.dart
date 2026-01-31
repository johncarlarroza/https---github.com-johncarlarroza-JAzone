import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedTheme = 'Dark';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// NOTIFICATIONS SECTION
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 12),
            _buildToggleItem(
              icon: Icons.notifications_active,
              title: 'Enable Notifications',
              subtitle: 'Receive alerts about incident updates',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            const SizedBox(height: 12),
            _buildToggleItem(
              icon: Icons.warning_rounded,
              title: 'Urgent Alerts Only',
              subtitle: 'Only receive urgent incident notifications',
              value: false,
              onChanged: (value) {},
            ),
            const SizedBox(height: 32),

            /// LOCATION SECTION
            _buildSectionTitle('Location Settings'),
            const SizedBox(height: 12),
            _buildToggleItem(
              icon: Icons.location_on,
              title: 'Location Services',
              subtitle: 'Allow access to your location for reports',
              value: _locationEnabled,
              onChanged: (value) {
                setState(() => _locationEnabled = value);
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.my_location,
              title: 'Location Accuracy',
              subtitle: 'High accuracy - More battery usage',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(height: 32),

            /// DISPLAY SECTION
            _buildSectionTitle('Display'),
            const SizedBox(height: 12),
            _buildToggleItem(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Use dark theme throughout the app',
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
              },
            ),
            const SizedBox(height: 12),
            _buildDropdownItem(
              icon: Icons.palette,
              title: 'Theme',
              value: _selectedTheme,
              options: ['Dark', 'Light', 'Auto'],
              onChanged: (value) {
                setState(() => _selectedTheme = value);
              },
            ),
            const SizedBox(height: 32),

            /// APP SECTION
            _buildSectionTitle('App'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: 'Version 1.0.0',
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.storage,
              title: 'Cache',
              subtitle: 'Clear: 24.5 MB',
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                },
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 32),

            /// ACCOUNT SECTION
            _buildSectionTitle('Account'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Manage your profile information',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.lock,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out from your account',
              onTap: () {
                _showLogoutDialog();
              },
            ),
            const SizedBox(height: 32),

            /// LEGAL SECTION
            _buildSectionTitle('Legal'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.description,
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'Review our privacy policy',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(height: 40),
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
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
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.teal),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 24),
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
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
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
                DropdownButton<String>(
                  value: value,
                  items: options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) onChanged(newValue);
                  },
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1A1F3A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
