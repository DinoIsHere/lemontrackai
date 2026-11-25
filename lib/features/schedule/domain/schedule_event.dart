enum ScheduleCategory { school, work, house, other }

class ScheduleEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final ScheduleCategory category;
  final String? description;

  const ScheduleEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.category,
    this.description,
  });

  ScheduleEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    ScheduleCategory? category,
    String? description,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}