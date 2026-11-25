import 'package:flutter/material.dart';

import '../../../schedule/domain/schedule_event.dart';
import 'mini_week_calendar.dart';
import 'today_events_list.dart';

class ScheduleWidget extends StatelessWidget {
  const ScheduleWidget({
    super.key,
    required this.selectedDay,
    required this.events,
    required this.busyDays,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final List<ScheduleEvent> events;
  final Set<DateTime> busyDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your schedule',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            MiniWeekCalendar(
              selectedDay: selectedDay,
              busyDays: busyDays,
              onSelect: onSelect,
            ),
            const Divider(),
            const SizedBox(height: 4),
            TodayEventsList(events: events),
          ],
        ),
      ),
    );
  }
}