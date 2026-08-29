import 'package:refbot_core/refbot_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeJoinCode', () {
    test('upper-cases and strips what people type', () {
      expect(normalizeJoinCode(' ab2-c3d '), 'AB2C3D');
    });
  });

  group('isValidJoinCode', () {
    test('accepts a code of the right length and alphabet', () {
      expect(isValidJoinCode('ab2c3d'), isTrue);
    });

    test('rejects the wrong length', () {
      expect(isValidJoinCode('AB2C3'), isFalse);
      expect(isValidJoinCode('AB2C3DE'), isFalse);
    });

    test('rejects letters the backend never generates', () {
      expect(isValidJoinCode('ABCDEI'), isFalse);
      expect(isValidJoinCode('ABCDE1'), isFalse);
    });
  });
}
