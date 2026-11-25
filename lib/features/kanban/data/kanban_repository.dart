import '../domain/kanban_card.dart';

abstract class KanbanRepository {
  Future<List<KanbanCard>> getAllCards();
  Future<List<KanbanCard>> getCardsByStatus(KanbanStatus status);
  Future<KanbanCard> createCard(KanbanCard card);
  Future<KanbanCard> updateCard(KanbanCard card);
  Future<void> deleteCard(String id);
  Future<void> moveCard(String id, KanbanStatus status, int order);
}
