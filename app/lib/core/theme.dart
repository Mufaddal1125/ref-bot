import 'package:flutter/material.dart';

import '../models/enums.dart';

final refbotTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BDB)),
  fontFamily: 'SpaceGrotesk',
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
  ),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);

/// Team A and Team B keep the same colour everywhere they appear.
Color sideColor(BuildContext context, Side side) => switch (side) {
  Side.teamA => Theme.of(context).colorScheme.primary,
  Side.teamB => Theme.of(context).colorScheme.tertiary,
};

/// The colour a role's badge wears in chat. Team colours carry over; the
/// moderator gets the one colour left that is not either team's.
Color roleColor(BuildContext context, Role role) {
  final side = role.side;
  if (side != null) {
    return sideColor(context, side);
  }
  return switch (role) {
    Role.moderator => Theme.of(context).colorScheme.secondary,
    _ => Theme.of(context).colorScheme.outline,
  };
}

/// A stable colour per chat author, so a name is recognisable at a glance in a
/// fast-moving list.
///
/// The hash is spelled out rather than taken from [String.hashCode], which is
/// only promised to be consistent within one run of one implementation — two
/// people in the same room would see the same name in different colours.
Color authorColor(BuildContext context, String name) {
  var hash = 0;
  for (final unit in name.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // Fixed saturation and lightness: only the hue varies, so every name is
  // equally readable against the background rather than merely different.
  return HSLColor.fromAHSL(
    1,
    (hash % 360).toDouble(),
    0.55,
    isDark ? 0.72 : 0.36,
  ).toColor();
}
