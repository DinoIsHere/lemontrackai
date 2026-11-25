import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hint = 'Ask Lemon Track…',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize();
      if (mounted) setState(() => _available = ok);
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  Future<void> _toggleListen() async {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input not available on this device.')),
      );
      return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        widget.controller.text = result.recognizedWords;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
      },
    );
    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') {
        if (mounted) setState(() => _listening = false);
      }
    };
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
              color: theme.colorScheme.onSurface,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendIfNotEmpty(),
                decoration: InputDecoration(
                  hintText: _listening ? 'Listening…' : 'Ask Assistant',
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            IconButton(
              icon: Icon(_listening ? Icons.mic : Icons.mic_none),
              onPressed: _toggleListen,
              color: theme.colorScheme.onSurface,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: hasText ? _sendIfNotEmpty : null,
                  color: hasText
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendIfNotEmpty() {
    if (widget.controller.text.trim().isEmpty) return;
    widget.onSend();
  }
}

