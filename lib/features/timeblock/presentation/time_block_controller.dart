import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/repository_providers.dart';
import '../data/time_block_repository.dart';
import '../domain/time_block.dart';

final timeBlockControllerProvider =
    StateNotifierProvider<TimeBlockController, AsyncValue<List<TimeBlock>>>((ref) {
  final repo = ref.watch(timeBlockRepositoryProvider);
  return TimeBlockController(repo);
});

class TimeBlockController extends StateNotifier<AsyncValue<List<TimeBlock>>> {
  TimeBlockController(this._repo) : super(const AsyncValue.loading()) {
    loadAll();
  }

  final TimeBlockRepository _repo;
  final _uuid = const Uuid();

  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final blocks = await _repo.getAllBlocks();
      state = AsyncValue.data(blocks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadForDay(DateTime day) async {
    state = const AsyncValue.loading();
    try {
      final blocks = await _repo.getBlocksForDay(day);
      state = AsyncValue.data(blocks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TimeBlock> createBlock({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? linkedTaskId,
    dynamic color,
    bool isFocus = false,
    String? id,
  }) async {
    final block = TimeBlock(
      id: id ?? _uuid.v4(),
      title: title,
      start: start,
      end: end,
      description: description,
      linkedTaskId: linkedTaskId,
      color: color,
      isFocus: isFocus,
    );
    final created = await _repo.createBlock(block);
    await loadAll();
    return created;
  }

  Future<TimeBlock> updateBlock(TimeBlock block) async {
    final updated = await _repo.updateBlock(block);
    await loadAll();
    return updated;
  }

  Future<void> deleteBlock(String id) async {
    await _repo.deleteBlock(id);
    await loadAll();
  }
}

