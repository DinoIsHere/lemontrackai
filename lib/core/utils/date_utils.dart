import 'package:intl/intl.dart';

String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String formatDate(DateTime d) => DateFormat('EEE, MMM d').format(d);

String formatTime(DateTime d) => DateFormat('h:mm a').format(d);

String formatTimeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} – ${formatTime(end)}';

DateTime startOfWeek(DateTime d) {
  final diff = d.weekday - DateTime.monday;
  final monday = d.subtract(Duration(days: diff));
  return DateTime(monday.year, monday.month, monday.day);
}

List<DateTime> weekDays(DateTime anchor) {
  final monday = startOfWeek(anchor);
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;