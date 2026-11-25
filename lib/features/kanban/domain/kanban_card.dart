enum KanbanStatus { todo, inProgress, done }

class KanbanCard {
  final String id;
  final String title;
  final String? description;
  final KanbanStatus status;
  final int order;
  final DateTime? dueDate;
  final String? linkedTimeBlockId;
  final String? linkedEventId;

  const KanbanCard({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.order = 0,
    this.dueDate,
    this.linkedTimeBlockId,
    this.linkedEventId,
  });

  KanbanCard copyWith({
    String? id,
    String? title,
    String? description,
    KanbanStatus? status,
    int? order,
    DateTime? dueDate,
    String? linkedTimeBlockId,
    String? linkedEventId,
  }) {
    return KanbanCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      order: order ?? this.order,
      dueDate: dueDate ?? this.dueDate,
      linkedTimeBlockId: linkedTimeBlockId ?? this.linkedTimeBlockId,
      linkedEventId: linkedEventId ?? this.linkedEventId,
    );
  }
}
