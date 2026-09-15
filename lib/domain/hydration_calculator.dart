import 'models.dart';

class HydrationCalculator {
  static int calculate(UserProfile profile) {
    var base = profile.weightKg *
        (profile.sex == Sex.male ? 35 : profile.sex == Sex.female ? 31 : 33);
    if (profile.age >= 65) base *= .95;
    if (profile.age < 18) base = (profile.weightKg * 40).clamp(0, 2500).toDouble();
    const activity = {
      ActivityLevel.sedentary: 0, ActivityLevel.light: 250,
      ActivityLevel.moderate: 500, ActivityLevel.active: 750,
      ActivityLevel.veryActive: 1000,
    };
    const climate = {Climate.cold: 0, Climate.temperate: 0, Climate.hot: 500};
    base += activity[profile.activityLevel]!.toDouble();
    base += climate[profile.climate]!.toDouble();
    if (profile.pregnant) base += 300;
    if (profile.breastfeeding) base += 700;
    return ((base.clamp(1500, 6000) / 10).round() * 10).toInt();
  }
}
