import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../schedule/domain/schedule_event.dart';

class TodayEventsList extends StatelessWidget {
  const TodayEventsList({super.key, required this.events});

  final List<ScheduleEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No events for this day',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      children: events.map((e) {
        final color = _categoryColor(e.category);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatTimeRange(e.start, e.end),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _categoryColor(ScheduleCategory c) {
    switch (c) {
      case ScheduleCategory.school:
        return const Color(0xFF4A90D9);
      case ScheduleCategory.work:
        return const Color(0xFF4CAF50);
      case ScheduleCategory.house:
        return const Color(0xFFFF9800);
      case ScheduleCategory.other:
        return const Color(0xFF9E9E9E);
    }
  }
}