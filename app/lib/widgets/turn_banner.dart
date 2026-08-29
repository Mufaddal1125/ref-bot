import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/debate.dart';
import '../models/enums.dart';

class TurnBanner extends StatelessWidget {
  const TurnBanner({required this.debate, required this.role, super.key});

  final Debate debate;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (debate.status) {
      DebateStatus.lobby => ('Waiting for the moderator to start', null),
      DebateStatus.active when debate.isTurnOf(role) => (
        'Your turn — round ${debate.currentRound}',
        sideColor(context, debate.currentSide),
      ),
      DebateStatus.active => (
        '${debate.currentSide.label} to speak — round ${debate.currentRound}',
        sideColor(context, debate.currentSide),
      ),
      DebateStatus.voting => ('The debate has ended', null),
      DebateStatus.closed => ('Results are final', null),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: (color ?? Theme.of(context).colorScheme.outline).withValues(
        alpha: 0.12,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
    );
  }
}
