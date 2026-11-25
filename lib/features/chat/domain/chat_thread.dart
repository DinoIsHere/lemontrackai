class ChatThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatThread copyWith({String? title, DateTime? updatedAt}) => ChatThread(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}