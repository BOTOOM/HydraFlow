import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/data/intake_database.dart';
import 'package:hydraflow/data/preferences_repository.dart';
import 'package:hydraflow/domain/models.dart';
import 'package:hydraflow/services/notification_service.dart';
import 'package:hydraflow/services/sound_service.dart';
import 'package:hydraflow/state/controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('agrega effectiveMl del día', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesRepository(await SharedPreferences.getInstance());
    final profile = ProfileController(prefs);
    await profile.save(const UserProfile(sex: Sex.male, age: 30, weightKg: 80, activityLevel: ActivityLevel.moderate, climate: Climate.temperate));
    final controller = IntakeController(IntakeDatabase(), profile, SoundService(), NotificationService());
    controller.entries = [
      IntakeEntry(drinkId: 'water', volumeMl: 250, effectiveMl: 250, timestamp: DateTime.now(), goalMl: 3300),
      IntakeEntry(drinkId: 'milk', volumeMl: 250, effectiveMl: 225, timestamp: DateTime.now(), goalMl: 3300),
    ];
    expect(controller.todayTotal, 475);
  });
}
