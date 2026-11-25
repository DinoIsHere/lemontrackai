import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_store.dart';
import '../../domain/schedule_event.dart';
import '../schedule_repository.dart';

class LocalScheduleRepository implements ScheduleRepository {
  final _uuid = const Uuid();

  Future<List<ScheduleEvent>> _load() async {
    final data = await LocalStore.getEventsJson();
    final events = <ScheduleEvent>[];
    for (final m in data) {
      final mm = Map<String, dynamic>.from(m);
      events.add(ScheduleEvent(
        id: mm['id'],
        title: mm['title'],
        start: DateTime.parse(mm['start']),
        end: DateTime.parse(mm['end']),
        category: ScheduleCategory.values.firstWhere((c) => c.name == mm['category']),
        description: mm['description'],
      ));
    }
    return events;
  }

  Future<void> _save(List<ScheduleEvent> events) async {
    final data = events
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'start': e.start.toIso8601String(),
              'end': e.end.toIso8601String(),
              'category': e.category.name,
              'description': e.description,
            })
        .toList();
    await LocalStore.saveEventsJson(data);
  }

  @override
  Future<List<ScheduleEvent>> getAllEvents() async {
    final events = await _load();
    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  @override
  Future<List<ScheduleEvent>> getEventsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final events = await _load();
    final filtered = events.where((e) => e.start.isBefore(end) && e.end.isAfter(start)).toList();
    filtered.sort((a, b) => a.start.compareTo(b.start));
    return filtered;
  }

  @override
  Future<List<ScheduleEvent>> getEventsForRange(DateTime start, DateTime end) async {
    final events = await _load();
    final filtered = events.where((e) => e.start.isBefore(end) && e.end.isAfter(start)).toList();
    filtered.sort((a, b) => a.start.compareTo(b.start));
    return filtered;
  }

  @override
  Future<ScheduleEvent> createEvent(ScheduleEvent event) async {
    final events = await _load();
    final newEvent = event.id.isEmpty
        ? event.copyWith(id: _uuid.v4())
        : event;
    events.add(newEvent);
    await _save(events);
    return newEvent;
  }

  @override
  Future<ScheduleEvent> updateEvent(ScheduleEvent event) async {
    final events = await _load();
    final idx = events.indexWhere((e) => e.id == event.id);
    if (idx == -1) {
      events.add(event);
    } else {
      events[idx] = event;
    }
    await _save(events);
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    final events = await _load();
    events.removeWhere((e) => e.id == id);
    await _save(events);
  }
}
