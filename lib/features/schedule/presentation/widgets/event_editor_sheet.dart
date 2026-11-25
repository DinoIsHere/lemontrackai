import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/schedule_event.dart';
import '../schedule_controller.dart';

class EventEditorSheet extends ConsumerStatefulWidget {
  const EventEditorSheet({
    super.key,
    this.event,
    this.initialStart,
    this.initialEnd,
  });

  final ScheduleEvent? event;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  ConsumerState<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<EventEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _start;
  late DateTime _end;
  late ScheduleCategory _category;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(text: widget.event?.description ?? '');
    _start = widget.event?.start ?? widget.initialStart ?? DateTime(now.year, now.month, now.day, now.hour + 1);
    _end = widget.event?.end ?? widget.initialEnd ?? _start.add(const Duration(hours: 1));
    _category = widget.event?.category ?? ScheduleCategory.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, _start.hour, _start.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(_start.year, _start.month, _start.day, time.hour, time.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    setState(() {
      _end = DateTime(date.year, date.month, date.day, _end.hour, _end.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (time == null) return;
    setState(() {
      _end = DateTime(_end.year, _end.month, _end.day, time.hour, time.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(scheduleControllerProvider.notifier);
    if (widget.event == null) {
      await controller.createEvent(
        title: _titleController.text.trim(),
        start: _start,
        end: _end,
        category: _category,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
    } else {
      await controller.updateEvent(
        widget.event!.copyWith(
          title: _titleController.text.trim(),
          start: _start,
          end: _end,
          category: _category,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.event == null) return;
    final controller = ref.read(scheduleControllerProvider.notifier);
    await controller.deleteEvent(widget.event!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.event == null ? 'New event' : 'Edit event',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ScheduleCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ScheduleCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),
              Text('Start', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartDate,
                      child: Text(formatDate(_start)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartTime,
                      child: Text(formatTime(_start)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('End', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEndDate,
                      child: Text(formatDate(_end)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEndTime,
                      child: Text(formatTime(_end)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.event != null)
                    TextButton(
                      onPressed: _delete,
                      child: const Text('Delete'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
