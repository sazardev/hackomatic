import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _notifications = true;
  bool _autoSave = true;
  bool _rootAccess = false;
  String _defaultTerminal = 'Built-in';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Appearance', [
              _buildSwitchTile(
                'Dark Mode',
                'Use dark theme for better visibility',
                Icons.dark_mode,
                _darkMode,
                (value) => setState(() => _darkMode = value),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('General', [
              _buildSwitchTile(
                'Notifications',
                'Show notifications for task completion',
                Icons.notifications,
                _notifications,
                (value) => setState(() => _notifications = value),
              ),
              _buildSwitchTile(
                'Auto Save',
                'Automatically save tool configurations',
                Icons.save,
                _autoSave,
                (value) => setState(() => _autoSave = value),
              ),
              _buildDropdownTile(
                'Default Terminal',
                'Choose default terminal emulator',
                Icons.terminal,
                _defaultTerminal,
                ['Built-in', 'Termux', 'External'],
                (value) => setState(() => _defaultTerminal = value!),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Security', [
              _buildSwitchTile(
                'Root Access',
                'Allow tools that require root privileges',
                Icons.security,
                _rootAccess,
                (value) => setState(() => _rootAccess = value),
              ),
              _buildActionTile(
                'Clear Data',
                'Remove all saved tools and scripts',
                Icons.delete_forever,
                _showClearDataDialog,
                color: HackomaticTheme.errorColor,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('About', [
              _buildInfoTile('Version', '1.0.0', Icons.info),
              _buildActionTile(
                'Open Source Licenses',
                'View third-party licenses',
                Icons.article,
                _showLicenses,
              ),
              _buildActionTile(
                'Privacy Policy',
                'Read our privacy policy',
                Icons.privacy_tip,
                _showPrivacyPolicy,
              ),
            ]),
            const SizedBox(height: 24),
            _buildWarningSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: HackomaticTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: HackomaticTheme.primaryGreen),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: HackomaticTheme.secondaryTextColor,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: HackomaticTheme.primaryGreen,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: HackomaticTheme.primaryGreen),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: HackomaticTheme.secondaryTextColor,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        underline: Container(),
        dropdownColor: HackomaticTheme.surfaceColor,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? HackomaticTheme.primaryGreen),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: HackomaticTheme.secondaryTextColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: HackomaticTheme.secondaryTextColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: HackomaticTheme.primaryGreen),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: HackomaticTheme.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildWarningSection() {
    return Card(
      color: HackomaticTheme.warningColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: HackomaticTheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Important Notice',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HackomaticTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Hackomatic is designed for educational and authorized security testing purposes only. '
              'Always ensure you have explicit permission before testing any network or system. '
              'Unauthorized access to computer systems is illegal and may result in severe penalties.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.android,
                  color: HackomaticTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This app is designed for Android devices only',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all saved tools, scripts, and tasks. '
          'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HackomaticTheme.errorColor,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    // Here you would implement data clearing logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared successfully'),
        backgroundColor: HackomaticTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Hackomatic',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Hackomatic Team',
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Hackomatic Privacy Policy\n\n'
            '1. Data Collection\n'
            'We do not collect any personal data. All information is stored locally on your device.\n\n'
            '2. Data Usage\n'
            'Tool configurations and scripts are saved locally for your convenience.\n\n'
            '3. Data Sharing\n'
            'We do not share any data with third parties.\n\n'
            '4. Security\n'
            'All data is stored securely on your device.\n\n'
            '5. Contact\n'
            'For questions about this policy, contact the development team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
