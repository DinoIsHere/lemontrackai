import 'package:flutter/material.dart';

class TimeBlock {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String? linkedTaskId;
  final Color? color;
  final bool isFocus;

  const TimeBlock({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.linkedTaskId,
    this.color,
    this.isFocus = false,
  });

  TimeBlock copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    String? description,
    String? linkedTaskId,
    Color? color,
    bool? isFocus,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      color: color ?? this.color,
      isFocus: isFocus ?? this.isFocus,
    );
  }
}
