import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/analysis.dart';
import '../models/argument.dart';
import '../models/enums.dart';
import 'analysis_card.dart';

class ArgumentTile extends StatefulWidget {
  const ArgumentTile({required this.argument, super.key});

  final Argument argument;

  @override
  State<ArgumentTile> createState() => _ArgumentTileState();
}

class _ArgumentTileState extends State<ArgumentTile> {
  // Ephemeral state: whether this one tile is open. Nobody else needs to know,
  // so it lives here in setState rather than in a provider.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final argument = widget.argument;
    final analysis = argument.analysis;
    final color = sideColor(context, argument.side);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: analysis == null
            ? null
            : () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '${argument.side.label} — Round ${argument.roundNumber}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: color),
                  ),
                  const Spacer(),
                  if (argument.authorName != null)
                    Text(
                      argument.authorName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(argument.body),
              if (analysis != null) ...[
                const Divider(height: 24),
                _RefereeRow(analysis: analysis, expanded: _expanded),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _expanded && analysis.result != null
                      ? AnalysisCard(analysis: analysis.result!)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RefereeRow extends StatelessWidget {
  const _RefereeRow({required this.analysis, required this.expanded});

  final Analysis analysis;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;

    if (analysis.status.isWaiting) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('Referee is thinking…', style: style),
        ],
      );
    }

    if (analysis.status == AnalysisStatus.failed) {
      return Text(
        'Referee unavailable: ${analysis.error ?? 'unknown error'}',
        style: style?.copyWith(color: Theme.of(context).colorScheme.error),
      );
    }

    final result = analysis.result;
    final summary = result == null || result.findings == 0
        ? 'Referee found nothing to flag'
        : '${result.fallacies.length} 🚨   ${result.missingContext.length} ⚠   '
              '${result.claims.length} ✓';

    return Row(
      children: [
        Text(summary, style: style),
        const Spacer(),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.expand_more, size: 20),
        ),
      ],
    );
  }
}
