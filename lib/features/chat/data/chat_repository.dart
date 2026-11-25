import '../domain/chat_thread.dart';
import '../domain/message.dart';

abstract class ChatRepository {
  Future<List<ChatThread>> getThreads();
  Future<ChatThread> createThread({String? title});
  Future<List<Message>> getMessages(String threadId);
  Future<Message> sendMessage(String threadId, String content);
}