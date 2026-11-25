import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'schemas/chat_thread_schema.dart';
import 'schemas/message_schema.dart';
import 'schemas/schedule_event_schema.dart';
import 'schemas/time_block_schema.dart';
import 'schemas/kanban_card_schema.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) return _isar!;
    _isar = await _openDb();
    return _isar!;
  }

  static Future<Isar> _openDb() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        ChatThreadIsarSchema,
        MessageIsarSchema,
        ScheduleEventIsarSchema,
        TimeBlockIsarSchema,
        KanbanCardIsarSchema,
      ],
      directory: dir.path,
      name: 'lemontrack',
    );
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
