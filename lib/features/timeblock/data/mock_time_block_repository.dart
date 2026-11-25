import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import './time_block_repository.dart';
import '../domain/time_block.dart';

class MockTimeBlockRepository implements TimeBlockRepository {
  MockTimeBlockRepository() {
    _seed();
  }

  final _blocks = <TimeBlock>[];
  final _uuid = const Uuid();
  final _rand = Random();

  void _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _blocks.addAll([
      TimeBlock(
        id: _uuid.v4(),
        title: 'Focus block',
        start: today.add(const Duration(hours: 13)),
        end: today.add(const Duration(hours: 15)),
        isFocus: true,
        color: const Color(0xFF6C5CE7),
      ),
    ]);
    _rand.nextInt(1);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<List<TimeBlock>> getBlocksForDay(DateTime day) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _blocks.where((b) => _sameDay(b.start, day)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(list);
  }

  @override
  Future<List<TimeBlock>> getBlocksForRange(DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _blocks
        .where((b) => !b.start.isBefore(start) && b.start.isBefore(end))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(list);
  }

  @override
  Future<List<TimeBlock>> getAllBlocks() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = List<TimeBlock>.from(_blocks)
      ..sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(list);
  }

  @override
  Future<TimeBlock> createBlock(TimeBlock block) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newBlock = TimeBlock(
      id: block.id.isEmpty ? _uuid.v4() : block.id,
      title: block.title,
      start: block.start,
      end: block.end,
      description: block.description,
      linkedTaskId: block.linkedTaskId,
      color: block.color,
      isFocus: block.isFocus,
    );
    _blocks.add(newBlock);
    return newBlock;
  }

  @override
  Future<TimeBlock> updateBlock(TimeBlock block) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _blocks.indexWhere((b) => b.id == block.id);
    if (index == -1) {
      _blocks.add(block);
      return block;
    }
    _blocks[index] = block;
    return block;
  }

  @override
  Future<void> deleteBlock(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _blocks.removeWhere((b) => b.id == id);
  }
}
