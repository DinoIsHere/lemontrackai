import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/kanban/presentation/kanban_board_screen.dart';
import 'features/schedule/presentation/schedule_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/profile_screen.dart';
import 'features/settings/presentation/notifications_screen.dart';
import 'features/settings/presentation/appearance_screen.dart';
import 'features/settings/presentation/skills_screen.dart';
import 'features/settings/presentation/ai_engine_screen.dart';
import 'features/settings/presentation/data_screen.dart';
import 'features/timeblock/presentation/time_block_screen.dart';

class LemonApp extends ConsumerWidget {
  const LemonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Lemon Track',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/chat': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String;
          return ChatScreen(threadId: id);
        },
        '/schedule': (_) => const ScheduleScreen(),
        '/timeblock': (_) => const TimeBlockScreen(),
        '/kanban': (_) => const KanbanBoardScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/settings/profile': (_) => const ProfileScreen(),
        '/settings/notifications': (_) => const NotificationsScreen(),
        '/settings/appearance': (_) => const AppearanceScreen(),
        '/settings/skills': (_) => const SkillsScreen(),
        '/settings/ai-engine': (_) => const AiEngineScreen(),
        '/settings/data': (_) => const DataScreen(),
      },
    );
  }
}