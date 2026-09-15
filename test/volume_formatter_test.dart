import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/domain/models.dart';
import 'package:hydraflow/ui/formatters.dart';

void main() {
  test('formatea volúmenes en ml y onzas', () {
    expect(formatVolume(250, UnitPreference.ml), '250 ml');
    expect(formatVolume(250, UnitPreference.oz), '8.5 oz');
  });
}
