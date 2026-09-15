import 'dart:convert';
import 'hydration_calculator.dart';

enum Sex { male, female, other }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }
enum Climate { cold, temperate, hot }
enum ThemePreference { system, light, dark }
enum UnitPreference { ml, oz }

class UserProfile {
  const UserProfile({
    required this.sex, required this.age, required this.weightKg,
    this.heightCm, required this.activityLevel, required this.climate,
    this.pregnant = false, this.breastfeeding = false, this.customGoalMl,
    this.name = '',
  });
  final Sex sex;
  final int age;
  final double weightKg;
  final double? heightCm;
  final ActivityLevel activityLevel;
  final Climate climate;
  final bool pregnant;
  final bool breastfeeding;
  final int? customGoalMl;
  final String name;
  int goalMl() => customGoalMl ?? HydrationCalculator.calculate(this);
  UserProfile copyWith({
    Sex? sex, int? age, double? weightKg, double? heightCm,
    ActivityLevel? activityLevel, Climate? climate, bool? pregnant,
    bool? breastfeeding, int? customGoalMl, bool clearCustomGoal = false,
    String? name,
  }) => UserProfile(
    sex: sex ?? this.sex, age: age ?? this.age,
    weightKg: weightKg ?? this.weightKg, heightCm: heightCm ?? this.heightCm,
    activityLevel: activityLevel ?? this.activityLevel,
    climate: climate ?? this.climate, pregnant: pregnant ?? this.pregnant,
    breastfeeding: breastfeeding ?? this.breastfeeding,
    customGoalMl: clearCustomGoal ? null : (customGoalMl ?? this.customGoalMl),
    name: name ?? this.name,
  );
  Map<String, dynamic> toJson() => {
    'sex': sex.name, 'age': age, 'weightKg': weightKg, 'heightCm': heightCm,
    'activityLevel': activityLevel.name, 'climate': climate.name,
    'pregnant': pregnant, 'breastfeeding': breastfeeding,
    'customGoalMl': customGoalMl, 'name': name,
  };
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    sex: Sex.values.byName(json['sex'] as String? ?? 'other'),
    age: (json['age'] as num?)?.toInt() ?? 30,
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    activityLevel: ActivityLevel.values.byName(json['activityLevel'] as String? ?? 'moderate'),
    climate: Climate.values.byName(json['climate'] as String? ?? 'temperate'),
    pregnant: json['pregnant'] as bool? ?? false,
    breastfeeding: json['breastfeeding'] as bool? ?? false,
    customGoalMl: (json['customGoalMl'] as num?)?.toInt(),
    name: json['name'] as String? ?? '',
  );
}

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false, this.wakeHour = 8, this.wakeMinute = 0,
    this.sleepHour = 22, this.sleepMinute = 0, this.intervalMinutes = 120,
    this.sound = 'gotas', this.pauseWhenGoalReached = true,
    this.splashEnabled = true,
  });
  final bool enabled;
  final int wakeHour, wakeMinute, sleepHour, sleepMinute, intervalMinutes;
  final String sound;
  final bool pauseWhenGoalReached;
  final bool splashEnabled;
  ReminderSettings copyWith({
    bool? enabled, int? wakeHour, int? wakeMinute, int? sleepHour,
    int? sleepMinute, int? intervalMinutes, String? sound,
    bool? pauseWhenGoalReached, bool? splashEnabled,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled, wakeHour: wakeHour ?? this.wakeHour,
    wakeMinute: wakeMinute ?? this.wakeMinute, sleepHour: sleepHour ?? this.sleepHour,
    sleepMinute: sleepMinute ?? this.sleepMinute,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes, sound: sound ?? this.sound,
    pauseWhenGoalReached: pauseWhenGoalReached ?? this.pauseWhenGoalReached,
    splashEnabled: splashEnabled ?? this.splashEnabled,
  );
  Map<String, dynamic> toJson() => {
    'enabled': enabled, 'wakeHour': wakeHour, 'wakeMinute': wakeMinute,
    'sleepHour': sleepHour, 'sleepMinute': sleepMinute,
    'intervalMinutes': intervalMinutes, 'sound': sound,
    'pauseWhenGoalReached': pauseWhenGoalReached, 'splashEnabled': splashEnabled,
  };
  factory ReminderSettings.fromJson(Map<String, dynamic> json) => ReminderSettings(
    enabled: json['enabled'] as bool? ?? false,
    wakeHour: (json['wakeHour'] as num?)?.toInt() ?? 8,
    wakeMinute: (json['wakeMinute'] as num?)?.toInt() ?? 0,
    sleepHour: (json['sleepHour'] as num?)?.toInt() ?? 22,
    sleepMinute: (json['sleepMinute'] as num?)?.toInt() ?? 0,
    intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 120,
    sound: _migrateReminderSound(json['sound'] as String?),
    pauseWhenGoalReached: json['pauseWhenGoalReached'] as bool? ?? true,
    splashEnabled: json['splashEnabled'] as bool? ?? true,
  );
}

String _migrateReminderSound(String? sound) => switch (sound) {
  'gota' => 'gotas',
  'vertido' => 'chorro',
  _ => sound ?? 'gotas',
};

class IntakeEntry {
  const IntakeEntry({
    this.id, required this.drinkId, required this.volumeMl,
    required this.effectiveMl, required this.timestamp, required this.goalMl,
  });
  final int? id;
  final String drinkId;
  final int volumeMl;
  final int effectiveMl;
  final DateTime timestamp;
  final int goalMl;
  Map<String, dynamic> toMap() => {
    'id': id, 'drink_id': drinkId, 'volume_ml': volumeMl,
    'effective_ml': effectiveMl, 'timestamp': timestamp.millisecondsSinceEpoch,
    'goal_ml': goalMl,
  };
  factory IntakeEntry.fromMap(Map<String, dynamic> map) => IntakeEntry(
    id: map['id'] as int?, drinkId: map['drink_id'] as String,
    volumeMl: map['volume_ml'] as int, effectiveMl: map['effective_ml'] as int,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    goalMl: map['goal_ml'] as int,
  );
}

class CustomDrink {
  const CustomDrink({
    required this.id, required this.name, required this.coefficient,
    required this.defaultSizeMl, this.color = 0xFF1FB6C9, this.icon = 'star',
  });
  final String id;
  final String name;
  final double coefficient;
  final int defaultSizeMl;
  final int color;
  final String icon;
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'coefficient': coefficient,
    'defaultSizeMl': defaultSizeMl, 'color': color, 'icon': icon,
  };
  factory CustomDrink.fromJson(Map<String, dynamic> json) => CustomDrink(
    id: json['id'] as String, name: json['name'] as String,
    coefficient: (json['coefficient'] as num).toDouble(),
    defaultSizeMl: (json['defaultSizeMl'] as num).toInt(),
    color: (json['color'] as num?)?.toInt() ?? 0xFF1FB6C9,
    icon: json['icon'] as String? ?? 'star',
  );
}

String encodeJson(Object value) => jsonEncode(value);
