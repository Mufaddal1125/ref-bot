/// Anything with a value the backend understands.
///
/// Mixed into every enum that crosses the wire, so one lookup serves them all.
mixin Wire {
  String get wire;
}

/// Finds the enum value the backend sent, or null when it sent something new.
T? fromWire<T extends Wire>(List<T> values, String? wire) {
  for (final value in values) {
    if (value.wire == wire) {
      return value;
    }
  }
  return null;
}
