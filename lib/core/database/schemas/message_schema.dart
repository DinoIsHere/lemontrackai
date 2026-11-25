import 'package:isar/isar.dart';

import '../../../features/chat/domain/message.dart';

part 'message_schema.g.dart';

@collection
class MessageIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String id;

  @Index()
  late String threadId;

  @enumerated
  late MessageRole role;

  late String content;

  @Index()
  late DateTime timestamp;

  bool isStreaming = false;

  Message toDomain() => Message(
        id: id,
        threadId: threadId,
        role: role,
        content: content,
        timestamp: timestamp,
        isStreaming: isStreaming,
      );

  static MessageIsar fromDomain(Message message) {
    final model = MessageIsar()
      ..id = message.id
      ..threadId = message.threadId
      ..role = message.role
      ..content = message.content
      ..timestamp = message.timestamp
      ..isStreaming = message.isStreaming;
    return model;
  }
}
