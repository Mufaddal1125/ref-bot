import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/debate.dart';
import '../models/enums.dart';
import '../providers/debate_provider.dart';
import 'tally_bar.dart';

/// Shown once the debate ends: the ballot, then the result.
class VotePanel extends StatelessWidget {
  const VotePanel({required this.debate, required this.role, super.key});

  final Debate debate;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final debates = context.watch<DebateProvider>();
    final stillOpen = debate.status == DebateStatus.voting;
    final hasVoted = debates.myVote != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            stillOpen && !hasVoted
                ? 'Who won the debate?'
                : 'Who won the debate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (stillOpen && !hasVoted)
            _Ballot(busy: debates.isLoading)
          else
            TallyBar(tally: debate.tally),
          if (role == Role.moderator && stillOpen) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: debates.close,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Close voting'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Ballot extends StatelessWidget {
  const _Ballot({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final debates = context.read<DebateProvider>();

    return Row(
      children: [
        for (final side in Side.values) ...[
          if (side == Side.teamB) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : () => debates.vote(side),
              style: FilledButton.styleFrom(
                backgroundColor: sideColor(context, side),
              ),
              child: Text(side.label),
            ),
          ),
        ],
      ],
    );
  }
}
