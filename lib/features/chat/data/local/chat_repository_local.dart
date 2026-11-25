import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_store.dart';
import '../../../../providers/ai_engine_provider.dart';
import '../../domain/chat_thread.dart';
import '../../domain/message.dart';
import '../ai_chat_service.dart';
import '../chat_repository.dart';

class LocalChatRepository implements ChatRepository {
  LocalChatRepository({required this.ref, required this.aiConfig})
      : _uuid = const Uuid();

  final Ref ref;
  final AiEngineConfig aiConfig;
  final Uuid _uuid;

  Future<List<ChatThread>> _loadThreads() async {
    final data = await LocalStore.getThreadsJson();
    final threads = <ChatThread>[];
    for (final entry in data.entries) {
      final m = Map<String, dynamic>.from(entry.value);
      threads.add(ChatThread(
        id: m['id'],
        title: m['title'],
        createdAt: DateTime.parse(m['createdAt']),
        updatedAt: DateTime.parse(m['updatedAt']),
      ));
    }
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads;
  }

  Future<void> _saveThreads(List<ChatThread> threads) async {
    final map = <String, dynamic>{};
    for (final t in threads) {
      map[t.id] = {
        'id': t.id,
        'title': t.title,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      };
    }
    await LocalStore.saveThreadsJson(map);
  }

  Future<List<Message>> _loadMessages(String threadId) async {
    final data = await LocalStore.getMessagesJson();
    final list = data[threadId] as List<dynamic>? ?? [];
    final messages = <Message>[];
    for (final m in list) {
      final mm = Map<String, dynamic>.from(m);
      messages.add(Message(
        id: mm['id'],
        threadId: mm['threadId'],
        role: MessageRole.values.firstWhere((r) => r.name == mm['role']),
        content: mm['content'],
        timestamp: DateTime.parse(mm['timestamp']),
      ));
    }
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<void> _saveMessages(String threadId, List<Message> messages) async {
    final data = await LocalStore.getMessagesJson();
    data[threadId] = messages
        .map((m) => {
              'id': m.id,
              'threadId': m.threadId,
              'role': m.role.name,
              'content': m.content,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();
    await LocalStore.saveMessagesJson(data);
  }

  @override
  Future<List<ChatThread>> getThreads() async {
    return _loadThreads();
  }

  @override
  Future<ChatThread> createThread({String? title}) async {
    final threads = await _loadThreads();
    final now = DateTime.now();
    final thread = ChatThread(
      id: _uuid.v4(),
      title: title ?? 'New chat',
      createdAt: now,
      updatedAt: now,
    );
    threads.add(thread);
    await _saveThreads(threads);
    // ensure empty message list exists
    final msgs = await LocalStore.getMessagesJson();
    if (!msgs.containsKey(thread.id)) {
      msgs[thread.id] = [];
      await LocalStore.saveMessagesJson(msgs);
    }
    return thread;
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    return _loadMessages(threadId);
  }

  @override
  Future<Message> sendMessage(String threadId, String content) async {
    final now = DateTime.now();
    final threads = await _loadThreads();
    final messages = await _loadMessages(threadId);

    final userMsg = Message(
      id: _uuid.v4(),
      threadId: threadId,
      role: MessageRole.user,
      content: content,
      timestamp: now,
    );
    messages.add(userMsg);
    await _saveMessages(threadId, messages);

    // update thread
    final idx = threads.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      var t = threads[idx];
      if (t.title == 'New chat' && content.trim().isNotEmpty) {
        final newTitle = content.trim().length > 30
            ? '${content.trim().substring(0, 30)}…'
            : content.trim();
        t = t.copyWith(title: newTitle, updatedAt: now);
      } else {
        t = t.copyWith(updatedAt: now);
      }
      threads[idx] = t;
      await _saveThreads(threads);
    }

    String replyText;
    try {
      final service = AIChatService(aiConfig);
      final history = messages
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();
      replyText = await service.sendMessage(content, history: history);
    } catch (e) {
      replyText = 'Error: ${e.toString()}. Check your AI Engine settings.';
    }

    final reply = Message(
      id: _uuid.v4(),
      threadId: threadId,
      role: MessageRole.assistant,
      content: replyText,
      timestamp: DateTime.now(),
    );
    final messages2 = await _loadMessages(threadId);
    messages2.add(reply);
    await _saveMessages(threadId, messages2);

    final threads2 = await _loadThreads();
    final idx2 = threads2.indexWhere((t) => t.id == threadId);
    if (idx2 != -1) {
      threads2[idx2] = threads2[idx2].copyWith(updatedAt: DateTime.now());
      await _saveThreads(threads2);
    }

    return reply;
  }
}
