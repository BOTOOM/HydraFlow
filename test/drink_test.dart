import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/domain/drink.dart';

void main() {
  test('calcula ml efectivos con coeficiente', () {
    expect(drinks.firstWhere((d) => d.id == 'milk').effectiveMl(250), 225);
    expect(drinks.firstWhere((d) => d.id == 'water').effectiveMl(350), 350);
  });
}
