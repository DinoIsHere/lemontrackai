import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_store.dart';
import '../../domain/kanban_card.dart';
import '../kanban_repository.dart';

class LocalKanbanRepository implements KanbanRepository {
  final _uuid = const Uuid();

  Future<List<KanbanCard>> _load() async {
    final data = await LocalStore.getKanbanJson();
    final cards = <KanbanCard>[];
    for (final m in data) {
      final mm = Map<String, dynamic>.from(m);
      cards.add(KanbanCard(
        id: mm['id'],
        title: mm['title'],
        description: mm['description'],
        status: KanbanStatus.values.firstWhere((s) => s.name == mm['status']),
        order: mm['order'] ?? 0,
        dueDate: mm['dueDate'] == null ? null : DateTime.parse(mm['dueDate']),
        linkedTimeBlockId: mm['linkedTimeBlockId'],
        linkedEventId: mm['linkedEventId'],
      ));
    }
    return cards;
  }

  Future<void> _save(List<KanbanCard> cards) async {
    final data = cards
        .map((c) => {
              'id': c.id,
              'title': c.title,
              'description': c.description,
              'status': c.status.name,
              'order': c.order,
              'dueDate': c.dueDate?.toIso8601String(),
              'linkedTimeBlockId': c.linkedTimeBlockId,
              'linkedEventId': c.linkedEventId,
            })
        .toList();
    await LocalStore.saveKanbanJson(data);
  }

  @override
  Future<List<KanbanCard>> getAllCards() async {
    final cards = await _load();
    cards.sort((a, b) {
      if (a.status.index != b.status.index) return a.status.index.compareTo(b.status.index);
      return a.order.compareTo(b.order);
    });
    return cards;
  }

  @override
  Future<List<KanbanCard>> getCardsByStatus(KanbanStatus status) async {
    final cards = await _load();
    final filtered = cards.where((c) => c.status == status).toList();
    filtered.sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  @override
  Future<KanbanCard> createCard(KanbanCard card) async {
    final cards = await _load();
    final newCard = card.id.isEmpty ? card.copyWith(id: _uuid.v4()) : card;
    cards.add(newCard);
    await _save(cards);
    return newCard;
  }

  @override
  Future<KanbanCard> updateCard(KanbanCard card) async {
    final cards = await _load();
    final idx = cards.indexWhere((c) => c.id == card.id);
    if (idx == -1) {
      cards.add(card);
    } else {
      cards[idx] = card;
    }
    await _save(cards);
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {
    final cards = await _load();
    cards.removeWhere((c) => c.id == id);
    await _save(cards);
  }

  @override
  Future<void> moveCard(String id, KanbanStatus status, int order) async {
    final cards = await _load();
    final idx = cards.indexWhere((c) => c.id == id);
    if (idx != -1) {
      cards[idx] = cards[idx].copyWith(status: status, order: order);
      await _save(cards);
    }
  }
}
