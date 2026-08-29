/// The alphabet the backend generates join codes from: no I, L, O or U, so
/// nobody misreads a code they are typing off a projector.
const joinCodeAlphabet = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';

const joinCodeLength = 6;

/// Upper-cases and strips the spaces and dashes people add when reading aloud.
String normalizeJoinCode(String input) {
  // TODO(step 1)
  throw UnimplementedError();
}

/// Whether a normalized code could exist. Only the server knows if it does.
bool isValidJoinCode(String input) {
  // TODO(step 1): the right length, and every character from the alphabet.
  throw UnimplementedError();
}
