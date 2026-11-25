import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../domain/schedule_event.dart';
import 'schedule_controller.dart';
import 'widgets/event_editor_sheet.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleControllerProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openEditor({ScheduleEvent? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EventEditorSheet(
        event: event,
        initialStart: event == null ? DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 9) : null,
        initialEnd: event == null ? DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 10) : null,
      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.watch(scheduleControllerProvider);
    final days = weekDays(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = _selectedDay.subtract(const Duration(days: 7));
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    'Week of ${formatDate(startOfWeek(_selectedDay))}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = _selectedDay.add(const Duration(days: 7));
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 72,
            child: Row(
              children: days.map((d) {
                final selected = isSameDay(d, _selectedDay);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = d),
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
                            color: selected ? theme.colorScheme.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isSameDay(d, DateTime.now()) && !selected
                                ? Border.all(color: theme.colorScheme.primary)
                                : null,
                          ),
                          child: Text(
                            '${d.day}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: controller.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (events) {
                final dayEvents = events.where((e) => isSameDay(e.start, _selectedDay)).toList()
                  ..sort((a, b) => a.start.compareTo(b.start));
                if (dayEvents.isEmpty) {
                  return Center(
                    child: Text(
                      'No events for this day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, i) {
                    final e = dayEvents[i];
                    final color = _categoryColor(e.category);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(e.title),
                        subtitle: Text(
                          '${formatTime(e.start)} – ${formatTime(e.end)}${e.description != null ? '\n${e.description}' : ''}',
                        ),
                        isThreeLine: e.description != null && e.description!.isNotEmpty,
                        onTap: () => _openEditor(event: e),
                        trailing: const Icon(Icons.edit_outlined),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }
}
