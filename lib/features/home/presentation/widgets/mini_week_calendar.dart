import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';

class MiniWeekCalendar extends StatelessWidget {
  const MiniWeekCalendar({
    super.key,
    required this.selectedDay,
    required this.busyDays,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final Set<DateTime> busyDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = weekDays(DateTime.now());
    final today = DateTime.now();
    return SizedBox(
      height: 72,
      child: Row(
        children: days.map((d) {
          final selected = isSameDay(d, selectedDay);
          final isToday = isSameDay(d, today);
          final busy = busyDays.any((b) => isSameDay(b, d));
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(d),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !selected
                          ? Border.all(color: theme.colorScheme.primary)
                          : null,
                    ),
                    child: Text(
                      '${d.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (busy)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }
}