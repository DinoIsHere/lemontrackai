import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../../features/timeblock/domain/time_block.dart';

part 'time_block_schema.g.dart';

@collection
class TimeBlockIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String id;

  late String title;

  @Index()
  late DateTime start;

  @Index()
  late DateTime end;

  String? description;

  String? linkedTaskId;

  int? colorValue;

  bool isFocus = false;

  TimeBlock toDomain() => TimeBlock(
        id: id,
        title: title,
        start: start,
        end: end,
        description: description,
        linkedTaskId: linkedTaskId,
        color: colorValue == null ? null : Color(colorValue!),
        isFocus: isFocus,
      );

  static TimeBlockIsar fromDomain(TimeBlock block) {
    final model = TimeBlockIsar()
      ..id = block.id
      ..title = block.title
      ..start = block.start
      ..end = block.end
      ..description = block.description
      ..linkedTaskId = block.linkedTaskId
      ..colorValue = block.color?.value
      ..isFocus = block.isFocus;
    return model;
  }
}
