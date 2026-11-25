import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_thread.dart';
import '../domain/message.dart';
import '../../../providers/repository_providers.dart';

final selectedThreadIdProvider = StateProvider<String?>((ref) => null);

final threadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getThreads();
});

final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, threadId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(threadId);
});

final chatActionsProvider = Provider<ChatActions>((ref) => ChatActions(ref));

class ChatActions {
  ChatActions(this.ref);
  final Ref ref;

  Future<ChatThread> createNewChat({String? initialMessage}) async {
    final repo = ref.read(chatRepositoryProvider);
    final thread = await repo.createThread(title: null);
    ref.invalidate(threadsProvider);
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      await repo.sendMessage(thread.id, initialMessage.trim());
      ref.invalidate(messagesProvider(thread.id));
      ref.invalidate(threadsProvider);
    }
    return thread;
  }

  Future<void> sendMessage(String threadId, String content) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(threadId, content);
    ref.invalidate(messagesProvider(threadId));
    ref.invalidate(threadsProvider);
  }
}
