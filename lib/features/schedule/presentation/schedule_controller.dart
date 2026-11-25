import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/repository_providers.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_event.dart';

final scheduleControllerProvider =
    StateNotifierProvider<ScheduleController, AsyncValue<List<ScheduleEvent>>>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  return ScheduleController(repo);
});

class ScheduleController extends StateNotifier<AsyncValue<List<ScheduleEvent>>> {
  ScheduleController(this._repo) : super(const AsyncValue.loading()) {
    loadAll();
  }

  final ScheduleRepository _repo;
  final _uuid = const Uuid();

  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final events = await _repo.getAllEvents();
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadForDay(DateTime day) async {
    state = const AsyncValue.loading();
    try {
      final events = await _repo.getEventsForDay(day);
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadForRange(DateTime start, DateTime end) async {
    state = const AsyncValue.loading();
    try {
      final events = await _repo.getEventsForRange(start, end);
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ScheduleEvent> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    required ScheduleCategory category,
    String? description,
    String? id,
  }) async {
    final event = ScheduleEvent(
      id: id ?? _uuid.v4(),
      title: title,
      start: start,
      end: end,
      category: category,
      description: description,
    );
    final created = await _repo.createEvent(event);
    await loadAll();
    return created;
  }

  Future<ScheduleEvent> updateEvent(ScheduleEvent event) async {
    final updated = await _repo.updateEvent(event);
    await loadAll();
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    await _repo.deleteEvent(id);
    await loadAll();
  }
}
