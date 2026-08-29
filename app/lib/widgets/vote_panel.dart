import 'package:flutter/material.dart';

import '../models/debate.dart';
import '../models/enums.dart';

/// Shown once the debate ends: the ballot, then the result.
class VotePanel extends StatelessWidget {
  const VotePanel({required this.debate, required this.role, super.key});

  final Debate debate;
  final Role role;

  @override
  Widget build(BuildContext context) {
    // TODO(step 8): the ballot, and the result once it has been cast.
    //
    // Voting is still open while debate.status is DebateStatus.voting, and
    // this device has voted when context.watch<DebateProvider>().myVote is
    // not null. Those two decide everything here:
    //
    //   title   'Who won the debate?' while there is still a choice to make,
    //           'Who won the debate' once there is not — titleMedium
    //   open and not yet voted   a Row of two Expanded FilledButtons, one per
    //                            Side.values, each in sideColor(context, side),
    //                            calling debates.vote(side); null while
    //                            debates.isLoading
    //   otherwise                TallyBar(tally: debate.tally)
    //   moderator, still open    an OutlinedButton 'Close voting' calling
    //                            debates.close()
    //
    // Pull the ballot out into a private _Ballot widget once build passes
    // sixty lines — a class rebuilds on its own, a _buildBallot() method does
    // not.
    return const SizedBox.shrink();
  }
}
