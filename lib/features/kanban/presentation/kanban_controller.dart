import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/repository_providers.dart';
import '../data/kanban_repository.dart';
import '../domain/kanban_card.dart';

final kanbanControllerProvider =
    StateNotifierProvider<KanbanController, AsyncValue<List<KanbanCard>>>((ref) {
  final repo = ref.watch(kanbanRepositoryProvider);
  return KanbanController(repo);
});

class KanbanController extends StateNotifier<AsyncValue<List<KanbanCard>>> {
  KanbanController(this._repo) : super(const AsyncValue.loading()) {
    loadAll();
  }

  final KanbanRepository _repo;
  final _uuid = const Uuid();

  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final cards = await _repo.getAllCards();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<KanbanCard> createCard({
    required String title,
    String? description,
    KanbanStatus status = KanbanStatus.todo,
    int order = 0,
    DateTime? dueDate,
    String? id,
  }) async {
    final card = KanbanCard(
      id: id ?? _uuid.v4(),
      title: title,
      description: description,
      status: status,
      order: order,
      dueDate: dueDate,
    );
    final created = await _repo.createCard(card);
    await loadAll();
    return created;
  }

  Future<KanbanCard> updateCard(KanbanCard card) async {
    final updated = await _repo.updateCard(card);
    await loadAll();
    return updated;
  }

  Future<void> deleteCard(String id) async {
    await _repo.deleteCard(id);
    await loadAll();
  }

  Future<void> moveCard(String id, KanbanStatus status, int order) async {
    await _repo.moveCard(id, status, order);
    await loadAll();
  }
}
