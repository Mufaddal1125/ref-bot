import 'package:flutter/material.dart';

import '../models/argument.dart';

class ArgumentTile extends StatelessWidget {
  const ArgumentTile({required this.argument, super.key});

  final Argument argument;

  @override
  Widget build(BuildContext context) {
    // TODO(step 8): one entry in the debate history. A Card with 6 of
    // vertical margin, 16 of padding, holding a Column crossAxisAlignment
    // start:
    //
    //   Row   a 4x16 Container in the side's colour, a gap, then
    //         'Team A — Round 2' in labelLarge in that colour;
    //         a Spacer and argument.authorName when there is one
    //   Text  argument.body
    //
    // The colour is sideColor(context, argument.side) — import core/theme.dart.
    // A Spacer inside a Row is how you push one child to the far end.
    return const Card(child: SizedBox(height: 72, child: Placeholder()));
  }
}
