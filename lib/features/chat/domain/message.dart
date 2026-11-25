enum MessageRole { user, assistant, system }

class Message {
  final String id;
  final String threadId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  const Message({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  Message copyWith({String? content, bool? isStreaming}) => Message(
        id: id,
        threadId: threadId,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}