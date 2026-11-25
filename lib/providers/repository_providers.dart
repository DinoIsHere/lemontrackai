import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/data/chat_repository.dart';
import '../features/chat/data/local/chat_repository_local.dart';
import '../features/kanban/data/kanban_repository.dart';
import '../features/kanban/data/local/kanban_repository_local.dart';
import '../features/schedule/data/local/schedule_repository_local.dart';
import '../features/schedule/data/schedule_repository.dart';
import '../features/timeblock/data/local/time_block_repository_local.dart';
import '../features/timeblock/data/time_block_repository.dart';
import 'ai_engine_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final aiConfig = ref.watch(aiEngineProvider);
  if (kIsWeb) {
    return LocalChatRepository(ref: ref, aiConfig: aiConfig);
  }
  return LocalChatRepository(ref: ref, aiConfig: aiConfig);
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return LocalScheduleRepository();
});

final timeBlockRepositoryProvider = Provider<TimeBlockRepository>((ref) {
  return LocalTimeBlockRepository();
});

final kanbanRepositoryProvider = Provider<KanbanRepository>((ref) {
  return LocalKanbanRepository();
});
