import 'package:flutter/material.dart';

class AppPreferencePage extends StatefulWidget {
  const AppPreferencePage({super.key});

  @override
  State<AppPreferencePage> createState() => _AppPreferencePageState();
}

class _AppPreferencePageState extends State<AppPreferencePage> {
  bool _biometricLogin = true;
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  String _selectedTheme = 'System Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "App Preferences",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Security"),
          SwitchListTile(
            title: const Text("Biometric Login"),
            subtitle: const Text("Use fingerprint or face recognition to unlock"),
            value: _biometricLogin,
            activeColor: Colors.teal,
            onChanged: (val) => setState(() => _biometricLogin = val),
          ),
          _buildSectionHeader("Notifications"),
          SwitchListTile(
            title: const Text("Push Notifications"),
            subtitle: const Text("Get instant transaction updates"),
            value: _pushNotifications,
            activeColor: Colors.teal,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          SwitchListTile(
            title: const Text("Email Alerts"),
            subtitle: const Text("Receive monthly statements and summaries"),
            value: _emailAlerts,
            activeColor: Colors.teal,
            onChanged: (val) => setState(() => _emailAlerts = val),
          ),
          _buildSectionHeader("Appearance"),
          ListTile(
            title: const Text("Theme"),
            subtitle: Text(_selectedTheme),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: _showThemeSelector,
          ),
          _buildSectionHeader("Cache & Storage"),
          ListTile(
            title: const Text("Clear Cache"),
            subtitle: const Text("Free up storage space (2.4 MB)"),
            trailing: const Icon(Icons.delete_outline, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cache cleared successfully")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal[700],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Theme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['System Default', 'Light Theme', 'Dark Theme'].map((theme) {
              return RadioListTile<String>(
                title: Text(theme),
                value: theme,
                groupValue: _selectedTheme,
                activeColor: Colors.teal,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTheme = val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
