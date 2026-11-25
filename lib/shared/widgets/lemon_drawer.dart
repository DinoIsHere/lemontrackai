import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/presentation/chat_controller.dart';

class LemonDrawer extends ConsumerWidget {
  const LemonDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadsProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Lemon Track',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                },
                icon: const Icon(Icons.add),
                label: const Text('New chat'),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Schedule'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/schedule');
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time Blocks'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/timeblock');
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_kanban_outlined),
              title: const Text('Kanban'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/kanban');
              },
            ),
            const Divider(),
            Expanded(
              child: threadsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (threads) {
                  if (threads.isEmpty) {
                    return const Center(child: Text('No conversations yet'));
                  }
                  return ListView.builder(
                    itemCount: threads.length,
                    itemBuilder: (context, i) {
                      final t = threads[i];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(t.title),
                        subtitle: Text(_formatDate(t.updatedAt)),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: t.id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.month}/${d.day}';
  }
}
