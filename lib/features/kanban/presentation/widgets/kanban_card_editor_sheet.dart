import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/kanban_card.dart';
import '../kanban_controller.dart';

class KanbanCardEditorSheet extends ConsumerStatefulWidget {
  const KanbanCardEditorSheet({super.key, this.card});

  final KanbanCard? card;

  @override
  ConsumerState<KanbanCardEditorSheet> createState() => _KanbanCardEditorSheetState();
}

class _KanbanCardEditorSheetState extends ConsumerState<KanbanCardEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late KanbanStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _descController = TextEditingController(text: widget.card?.description ?? '');
    _status = widget.card?.status ?? KanbanStatus.todo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(kanbanControllerProvider.notifier);
    if (widget.card == null) {
      await controller.createCard(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        status: _status,
      );
    } else {
      await controller.updateCard(
        widget.card!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          status: _status,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.card == null) return;
    final controller = ref.read(kanbanControllerProvider.notifier);
    await controller.deleteCard(widget.card!.id);
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
                widget.card == null ? 'New card' : 'Edit card',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<KanbanStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: KanbanStatus.values.map((s) {
                  String label;
                  switch (s) {
                    case KanbanStatus.todo:
                      label = 'To do';
                      break;
                    case KanbanStatus.inProgress:
                      label = 'In progress';
                      break;
                    case KanbanStatus.done:
                      label = 'Done';
                      break;
                  }
                  return DropdownMenuItem(value: s, child: Text(label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
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
                  if (widget.card != null) TextButton(onPressed: _delete, child: const Text('Delete')),
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
