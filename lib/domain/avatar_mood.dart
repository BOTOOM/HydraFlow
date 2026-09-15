/// Emotional state of the droplet avatar, derived from how the user's intake
/// compares with the intake expected at the current moment of the day.
enum Mood {
  /// Day just started: a fresh, cheerful greeting.
  morning,

  /// Goal reached during the day.
  radiant,

  /// On track or ahead of the expected pace.
  happy,

  /// Slightly behind the expected pace.
  okay,

  /// Clearly behind: thirsty and a bit deflated.
  thirsty,

  /// Far behind late in the day: wilted and sad.
  wilted,

  /// Night with the goal (nearly) reached: sleepy and very happy.
  nightHappy,

  /// Night without reaching the goal: tired and thirsty.
  nightSleepy,
}

class AvatarState {
  const AvatarState({
    required this.mood,
    required this.vitality,
    required this.dayFraction,
    required this.ratio,
  });

  final Mood mood;

  /// 0 = dried out, 1 = fully hydrated. Drives colour and plumpness.
  final double vitality;

  /// 0 at wake time, 1 at sleep time.
  final double dayFraction;

  /// Intake / goal.
  final double ratio;

  bool get isNight => mood == Mood.nightHappy || mood == Mood.nightSleepy;

  String get message => switch (mood) {
        Mood.morning => '¡Buen día! Empecemos con un vaso de agua.',
        Mood.radiant => '¡Meta cumplida! Estoy rebosante.',
        Mood.happy => 'Vamos muy bien, sigue así.',
        Mood.okay => 'Un sorbito ahora me vendría genial.',
        Mood.thirsty => 'Tengo sed… ¿me das un poco de agua?',
        Mood.wilted => 'Me estoy secando. ¡Agua, por favor!',
        Mood.nightHappy => 'Qué gran día. Mañana seguimos.',
        Mood.nightSleepy => 'Quedó agua pendiente… mañana lo logramos.',
      };
}

/// Fraction of the awake window elapsed at [now]; < 0 before waking and > 1
/// after bedtime. Handles bedtimes past midnight.
double awakeFraction(
  DateTime now, {
  required int wakeHour,
  required int wakeMinute,
  required int sleepHour,
  required int sleepMinute,
}) {
  final minutesNow = now.hour * 60 + now.minute;
  final wake = wakeHour * 60 + wakeMinute;
  var sleep = sleepHour * 60 + sleepMinute;
  if (sleep <= wake) sleep += 24 * 60;
  var current = minutesNow;
  if (current < wake && current + 24 * 60 <= sleep) current += 24 * 60;
  return (current - wake) / (sleep - wake);
}

AvatarState avatarStateFor({
  required int totalMl,
  required int goalMl,
  required DateTime now,
  int wakeHour = 7,
  int wakeMinute = 0,
  int sleepHour = 22,
  int sleepMinute = 0,
  DateTime? lastDrinkAt,
}) {
  final goal = goalMl <= 0 ? 1 : goalMl;
  final ratio = totalMl / goal;
  final sinceDrink = lastDrinkAt == null ? null : now.difference(lastDrinkAt);
  final recentlyDrank =
      sinceDrink != null && !sinceDrink.isNegative && sinceDrink.inMinutes < 20;
  final raw = awakeFraction(
    now,
    wakeHour: wakeHour,
    wakeMinute: wakeMinute,
    sleepHour: sleepHour,
    sleepMinute: sleepMinute,
  );
  final day = raw.clamp(0.0, 1.0);
  final night = raw < 0 || raw >= 1;
  final expected = day;
  final delta = ratio - expected + (recentlyDrank ? 0.15 : 0);
  final vitality = (0.55 + delta * 1.6).clamp(0.0, 1.0);

  final Mood mood;
  if (night) {
    mood = ratio >= 0.8 ? Mood.nightHappy : Mood.nightSleepy;
  } else if (ratio >= 1) {
    mood = Mood.radiant;
  } else if (day < 0.08 && ratio < 0.15) {
    mood = Mood.morning;
  } else if (delta >= -0.06) {
    mood = Mood.happy;
  } else if (delta >= -0.2) {
    mood = Mood.okay;
  } else if (delta >= -0.4 || day < 0.5) {
    mood = Mood.thirsty;
  } else {
    mood = Mood.wilted;
  }
  return AvatarState(
    mood: mood,
    vitality: ratio >= 1 ? 1 : vitality,
    dayFraction: day,
    ratio: ratio,
  );
}
