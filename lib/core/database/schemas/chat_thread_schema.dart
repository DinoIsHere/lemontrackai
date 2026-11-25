import 'package:isar/isar.dart';

import '../../../features/chat/domain/chat_thread.dart';

part 'chat_thread_schema.g.dart';

@collection
class ChatThreadIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String id;

  late String title;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  ChatThread toDomain() => ChatThread(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static ChatThreadIsar fromDomain(ChatThread thread) {
    final model = ChatThreadIsar()
      ..id = thread.id
      ..title = thread.title
      ..createdAt = thread.createdAt
      ..updatedAt = thread.updatedAt;
    return model;
  }
}
