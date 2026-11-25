import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/chat_thread_schema.dart';
import '../../../../core/database/schemas/message_schema.dart';
import '../../domain/chat_thread.dart';
import '../../domain/message.dart';
import '../chat_repository.dart';

class IsarChatRepository implements ChatRepository {
  IsarChatRepository() : _uuid = const Uuid();

  final Uuid _uuid;

  Future<Isar> get _db async => IsarService.instance;

  @override
  Future<List<ChatThread>> getThreads() async {
    final isar = await _db;
    final threads = await isar.chatThreadIsars.where().sortByUpdatedAtDesc().findAll();
    return threads.map((t) => t.toDomain()).toList();
  }

  @override
  Future<ChatThread> createThread({String? title}) async {
    final now = DateTime.now();
    final thread = ChatThread(
      id: _uuid.v4(),
      title: title ?? 'New chat',
      createdAt: now,
      updatedAt: now,
    );
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.chatThreadIsars.put(ChatThreadIsar.fromDomain(thread));
    });
    return thread;
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    final isar = await _db;
    final messages = await isar.messageIsars
        .filter()
        .threadIdEqualTo(threadId)
        .sortByTimestamp()
        .findAll();
    return messages.map((m) => m.toDomain()).toList();
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

    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.messageIsars.put(MessageIsar.fromDomain(userMsg));

      // Update thread title and updatedAt
      final thread = await isar.chatThreadIsars.filter().idEqualTo(threadId).findFirst();
      if (thread != null) {
        var updated = thread;
        if (thread.title == 'New chat' && content.trim().isNotEmpty) {
          final newTitle = content.trim().length > 30
              ? '${content.trim().substring(0, 30)}…'
              : content.trim();
          updated.title = newTitle;
        }
        updated.updatedAt = now;
        await isar.chatThreadIsars.put(updated);
      }
    });

    // Generate assistant reply
    final replies = [
      "Got it! I've added that to your schedule. Anything else you'd like me to handle?",
      "Done — your calendar is updated. Want me to set a reminder too?",
      "I've noted that down. I can also break it into smaller tasks if you'd like.",
      "Scheduled! I'll keep an eye on it and nudge you when it's coming up.",
      "All set. I moved a few things around so nothing clashes.",
    ];
    final reply = Message(
      id: _uuid.v4(),
      threadId: threadId,
      role: MessageRole.assistant,
      content: replies[DateTime.now().millisecondsSinceEpoch % replies.length],
      timestamp: DateTime.now(),
    );

    await isar.writeTxn(() async {
      await isar.messageIsars.put(MessageIsar.fromDomain(reply));
      final thread = await isar.chatThreadIsars.filter().idEqualTo(threadId).findFirst();
      if (thread != null) {
        thread.updatedAt = DateTime.now();
        await isar.chatThreadIsars.put(thread);
      }
    });

    return reply;
  }
}
