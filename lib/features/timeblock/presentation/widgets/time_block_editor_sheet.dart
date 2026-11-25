import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/time_block.dart';
import '../time_block_controller.dart';

class TimeBlockEditorSheet extends ConsumerStatefulWidget {
  const TimeBlockEditorSheet({super.key, this.block, this.initialStart, this.initialEnd});

  final TimeBlock? block;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  ConsumerState<TimeBlockEditorSheet> createState() => _TimeBlockEditorSheetState();
}

class _TimeBlockEditorSheetState extends ConsumerState<TimeBlockEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _start;
  late DateTime _end;
  late bool _isFocus;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController = TextEditingController(text: widget.block?.title ?? '');
    _descController = TextEditingController(text: widget.block?.description ?? '');
    _start = widget.block?.start ?? widget.initialStart ?? DateTime(now.year, now.month, now.day, now.hour + 1);
    _end = widget.block?.end ?? widget.initialEnd ?? _start.add(const Duration(hours: 2));
    _isFocus = widget.block?.isFocus ?? true;
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
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null) return;
    setState(() {
      _start = DateTime(_start.year, _start.month, _start.day, time.hour, time.minute);
      if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
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
      if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
    });
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
    if (time == null) return;
    setState(() {
      _end = DateTime(_end.year, _end.month, _end.day, time.hour, time.minute);
      if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(timeBlockControllerProvider.notifier);
    if (widget.block == null) {
      await controller.createBlock(
        title: _titleController.text.trim(),
        start: _start,
        end: _end,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        isFocus: _isFocus,
        color: Colors.deepPurple,
      );
    } else {
      await controller.updateBlock(
        widget.block!.copyWith(
          title: _titleController.text.trim(),
          start: _start,
          end: _end,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          isFocus: _isFocus,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.block == null) return;
    final controller = ref.read(timeBlockControllerProvider.notifier);
    await controller.deleteBlock(widget.block!.id);
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
                widget.block == null ? 'New time block' : 'Edit time block',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Focus block'),
                value: _isFocus,
                onChanged: (v) => setState(() => _isFocus = v),
              ),
              const SizedBox(height: 8),
              Text('Start', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _pickStartDate, child: Text(formatDate(_start)))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: _pickStartTime, child: Text(formatTime(_start)))),
                ],
              ),
              const SizedBox(height: 12),
              Text('End', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _pickEndDate, child: Text(formatDate(_end)))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: _pickEndTime, child: Text(formatTime(_end)))),
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
                  if (widget.block != null) TextButton(onPressed: _delete, child: const Text('Delete')),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
