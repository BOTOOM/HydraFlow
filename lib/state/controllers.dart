import 'package:flutter/foundation.dart';
import '../data/intake_database.dart';
import '../data/preferences_repository.dart';
import '../domain/drink.dart';
import '../domain/models.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this.repository);
  final PreferencesRepository repository;
  UserProfile? profile;
  ThemePreference theme = ThemePreference.system;
  UnitPreference unit = UnitPreference.ml;
  List<CustomDrink> customDrinks = [];
  bool get complete => profile != null;
  Future<void> load() async {
    profile = repository.profile; theme = repository.theme; unit = repository.unit;
    customDrinks = repository.customDrinks; notifyListeners();
  }
  Future<void> save(UserProfile value) async { profile = value; await repository.saveProfile(value); notifyListeners(); }
  Future<void> setCustomGoal(int? value) async {
    if (profile == null) return;
    profile = value == null
        ? profile!.copyWith(clearCustomGoal: true)
        : profile!.copyWith(customGoalMl: value);
    await repository.saveProfile(profile!);
    notifyListeners();
  }
  Future<void> setTheme(ThemePreference value) async { theme = value; await repository.saveTheme(value); notifyListeners(); }
  Future<void> setUnit(UnitPreference value) async { unit = value; await repository.saveUnit(value); notifyListeners(); }
  Future<void> addCustom(CustomDrink drink) async { customDrinks = [...customDrinks, drink]; await repository.saveCustomDrinks(customDrinks); notifyListeners(); }
  Future<void> removeCustom(String id) async { customDrinks = customDrinks.where((d) => d.id != id).toList(); await repository.saveCustomDrinks(customDrinks); notifyListeners(); }
}

class IntakeController extends ChangeNotifier {
  IntakeController(this.database, this.profile, this.sound, this.notifications);
  final IntakeDatabase database;
  final ProfileController profile;
  final SoundService sound;
  final NotificationService notifications;
  List<IntakeEntry> entries = [];
  bool loading = true;
  Future<void> load() async { entries = await database.all(); loading = false; notifyListeners(); }
  List<IntakeEntry> get todayEntries {
    final today = DateTime.now();
    return entries.where((e) => e.timestamp.year == today.year && e.timestamp.month == today.month && e.timestamp.day == today.day).toList();
  }
  int get todayTotal => todayEntries.fold(0, (total, e) => total + e.effectiveMl);
  int get todayGoal => profile.profile?.goalMl() ?? 2500;
  List<String> get recentDrinkIds {
    final seen = <String>{};
    return [
      for (final entry in entries)
        if (seen.add(entry.drinkId)) entry.drinkId,
    ].take(4).toList();
  }
  double get progress => (todayTotal / todayGoal).clamp(0, 1);
  Future<void> add(String drinkId, int volumeMl) async {
    final drink = drinkById(drinkId, profile.customDrinks);
    final entry = IntakeEntry(drinkId: drinkId, volumeMl: volumeMl, effectiveMl: drink.effectiveMl(volumeMl), timestamp: DateTime.now(), goalMl: todayGoal);
    final id = await database.insert(entry);
    entries = [entry.copyWith(id: id), ...entries];
    if (profile.repository.reminders.splashEnabled) await sound.play('splash');
    final settings = profile.repository.reminders;
    await notifications.schedule(settings, pause: settings.pauseWhenGoalReached && todayTotal >= todayGoal);
    notifyListeners();
  }
  Future<void> remove(IntakeEntry entry) async { if (entry.id != null) await database.delete(entry.id!); entries.removeWhere((e) => e.id == entry.id); notifyListeners(); }
  int streak() {
    var result = 0;
    var date = DateTime.now();
    final grouped = <String, int>{};
    for (final e in entries) { final d = e.timestamp; final key = '${d.year}-${d.month}-${d.day}'; grouped[key] = (grouped[key] ?? 0) + e.effectiveMl; }
    while ((grouped['${date.year}-${date.month}-${date.day}'] ?? 0) >= todayGoal) { result++; date = date.subtract(const Duration(days: 1)); }
    return result;
  }
}

extension on IntakeEntry {
  IntakeEntry copyWith({int? id}) => IntakeEntry(id: id ?? this.id, drinkId: drinkId, volumeMl: volumeMl, effectiveMl: effectiveMl, timestamp: timestamp, goalMl: goalMl);
}

class ReminderController extends ChangeNotifier {
  ReminderController(this.repository, this.service);
  final PreferencesRepository repository;
  final NotificationService service;
  ReminderSettings settings = const ReminderSettings();
  Future<void> load() async { settings = repository.reminders; notifyListeners(); }
  Future<void> update(ReminderSettings value) async { settings = value; await repository.saveReminders(value); await service.schedule(value); notifyListeners(); }
  Future<void> requestPermissions() => service.requestPermissions();
}
