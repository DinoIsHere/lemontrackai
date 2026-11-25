import '../domain/schedule_event.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleEvent>> getEventsForDay(DateTime day);
  Future<List<ScheduleEvent>> getEventsForRange(DateTime start, DateTime end);
  Future<ScheduleEvent> createEvent(ScheduleEvent event);
  Future<ScheduleEvent> updateEvent(ScheduleEvent event);
  Future<void> deleteEvent(String id);
  Future<List<ScheduleEvent>> getAllEvents();
}