import '../domain/models.dart';

const _mlPerOz = 29.5735;

String formatVolume(int milliliters, UnitPreference unit) {
  if (unit == UnitPreference.ml) return '$milliliters ml';
  final ounces = milliliters / _mlPerOz;
  final rounded = ounces.roundToDouble() == ounces
      ? ounces.toStringAsFixed(0)
      : ounces.toStringAsFixed(1);
  return '$rounded oz';
}

String formatVolumePair(int totalMl, int goalMl, UnitPreference unit) =>
    '${formatVolume(totalMl, unit)} / ${formatVolume(goalMl, unit)}';
