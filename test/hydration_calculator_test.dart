import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/domain/hydration_calculator.dart';
import 'package:hydraflow/domain/models.dart';

void main() {
  test('calcula hombre de 80 kg con actividad moderada', () {
    const profile = UserProfile(sex: Sex.male, age: 35, weightKg: 80, activityLevel: ActivityLevel.moderate, climate: Climate.temperate);
    expect(HydrationCalculator.calculate(profile), 3300);
  });
  test('calcula mujer de 60 kg sedentaria con clima caluroso', () {
    const profile = UserProfile(sex: Sex.female, age: 35, weightKg: 60, activityLevel: ActivityLevel.sedentary, climate: Climate.hot);
    expect(HydrationCalculator.calculate(profile), 2360);
  });
  test('embarazo suma 300 ml', () {
    const base = UserProfile(sex: Sex.female, age: 35, weightKg: 60, activityLevel: ActivityLevel.sedentary, climate: Climate.temperate);
    expect(HydrationCalculator.calculate(base.copyWith(pregnant: true)) - HydrationCalculator.calculate(base), 300);
  });
  test('aplica límites', () {
    const low = UserProfile(sex: Sex.female, age: 35, weightKg: 20, activityLevel: ActivityLevel.sedentary, climate: Climate.cold);
    const high = UserProfile(sex: Sex.male, age: 35, weightKg: 300, activityLevel: ActivityLevel.veryActive, climate: Climate.hot);
    expect(HydrationCalculator.calculate(low), 1500);
    expect(HydrationCalculator.calculate(high), 6000);
  });
}
