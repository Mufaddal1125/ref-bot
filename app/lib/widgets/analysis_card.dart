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

    // TODO(step 5): a Column, crossAxisAlignment start, holding one _Line for
    // every finding — a collection-for over each of the three lists in turn:
    //
    //   analysis.fallacies       '🚨'  fallacy.name        fallacy.explanation
    //                                  titled in colorScheme.error
    //   analysis.missingContext  '⚠'   'Missing context'   gap.text
    //   analysis.claims          '✓'   '<Assessment> claim'
    //                                  '“<text>” — <note>'
    //
    // Three `for (final x in ...)` clauses inside one children list. No
    // .map().toList(), no temporary list built up with add().
    return const SizedBox.shrink();
  }
}

class _Line extends StatelessWidget {
  // title and color are for the findings you are about to list; the one call
  // above needs neither.
  // ignore: unused_element_parameter
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
