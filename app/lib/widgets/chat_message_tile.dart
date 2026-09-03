import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/chat_message.dart';
import '../models/enums.dart';

/// One line of chat, laid out the way a live chat is: dense, and with the name
/// inline with the words so a long message wraps under its own timestamp.
class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({required this.message, this.onDelete, super.key});

  final ChatMessage message;

  /// Set only for the moderator, and only on a message still standing.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.Hm().format(message.createdAt.toLocal());
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: message.isDeleted
                ? _removed(context, time, muted)
                : _said(context, time, muted),
          ),
          if (onDelete != null)
            // Small and quiet: it sits on every line the moderator can see, so
            // it has to stay out of the way of reading them.
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.backspace_outlined, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color: theme.colorScheme.outline,
              tooltip: 'Remove this message',
            ),
        ],
      ),
    );
  }

  /// The name is dropped along with the words. The room needs to know a message
  /// went, not who is being made an example of.
  Widget _removed(BuildContext context, String time, TextStyle? muted) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$time  ', style: muted),
          TextSpan(
            text: 'message removed by the moderator',
            style: muted?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _said(BuildContext context, String time, TextStyle? muted) {
    final theme = Theme.of(context);
    final badge = _badgeFor(message.authorRole);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$time  ', style: muted),
          if (badge != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _RoleBadge(role: message.authorRole, label: badge),
              ),
            ),
          TextSpan(
            text: '${message.authorName}  ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: authorColor(context, message.authorName),
            ),
          ),
          TextSpan(text: message.body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// The audience is everybody, so it wears no badge — only the people with a
  /// stake in the debate are worth marking out.
  static String? _badgeFor(Role role) => switch (role) {
    Role.moderator => 'MOD',
    Role.teamA => 'A',
    Role.teamB => 'B',
    Role.audience => null,
  };
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.label});

  final Role role;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(context, role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
