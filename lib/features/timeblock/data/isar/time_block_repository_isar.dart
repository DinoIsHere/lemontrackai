import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/time_block_schema.dart';
import '../../domain/time_block.dart';
import '../time_block_repository.dart';

class IsarTimeBlockRepository implements TimeBlockRepository {
  Future<Isar> get _db async => IsarService.instance;

  @override
  Future<List<TimeBlock>> getBlocksForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final isar = await _db;
    final blocks = await isar.timeBlockIsars
        .filter()
        .startLessThan(end)
        .and()
        .endGreaterThan(start)
        .findAll();
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks.map((b) => b.toDomain()).toList();
  }

  @override
  Future<List<TimeBlock>> getBlocksForRange(DateTime start, DateTime end) async {
    final isar = await _db;
    final blocks = await isar.timeBlockIsars
        .filter()
        .startLessThan(end)
        .and()
        .endGreaterThan(start)
        .findAll();
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks.map((b) => b.toDomain()).toList();
  }

  @override
  Future<List<TimeBlock>> getAllBlocks() async {
    final isar = await _db;
    final blocks = await isar.timeBlockIsars.where().findAll();
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks.map((b) => b.toDomain()).toList();
  }

  @override
  Future<TimeBlock> createBlock(TimeBlock block) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.timeBlockIsars.put(TimeBlockIsar.fromDomain(block));
    });
    return block;
  }

  @override
  Future<TimeBlock> updateBlock(TimeBlock block) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.timeBlockIsars.put(TimeBlockIsar.fromDomain(block));
    });
    return block;
  }

  @override
  Future<void> deleteBlock(String id) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.timeBlockIsars.filter().idEqualTo(id).deleteAll();
    });
  }
}
