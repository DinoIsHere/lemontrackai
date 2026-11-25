import 'dart:math';

import 'package:uuid/uuid.dart';

import './chat_repository.dart';
import '../domain/chat_thread.dart';
import '../domain/message.dart';

class MockChatRepository implements ChatRepository {
  MockChatRepository() : _rand = Random();

  final _threads = <ChatThread>[];
  final _messages = <String, List<Message>>{};
  final _uuid = const Uuid();
  final Random _rand;

  static const _replies = <String>[
    "Got it! I've added that to your schedule. Anything else you'd like me to handle?",
    "Done — your calendar is updated. Want me to set a reminder too?",
    "I've noted that down. I can also break it into smaller tasks if you'd like.",
    "Scheduled! I'll keep an eye on it and nudge you when it's coming up.",
    "All set. I moved a few things around so nothing clashes.",
  ];

  @override
  Future<List<ChatThread>> getThreads() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final sorted = [..._threads]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Future<ChatThread> createThread({String? title}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final now = DateTime.now();
    final thread = ChatThread(
      id: _uuid.v4(),
      title: title ?? 'New chat',
      createdAt: now,
      updatedAt: now,
    );
    _threads.add(thread);
    _messages[thread.id] = [];
    return thread;
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List<Message>.from(_messages[threadId] ?? []);
  }

  @override
  Future<Message> sendMessage(String threadId, String content) async {
    final now = DateTime.now();
    final userMsg = Message(
      id: _uuid.v4(),
      threadId: threadId,
      role: MessageRole.user,
      content: content,
      timestamp: now,
    );
    _messages[threadId] = [...(_messages[threadId] ?? []), userMsg];

    // derive thread title from first user message
    final thread = _threads.firstWhere((t) => t.id == threadId);
    if (thread.title == 'New chat' && content.trim().isNotEmpty) {
      final newTitle = content.trim().length > 30
          ? '${content.trim().substring(0, 30)}…'
          : content.trim();
      final idx = _threads.indexOf(thread);
      _threads[idx] = thread.copyWith(title: newTitle, updatedAt: now);
    } else {
      final idx = _threads.indexOf(thread);
      _threads[idx] = thread.copyWith(updatedAt: now);
    }

    await Future.delayed(
      Duration(milliseconds: 600 + _rand.nextInt(600)),
    );

    final reply = Message(
      id: _uuid.v4(),
      threadId: threadId,
      role: MessageRole.assistant,
      content: _replies[_rand.nextInt(_replies.length)],
      timestamp: DateTime.now(),
    );
    _messages[threadId] = [...(_messages[threadId] ?? []), reply];
    return reply;
  }
}