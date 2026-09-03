import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/enums.dart';
import '../providers/debate_provider.dart';
import 'chat_message_tile.dart';

/// The room's live chat: a list that follows the newest line, and a box to add
/// one. Everybody can write here, in every phase of the debate.
class ChatPanel extends StatefulWidget {
  const ChatPanel({required this.role, super.key});

  final Role role;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _scroll = ScrollController();
  final _body = TextEditingController();
  final _focus = FocusNode();

  /// How many messages the list has already been scrolled for.
  int _seen = 0;

  /// Whether the list should keep following. Scrolling up turns this off, so
  /// reading something from a minute ago is not yanked away mid-sentence.
  bool _stick = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_watchStickiness);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _body.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _watchStickiness() {
    if (!_scroll.hasClients) {
      return;
    }
    final atBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 32;
    if (atBottom != _stick) {
      setState(() => _stick = atBottom);
    }
  }

  /// A live chat jumps rather than glides: at four messages a second an
  /// animation never finishes before the next one starts it again.
  void _toLatest({bool animate = false}) {
    if (!_scroll.hasClients) {
      return;
    }
    final bottom = _scroll.position.maxScrollExtent;
    if (animate) {
      _scroll.animateTo(
        bottom,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(bottom);
    }
  }

  void _send() {
    final text = _body.text.trim();
    if (text.isEmpty) {
      return;
    }
    context.read<DebateProvider>().sendChat(text);
    _body.clear();
    setState(() => _stick = true);
    // Sending should not cost the keyboard, or a conversation is one message
    // and a tap, over and over.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final debates = context.watch<DebateProvider>();
    final messages = debates.chatMessages;

    // build is where this widget hears about new messages, so it is where the
    // follow is scheduled. The scroll itself waits for the row to exist.
    if (messages.length != _seen) {
      _seen = messages.length;
      if (_stick) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _toLatest());
      }
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _messages(messages, debates),
              if (!_stick)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Center(
                    child: _JumpToLatest(
                      unread: debates.unreadChat,
                      onPressed: () {
                        setState(() => _stick = true);
                        _toLatest(animate: true);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (debates.chatError != null) _ChatError(message: debates.chatError!),
        _composer(debates),
      ],
    );
  }

  Widget _messages(List<ChatMessage> messages, DebateProvider debates) {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No messages yet. Say hello.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final message = messages[i];
        final canRemove =
            widget.role == Role.moderator && !message.isDeleted;
        return ChatMessageTile(
          message: message,
          onDelete: canRemove
              ? () => debates.deleteChatMessage(message.id)
              : null,
        );
      },
    );
  }

  Widget _composer(DebateProvider debates) {
    final canSend = debates.isConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _body,
              focusNode: _focus,
              enabled: canSend,
              maxLength: 500,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: canSend ? 'Say something…' : 'Reconnecting…',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: canSend ? _send : null,
            icon: const Icon(Icons.send, size: 18),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}

class _JumpToLatest extends StatelessWidget {
  const _JumpToLatest({required this.unread, required this.onPressed});

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_downward, size: 16),
      label: Text(unread == 0 ? 'Jump to latest' : '$unread new'),
      style: FilledButton.styleFrom(
        // The theme gives every filled button a full-width minimum, which is
        // not what a floating pill wants.
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          IconButton(
            onPressed: context.read<DebateProvider>().clearChatError,
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            color: scheme.onErrorContainer,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
