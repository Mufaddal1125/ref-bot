import 'package:refbot_core/refbot_core.dart';
import 'package:test/test.dart';

enum Fruit with Wire {
  apple('apple'),
  pear('pear');

  const Fruit(this.wire);

  @override
  final String wire;
}

void main() {
  test('fromWire finds the value the backend sent', () {
    expect(fromWire(Fruit.values, 'pear'), Fruit.pear);
  });

  test('fromWire returns null for something it has never seen', () {
    expect(fromWire(Fruit.values, 'durian'), isNull);
    expect(fromWire(Fruit.values, null), isNull);
  });
}
