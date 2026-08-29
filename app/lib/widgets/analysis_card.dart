import 'package:flutter/material.dart';

import '../models/analysis.dart';

/// What the referee found, in the three categories it is allowed to report.
class AnalysisCard extends StatelessWidget {
  const AnalysisCard({required this.analysis, super.key});

  final RefereeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    if (analysis.findings == 0) {
      return const _Line(icon: '✓', text: 'The referee found nothing to flag.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final fallacy in analysis.fallacies)
          _Line(
            icon: '🚨',
            title: fallacy.name,
            text: fallacy.explanation,
            color: Theme.of(context).colorScheme.error,
          ),
        for (final gap in analysis.missingContext)
          _Line(icon: '⚠', title: 'Missing context', text: gap.text),
        for (final claim in analysis.claims)
          _Line(
            icon: '✓',
            title: '${claim.assessment.label} claim',
            text: '“${claim.text}” — ${claim.note}',
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.title, this.color});

  final String icon;
  final String text;
  final String? title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                Text(text, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
