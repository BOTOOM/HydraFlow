import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

class PreferencesRepository {
  PreferencesRepository(this._prefs);
  final SharedPreferences _prefs;
  static const profileKey = 'profile';
  static const remindersKey = 'reminders';
  static const customDrinksKey = 'custom_drinks';
  static const onboardingKey = 'onboarding_done';
  static const themeKey = 'theme';
  static const unitKey = 'unit';

  UserProfile? get profile {
    final raw = _prefs.getString(profileKey);
    return raw == null ? null : UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
  Future<void> saveProfile(UserProfile value) => _prefs.setString(profileKey, jsonEncode(value.toJson()));
  ReminderSettings get reminders {
    final raw = _prefs.getString(remindersKey);
    return raw == null ? const ReminderSettings() : ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
  Future<void> saveReminders(ReminderSettings value) => _prefs.setString(remindersKey, jsonEncode(value.toJson()));
  List<CustomDrink> get customDrinks {
    final raw = _prefs.getString(customDrinksKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => CustomDrink.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<void> saveCustomDrinks(List<CustomDrink> value) => _prefs.setString(customDrinksKey, jsonEncode(value.map((e) => e.toJson()).toList()));
  bool get onboardingDone => _prefs.getBool(onboardingKey) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(onboardingKey, true);
  ThemePreference get theme => ThemePreference.values.byName(_prefs.getString(themeKey) ?? 'system');
  Future<void> saveTheme(ThemePreference value) => _prefs.setString(themeKey, value.name);
  UnitPreference get unit => UnitPreference.values.byName(_prefs.getString(unitKey) ?? 'ml');
  Future<void> saveUnit(UnitPreference value) => _prefs.setString(unitKey, value.name);
}
