import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_store.dart';
import '../../domain/time_block.dart';
import '../time_block_repository.dart';

class LocalTimeBlockRepository implements TimeBlockRepository {
  final _uuid = const Uuid();

  Future<List<TimeBlock>> _load() async {
    final data = await LocalStore.getBlocksJson();
    final blocks = <TimeBlock>[];
    for (final m in data) {
      final mm = Map<String, dynamic>.from(m);
      blocks.add(TimeBlock(
        id: mm['id'],
        title: mm['title'],
        start: DateTime.parse(mm['start']),
        end: DateTime.parse(mm['end']),
        description: mm['description'],
        linkedTaskId: mm['linkedTaskId'],
        color: mm['colorValue'] == null ? null : Color(mm['colorValue']),
        isFocus: mm['isFocus'] ?? false,
      ));
    }
    return blocks;
  }

  Future<void> _save(List<TimeBlock> blocks) async {
    final data = blocks
        .map((b) => {
              'id': b.id,
              'title': b.title,
              'start': b.start.toIso8601String(),
              'end': b.end.toIso8601String(),
              'description': b.description,
              'linkedTaskId': b.linkedTaskId,
              'colorValue': b.color?.value,
              'isFocus': b.isFocus,
            })
        .toList();
    await LocalStore.saveBlocksJson(data);
  }

  @override
  Future<List<TimeBlock>> getBlocksForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final blocks = await _load();
    final filtered = blocks.where((b) => b.start.isBefore(end) && b.end.isAfter(start)).toList();
    filtered.sort((a, b) => a.start.compareTo(b.start));
    return filtered;
  }

  @override
  Future<List<TimeBlock>> getBlocksForRange(DateTime start, DateTime end) async {
    final blocks = await _load();
    final filtered = blocks.where((b) => b.start.isBefore(end) && b.end.isAfter(start)).toList();
    filtered.sort((a, b) => a.start.compareTo(b.start));
    return filtered;
  }

  @override
  Future<List<TimeBlock>> getAllBlocks() async {
    final blocks = await _load();
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks;
  }

  @override
  Future<TimeBlock> createBlock(TimeBlock block) async {
    final blocks = await _load();
    final newBlock = block.id.isEmpty ? block.copyWith(id: _uuid.v4()) : block;
    blocks.add(newBlock);
    await _save(blocks);
    return newBlock;
  }

  @override
  Future<TimeBlock> updateBlock(TimeBlock block) async {
    final blocks = await _load();
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx == -1) {
      blocks.add(block);
    } else {
      blocks[idx] = block;
    }
    await _save(blocks);
    return block;
  }

  @override
  Future<void> deleteBlock(String id) async {
    final blocks = await _load();
    blocks.removeWhere((b) => b.id == id);
    await _save(blocks);
  }
}
