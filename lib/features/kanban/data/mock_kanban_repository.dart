import 'package:uuid/uuid.dart';

import './kanban_repository.dart';
import '../domain/kanban_card.dart';

class MockKanbanRepository implements KanbanRepository {
  MockKanbanRepository() {
    _seed();
  }

  final _cards = <KanbanCard>[];
  final _uuid = const Uuid();

  void _seed() {
    _cards.addAll([
      KanbanCard(
        id: _uuid.v4(),
        title: 'Plan project structure',
        description: 'Outline features and modules',
        status: KanbanStatus.todo,
        order: 0,
      ),
      KanbanCard(
        id: _uuid.v4(),
        title: 'Build schedule UI',
        description: 'Calendar + event editor',
        status: KanbanStatus.inProgress,
        order: 0,
      ),
      KanbanCard(
        id: _uuid.v4(),
        title: 'Add auth flow',
        status: KanbanStatus.done,
        order: 0,
      ),
    ]);
  }

  @override
  Future<List<KanbanCard>> getAllCards() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = List<KanbanCard>.from(_cards)
      ..sort((a, b) {
        if (a.status.index != b.status.index) return a.status.index.compareTo(b.status.index);
        return a.order.compareTo(b.order);
      });
    return List.unmodifiable(list);
  }

  @override
  Future<List<KanbanCard>> getCardsByStatus(KanbanStatus status) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _cards.where((c) => c.status == status).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(list);
  }

  @override
  Future<KanbanCard> createCard(KanbanCard card) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final maxOrder = _cards.where((c) => c.status == card.status).fold<int>(-1, (prev, c) => c.order > prev ? c.order : prev);
    final newCard = KanbanCard(
      id: card.id.isEmpty ? _uuid.v4() : card.id,
      title: card.title,
      description: card.description,
      status: card.status,
      order: maxOrder + 1,
      dueDate: card.dueDate,
      linkedTimeBlockId: card.linkedTimeBlockId,
      linkedEventId: card.linkedEventId,
    );
    _cards.add(newCard);
    return newCard;
  }

  @override
  Future<KanbanCard> updateCard(KanbanCard card) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      _cards.add(card);
      return card;
    }
    _cards[index] = card;
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _cards.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> moveCard(String id, KanbanStatus status, int order) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _cards.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final card = _cards[index];
    _cards[index] = card.copyWith(status: status, order: order);
  }
}
