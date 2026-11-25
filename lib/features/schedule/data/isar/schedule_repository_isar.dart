import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/schedule_event_schema.dart';
import '../../domain/schedule_event.dart';
import '../schedule_repository.dart';

class IsarScheduleRepository implements ScheduleRepository {
  Future<Isar> get _db async => IsarService.instance;

  @override
  Future<List<ScheduleEvent>> getAllEvents() async {
    final isar = await _db;
    final events = await isar.scheduleEventIsars.where().findAll();
    return events.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<ScheduleEvent>> getEventsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final isar = await _db;
    final events = await isar.scheduleEventIsars
        .filter()
        .startLessThan(end)
        .and()
        .endGreaterThan(start)
        .findAll();
    events.sort((a, b) => a.start.compareTo(b.start));
    return events.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<ScheduleEvent>> getEventsForRange(DateTime start, DateTime end) async {
    final isar = await _db;
    final events = await isar.scheduleEventIsars
        .filter()
        .startLessThan(end)
        .and()
        .endGreaterThan(start)
        .findAll();
    events.sort((a, b) => a.start.compareTo(b.start));
    return events.map((e) => e.toDomain()).toList();
  }

  @override
  Future<ScheduleEvent> createEvent(ScheduleEvent event) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.scheduleEventIsars.put(ScheduleEventIsar.fromDomain(event));
    });
    return event;
  }

  @override
  Future<ScheduleEvent> updateEvent(ScheduleEvent event) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.scheduleEventIsars.put(ScheduleEventIsar.fromDomain(event));
    });
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.scheduleEventIsars.filter().idEqualTo(id).deleteAll();
    });
  }
}
