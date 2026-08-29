import 'package:flutter/material.dart';

import '../models/debate.dart';
import '../models/enums.dart';

class TurnBanner extends StatelessWidget {
  const TurnBanner({required this.debate, required this.role, super.key});

  final Debate debate;
  final Role role;

  @override
  Widget build(BuildContext context) {
    // TODO(step 7): replace this with one switch expression over
    // debate.status, yielding the text and its colour together as a record:
    //
    //   lobby   'Waiting for the moderator to start'          no colour
    //   active  'Your turn — round N'                         the side's colour
    //           when debate.isTurnOf(role)
    //   active  'Team B to speak — round N'                   the side's colour
    //   voting  'The debate has ended'                        no colour
    //   closed  'Results are final'                           no colour
    //
    // The colour is sideColor(context, debate.currentSide) — import
    // core/theme.dart. A guarded case (`when`) is how the two active cases
    // stay one switch. Cover all five and Dart stops asking for a default.
    final (String text, Color? color) = ('', null);

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
