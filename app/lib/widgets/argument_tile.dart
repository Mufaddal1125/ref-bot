import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/argument.dart';

class ArgumentTile extends StatelessWidget {
  const ArgumentTile({required this.argument, super.key});

  final Argument argument;

  @override
  Widget build(BuildContext context) {
    final color = sideColor(context, argument.side);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                if (argument.authorName != null) ...[
                  const Spacer(),
                  Text(
                    argument.authorName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(argument.body),
          ],
        ),
      ),
    );
  }
}
