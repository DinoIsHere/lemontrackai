import 'package:isar/isar.dart';

import '../../../features/kanban/domain/kanban_card.dart';

part 'kanban_card_schema.g.dart';

@collection
class KanbanCardIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String id;

  late String title;

  String? description;

  @enumerated
  late KanbanStatus status;

  int order = 0;

  DateTime? dueDate;

  String? linkedTimeBlockId;

  String? linkedEventId;

  KanbanCard toDomain() => KanbanCard(
        id: id,
        title: title,
        description: description,
        status: status,
        order: order,
        dueDate: dueDate,
        linkedTimeBlockId: linkedTimeBlockId,
        linkedEventId: linkedEventId,
      );

  static KanbanCardIsar fromDomain(KanbanCard card) {
    final model = KanbanCardIsar()
      ..id = card.id
      ..title = card.title
      ..description = card.description
      ..status = card.status
      ..order = card.order
      ..dueDate = card.dueDate
      ..linkedTimeBlockId = card.linkedTimeBlockId
      ..linkedEventId = card.linkedEventId;
    return model;
  }
}
