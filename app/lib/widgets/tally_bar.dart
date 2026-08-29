import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/enums.dart';
import '../models/vote_tally.dart';

/// The result, drawn rather than laid out: one rounded bar split by the vote.
class TallyBar extends StatelessWidget {
  const TallyBar({required this.tally, super.key});

  final VoteTally tally;

  @override
  Widget build(BuildContext context) {
    final colorA = sideColor(context, Side.teamA);
    final colorB = sideColor(context, Side.teamB);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Score(side: Side.teamA, count: tally.teamA, share: tally.shareA),
            _Score(
              side: Side.teamB,
              count: tally.teamB,
              share: tally.shareB,
              alignRight: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // The share animates, so the bar slides as votes land instead of jumping.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: tally.shareA),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (_, share, _) => CustomPaint(
            size: const Size(double.infinity, 28),
            painter: _TallyBarPainter(
              shareA: share,
              colorA: colorA,
              colorB: colorB,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tally.total == 1 ? '1 vote' : '${tally.total} votes',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({
    required this.side,
    required this.count,
    required this.share,
    this.alignRight = false,
  });

  final Side side;
  final int count;
  final double share;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = sideColor(context, side);

    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(side.label, style: theme.textTheme.labelLarge?.copyWith(color: color)),
        Text(
          '${(share * 100).round()}%',
          style: theme.textTheme.headlineMedium?.copyWith(color: color),
        ),
        Text('$count', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TallyBarPainter extends CustomPainter {
  const _TallyBarPainter({
    required this.shareA,
    required this.colorA,
    required this.colorB,
  });

  final double shareA;
  final Color colorA;
  final Color colorB;

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.clipRRect(rounded);

    final split = size.width * shareA;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, split, size.height),
      Paint()..color = colorA,
    );
    canvas.drawRect(
      Rect.fromLTWH(split, 0, size.width - split, size.height),
      Paint()..color = colorB,
    );
  }

  @override
  bool shouldRepaint(_TallyBarPainter old) =>
      old.shareA != shareA || old.colorA != colorA || old.colorB != colorB;
}
