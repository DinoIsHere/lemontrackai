import 'dart:math';

import 'package:uuid/uuid.dart';

import './schedule_repository.dart';
import '../domain/schedule_event.dart';

class MockScheduleRepository implements ScheduleRepository {
  MockScheduleRepository() {
    _seed();
  }

  final _events = <ScheduleEvent>[];
  final _uuid = const Uuid();
  final _rand = Random();

  void _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _events.addAll([
      ScheduleEvent(
        id: _uuid.v4(),
        title: 'Math homework',
        start: today.add(const Duration(hours: 9)),
        end: today.add(const Duration(hours: 10)),
        category: ScheduleCategory.school,
      ),
      ScheduleEvent(
        id: _uuid.v4(),
        title: 'Team standup',
        start: today.add(const Duration(hours: 10, minutes: 30)),
        end: today.add(const Duration(hours: 11)),
        category: ScheduleCategory.work,
      ),
      ScheduleEvent(
        id: _uuid.v4(),
        title: 'Clean kitchen',
        start: today.add(const Duration(hours: 18)),
        end: today.add(const Duration(hours: 19)),
        category: ScheduleCategory.house,
      ),
      ScheduleEvent(
        id: _uuid.v4(),
        title: 'Physics lab report',
        start: today.add(const Duration(days: 1, hours: 14)),
        end: today.add(const Duration(days: 1, hours: 16)),
        category: ScheduleCategory.school,
      ),
      ScheduleEvent(
        id: _uuid.v4(),
        title: 'Grocery run',
        start: today.add(const Duration(days: 2, hours: 11)),
        end: today.add(const Duration(days: 2, hours: 12)),
        category: ScheduleCategory.house,
      ),
    ]);
    // sprinkle randomness to avoid determinism concerns (none needed)
    _rand.nextInt(1);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<List<ScheduleEvent>> getEventsForDay(DateTime day) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _events.where((e) => _sameDay(e.start, day)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(list);
  }

  @override
  Future<List<ScheduleEvent>> getEventsForRange(DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _events
        .where((e) => !e.start.isBefore(start) && e.start.isBefore(end))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(list);
  }

  @override
  Future<List<ScheduleEvent>> getAllEvents() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = List<ScheduleEvent>.from(_events)
      ..sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(list);
  }

  @override
  Future<ScheduleEvent> createEvent(ScheduleEvent event) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newEvent = ScheduleEvent(
      id: event.id.isEmpty ? _uuid.v4() : event.id,
      title: event.title,
      start: event.start,
      end: event.end,
      category: event.category,
      description: event.description,
    );
    _events.add(newEvent);
    return newEvent;
  }

  @override
  Future<ScheduleEvent> updateEvent(ScheduleEvent event) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      _events.add(event);
      return event;
    }
    _events[index] = event;
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _events.removeWhere((e) => e.id == id);
  }
}