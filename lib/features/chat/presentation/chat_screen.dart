import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_providers.dart';
import '../../../shared/widgets/chat_input_bar.dart';
import '../../../shared/widgets/lemon_drawer.dart';
import 'chat_controller.dart';
import '../domain/chat_thread.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  final ScrollController _scroll = ScrollController();

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(widget.threadId, text);
      ref.invalidate(messagesProvider(widget.threadId));
      ref.invalidate(threadsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.threadId));
    final threads = ref.watch(threadsProvider).valueOrNull ?? [];
    ChatThread? thread;
    for (final t in threads) {
      if (t.id == widget.threadId) {
        thread = t;
        break;
      }
    }
    final title = thread?.title ?? 'Chat';

    return Scaffold(
      drawer: const LemonDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (messages.isEmpty) {
                  return const Center(child: Text('Start the conversation'));
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i < messages.length) {
                      return MessageBubble(message: messages[i]);
                    }
                    return const TypingIndicator();
                  },
                );
              },
            ),
          ),
          ChatInputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}