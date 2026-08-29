import 'package:flutter/material.dart';

import '../models/enums.dart';

final refbotTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BDB)),
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
