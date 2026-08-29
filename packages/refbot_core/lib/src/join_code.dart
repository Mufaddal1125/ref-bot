/// The alphabet the backend generates join codes from: no I, L, O or U, so
/// nobody misreads a code they are typing off a projector.
const joinCodeAlphabet = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';

const joinCodeLength = 6;

/// Upper-cases and strips the spaces and dashes people add when reading aloud.
String normalizeJoinCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// Whether a normalized code could exist. Only the server knows if it does.
bool isValidJoinCode(String input) {
  final code = normalizeJoinCode(input);
  return code.length == joinCodeLength &&
      code.split('').every(joinCodeAlphabet.contains);
}
