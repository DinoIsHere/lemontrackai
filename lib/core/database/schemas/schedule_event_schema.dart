import 'package:isar/isar.dart';

import '../../../features/schedule/domain/schedule_event.dart';

part 'schedule_event_schema.g.dart';

@collection
class ScheduleEventIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String id;

  late String title;

  @Index()
  late DateTime start;

  @Index()
  late DateTime end;

  @enumerated
  late ScheduleCategory category;

  String? description;

  ScheduleEvent toDomain() => ScheduleEvent(
        id: id,
        title: title,
        start: start,
        end: end,
        category: category,
        description: description,
      );

  static ScheduleEventIsar fromDomain(ScheduleEvent event) {
    final model = ScheduleEventIsar()
      ..id = event.id
      ..title = event.title
      ..start = event.start
      ..end = event.end
      ..category = event.category
      ..description = event.description;
    return model;
  }
}
