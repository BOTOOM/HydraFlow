import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/data/intake_database.dart';
import 'package:hydraflow/data/preferences_repository.dart';
import 'package:hydraflow/domain/models.dart';
import 'package:hydraflow/services/form_factor.dart';
import 'package:hydraflow/services/notification_service.dart';
import 'package:hydraflow/services/sound_service.dart';
import 'package:hydraflow/state/controllers.dart';
import 'package:hydraflow/ui/theme.dart';
import 'package:hydraflow/ui/watch/watch_home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryIntakeDatabase extends IntakeDatabase {
  var _nextId = 0;

  @override
  Future<int> insert(IntakeEntry entry) async => ++_nextId;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<IntakeEntry>> all() async => [];
}

class _FakeSoundService extends SoundService {
  @override
  Future<void> play(String name) async {}

  @override
  Future<void> dispose() async {}
}

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> schedule(ReminderSettings settings, {bool pause = false}) async {}
}

Future<void> _mountWatch(
  WidgetTester tester,
  WatchShape shape,
) async {
  await initializeDateFormatting('es');
  tester.view.physicalSize = const Size(227, 227);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final preferences = PreferencesRepository(
    await SharedPreferences.getInstance(),
  );
  await preferences.saveReminders(
    const ReminderSettings(splashEnabled: false),
  );
  final notifications = _FakeNotificationService();
  final sounds = _FakeSoundService();
  final profile = ProfileController(preferences);
  final reminders = ReminderController(preferences, notifications);
  final intake = IntakeController(
    _MemoryIntakeDatabase(),
    profile,
    sounds,
    notifications,
  );
  await profile.load();
  await reminders.load();
  await intake.load();
  addTearDown(profile.dispose);
  addTearDown(reminders.dispose);
  addTearDown(intake.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>.value(value: profile),
        ChangeNotifierProvider<ReminderController>.value(value: reminders),
        ChangeNotifierProvider<IntakeController>.value(value: intake),
        Provider<SoundService>.value(value: sounds),
      ],
      child: MaterialApp(
        theme: HydraTheme.dark(),
        home: WatchHomeScreen(shape: shape),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  final target = find.text(text);
  for (var attempt = 0; attempt < 10 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pump();
  }
  await tester.ensureVisible(target);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final shape in WatchShape.values) {
    testWidgets('${shape.name} watch renders and adds/undoes water', (
      tester,
    ) async {
      await _mountWatch(tester, shape);

      if (shape == WatchShape.round) {
        expect(find.byKey(const ValueKey('watch-ring')), findsOneWidget);
        expect(find.byKey(const ValueKey('watch-bar')), findsNothing);
      } else {
        expect(find.byKey(const ValueKey('watch-bar')), findsOneWidget);
        expect(find.byKey(const ValueKey('watch-ring')), findsNothing);
      }
      expect(tester.takeException(), isNull);

      await _scrollToText(tester, 'Agua +150 ml');
      await tester.tap(find.text('Agua +150 ml'));
      await tester.pump();
      await tester.pump();
      await _scrollToTop(tester);
      expect(find.text('150 ml / 2500 ml'), findsOneWidget);

      await _scrollToText(tester, 'Deshacer último');
      await tester.tap(find.text('Deshacer último'));
      await tester.pump();
      await tester.pump();
      await _scrollToTop(tester);
      expect(find.text('0 ml / 2500 ml'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _scrollToTop(WidgetTester tester) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pump();
}
