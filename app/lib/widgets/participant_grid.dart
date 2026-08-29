import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/participant.dart';

/// Who is in the room. A grid, because names are short and there can be many.
class ParticipantGrid extends StatelessWidget {
  const ParticipantGrid({required this.participants, super.key});

  final List<Participant> participants;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      // A fixed extent means no intrinsic pass, however many people join.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 56,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: participants.length,
      itemBuilder: (_, i) => _ParticipantChip(participant: participants[i]),
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final side = participant.role.side;
    final color = side == null
        ? Theme.of(context).colorScheme.outline
        : sideColor(context, side);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            participant.displayName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            participant.role.label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
