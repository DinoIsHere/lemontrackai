import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push notifications'),
            value: settings.pushEnabled,
            onChanged: notifier.setPush,
          ),
          SwitchListTile(
            title: const Text('Reminders'),
            value: settings.remindersEnabled,
            onChanged: notifier.setReminders,
          ),
          SwitchListTile(
            title: const Text('Email notifications'),
            value: settings.emailEnabled,
            onChanged: notifier.setEmail,
          ),
        ],
      ),
    );
  }
}
