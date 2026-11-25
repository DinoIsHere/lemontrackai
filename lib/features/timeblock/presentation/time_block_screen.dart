import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../domain/time_block.dart';
import 'time_block_controller.dart';
import 'widgets/time_block_editor_sheet.dart';

class TimeBlockScreen extends ConsumerStatefulWidget {
  const TimeBlockScreen({super.key});

  @override
  ConsumerState<TimeBlockScreen> createState() => _TimeBlockScreenState();
}

class _TimeBlockScreenState extends ConsumerState<TimeBlockScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timeBlockControllerProvider.notifier).loadAll();
    });
  }

  void _openEditor({TimeBlock? block}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TimeBlockEditorSheet(
        block: block,
        initialStart: block == null ? DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 13) : null,
        initialEnd: block == null ? DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 15) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.watch(timeBlockControllerProvider);
    final days = weekDays(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Blocks'),
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
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              data: (blocks) {
                final dayBlocks = blocks.where((b) => isSameDay(b.start, _selectedDay)).toList()
                  ..sort((a, b) => a.start.compareTo(b.start));
                if (dayBlocks.isEmpty) {
                  return Center(
                    child: Text(
                      'No time blocks for this day',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dayBlocks.length,
                  itemBuilder: (context, i) {
                    final b = dayBlocks[i];
                    final color = b.color ?? Colors.deepPurple;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                        ),
                        title: Text(b.title),
                        subtitle: Text(
                          '${formatTime(b.start)} – ${formatTime(b.end)}${b.isFocus ? ' • Focus' : ''}${b.description != null && b.description!.isNotEmpty ? '\n${b.description}' : ''}',
                        ),
                        isThreeLine: (b.description != null && b.description!.isNotEmpty),
                        onTap: () => _openEditor(block: b),
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
