import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/participant.dart';

/// Who is in the room. A grid, because names are short and there can be many.
class ParticipantGrid extends StatelessWidget {
  const ParticipantGrid({required this.participants, super.key});

  final List<Participant> participants;

  @override
  Widget build(BuildContext context) {
    // TODO(step 6): replace this Column with a GridView.builder — shrinkWrap,
    // NeverScrollableScrollPhysics (the panel around it already scrolls),
    // padded by 12, and laid out by a
    // SliverGridDelegateWithMaxCrossAxisExtent: maxCrossAxisExtent 180,
    // mainAxisExtent 56, 8 of spacing each way.
    //
    // The fixed mainAxisExtent is the point. Without it the grid has to ask
    // every chip how tall it wants to be before it can lay any of them out —
    // an intrinsic pass that grows with the room. With it, the row height is
    // known up front however many people join.
    return Column(
      children: [
        for (final participant in participants)
          _ParticipantChip(participant: participant),
      ],
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
