import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/kanban_card.dart';
import 'kanban_controller.dart';
import 'widgets/kanban_card_editor_sheet.dart';

class KanbanBoardScreen extends ConsumerStatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kanbanControllerProvider.notifier).loadAll();
    });
  }

  void _openEditor({KanbanCard? card}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => KanbanCardEditorSheet(card: card),
    );
  }

  Future<void> _moveCard(KanbanCard card, KanbanStatus status) async {
    await ref.read(kanbanControllerProvider.notifier).moveCard(card.id, status, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.watch(kanbanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: controller.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          final todo = cards.where((c) => c.status == KanbanStatus.todo).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
          final inProgress = cards.where((c) => c.status == KanbanStatus.inProgress).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
          final done = cards.where((c) => c.status == KanbanStatus.done).toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          Widget buildColumn(String title, List<KanbanCard> list, KanbanStatus status) {
            return Expanded(
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text('${list.length}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final card = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(card.title),
                              subtitle: card.description != null && card.description!.isNotEmpty
                                  ? Text(card.description!)
                                  : null,
                              onTap: () => _openEditor(card: card),
                              trailing: PopupMenuButton<KanbanStatus>(
                                onSelected: (s) => _moveCard(card, s),
                                itemBuilder: (context) => [
                                  if (status != KanbanStatus.todo)
                                    const PopupMenuItem(value: KanbanStatus.todo, child: Text('Move to To do')),
                                  if (status != KanbanStatus.inProgress)
                                    const PopupMenuItem(value: KanbanStatus.inProgress, child: Text('Move to In progress')),
                                  if (status != KanbanStatus.done)
                                    const PopupMenuItem(value: KanbanStatus.done, child: Text('Move to Done')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              buildColumn('To do', todo, KanbanStatus.todo),
              buildColumn('In progress', inProgress, KanbanStatus.inProgress),
              buildColumn('Done', done, KanbanStatus.done),
            ],
          );
        },
      ),
    );
  }
}
