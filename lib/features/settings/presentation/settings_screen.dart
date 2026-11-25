import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'appearance_screen.dart';
import 'skills_screen.dart';
import 'ai_engine_screen.dart';
import 'data_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingsItem(Icons.person_outline, 'Profile', const ProfileScreen()),
      _SettingsItem(Icons.notifications_outlined, 'Notifications', const NotificationsScreen()),
      _SettingsItem(Icons.palette_outlined, 'Appearance', const AppearanceScreen()),
      _SettingsItem(Icons.extension_outlined, 'Skills', const SkillsScreen()),
      _SettingsItem(Icons.smart_toy_outlined, 'AI Engine', const AiEngineScreen()),
      _SettingsItem(Icons.storage_outlined, 'Data', const DataScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => item.screen),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem(this.icon, this.title, this.screen);
  final IconData icon;
  final String title;
  final Widget screen;
}
