import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/kanban_card_schema.dart';
import '../../domain/kanban_card.dart';
import '../kanban_repository.dart';

class IsarKanbanRepository implements KanbanRepository {
  Future<Isar> get _db async => IsarService.instance;

  @override
  Future<List<KanbanCard>> getAllCards() async {
    final isar = await _db;
    final cards = await isar.kanbanCardIsars.where().sortByStatus().thenByOrder().findAll();
    return cards.map((c) => c.toDomain()).toList();
  }

  @override
  Future<List<KanbanCard>> getCardsByStatus(KanbanStatus status) async {
    final isar = await _db;
    final cards = await isar.kanbanCardIsars.filter().statusEqualTo(status).sortByOrder().findAll();
    return cards.map((c) => c.toDomain()).toList();
  }

  @override
  Future<KanbanCard> createCard(KanbanCard card) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.kanbanCardIsars.put(KanbanCardIsar.fromDomain(card));
    });
    return card;
  }

  @override
  Future<KanbanCard> updateCard(KanbanCard card) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.kanbanCardIsars.put(KanbanCardIsar.fromDomain(card));
    });
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.kanbanCardIsars.filter().idEqualTo(id).deleteAll();
    });
  }

  @override
  Future<void> moveCard(String id, KanbanStatus status, int order) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      final card = await isar.kanbanCardIsars.filter().idEqualTo(id).findFirst();
      if (card != null) {
        card.status = status;
        card.order = order;
        await isar.kanbanCardIsars.put(card);
      }
    });
  }
}
