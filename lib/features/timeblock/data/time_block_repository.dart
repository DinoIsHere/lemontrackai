import '../domain/time_block.dart';

abstract class TimeBlockRepository {
  Future<List<TimeBlock>> getBlocksForDay(DateTime day);
  Future<List<TimeBlock>> getBlocksForRange(DateTime start, DateTime end);
  Future<List<TimeBlock>> getAllBlocks();
  Future<TimeBlock> createBlock(TimeBlock block);
  Future<TimeBlock> updateBlock(TimeBlock block);
  Future<void> deleteBlock(String id);
}
