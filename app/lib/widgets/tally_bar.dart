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
        // TODO(step 7): wrap this CustomPaint in a TweenAnimationBuilder<double>
        // — tween 0.5 to tally.shareA, 450ms, Curves.easeOutCubic — and hand
        // the builder's value to the painter in place of tally.shareA.
        //
        // The painter draws whatever number it is given. Keeping the animation
        // outside it is what lets the bar slide as votes land, one repaint per
        // frame, without the painter knowing anything about time.
        CustomPaint(
          size: const Size(double.infinity, 28),
          painter: _TallyBarPainter(
            shareA: tally.shareA,
            colorA: colorA,
            colorB: colorB,
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
    // TODO(step 7): a Column — crossAxisAlignment end when alignRight, start
    // otherwise — holding three lines:
    //
    //   side.label                  labelLarge, in sideColor(context, side)
    //   '${(share * 100).round()}%' headlineMedium, same colour
    //   '$count'                    bodySmall, no colour
    return const SizedBox.shrink();
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
    // TODO(step 6): clip the canvas to a fully rounded rectangle, then fill
    // the left shareA of the width in colorA and the remainder in colorB.
  }

  @override
  bool shouldRepaint(_TallyBarPainter old) =>
      old.shareA != shareA || old.colorA != colorA || old.colorB != colorB;
}
