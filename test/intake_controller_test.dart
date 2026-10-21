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

  test('agrega y notifica aunque falle el sonido', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesRepository(await SharedPreferences.getInstance());
    final profile = ProfileController(prefs);
    await profile.save(const UserProfile(sex: Sex.male, age: 30, weightKg: 80, activityLevel: ActivityLevel.moderate, climate: Climate.temperate));
    final sound = _ThrowingSoundService();
    final controller = IntakeController(_FakeIntakeDatabase(), profile, sound, _NoopNotificationService());
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.add('water', 250);

    expect(sound.calls, 1);
    expect(controller.entries, hasLength(1));
    expect(controller.entries.single.id, 1);
    expect(controller.todayTotal, 250);
    expect(notifications, 1);
  });
}

class _FakeIntakeDatabase extends IntakeDatabase {
  @override
  Future<int> insert(IntakeEntry entry) async => 1;
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> schedule(ReminderSettings settings, {bool pause = false}) async {}
}

class _ThrowingSoundService extends SoundService {
  int calls = 0;

  @override
  Future<void> play(String name) async {
    calls++;
    throw StateError('Audio unavailable');
  }
}
