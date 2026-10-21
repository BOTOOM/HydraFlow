import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/app.dart';
import 'package:hydraflow/data/intake_database.dart';
import 'package:hydraflow/data/preferences_repository.dart';
import 'package:hydraflow/domain/models.dart';
import 'package:hydraflow/services/notification_service.dart';
import 'package:hydraflow/services/sound_service.dart';
import 'package:hydraflow/state/controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

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

Future<void> _mountShell(
  WidgetTester tester, {
  required Size size,
  required List<DisplayFeature> features,
}) async {
  await initializeDateFormatting('es');
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.displayFeatures = features;
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
      child: const MaterialApp(home: Shell()),
    ),
  );
  await tester.pump();
}

DisplayFeature _hinge(Rect bounds, DisplayFeatureState state) => DisplayFeature(
      bounds: bounds,
      type: DisplayFeatureType.hinge,
      state: state,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone keeps bottom navigation and has no posture chip', (
    tester,
  ) async {
    await _mountShell(
      tester,
      size: const Size(412, 915),
      features: const [],
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Abierto · dos paneles'), findsNothing);
    expect(find.text('Modo libro'), findsNothing);
    expect(find.text('Modo mesa'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flat book fold aligns both panes with the hinge', (
    tester,
  ) async {
    await _mountShell(
      tester,
      size: const Size(884, 1104),
      features: [
        _hinge(
          const Rect.fromLTRB(440, 0, 444, 1104),
          DisplayFeatureState.postureFlat,
        ),
      ],
    );

    expect(find.text('Abierto · dos paneles'), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey('pane-left'))).right, 440);
    expect(tester.getRect(find.byKey(const ValueKey('pane-right'))).left, 444);
    expect(tester.takeException(), isNull);
  });

  testWidgets('half-open vertical fold shows book mode', (tester) async {
    await _mountShell(
      tester,
      size: const Size(884, 1104),
      features: [
        _hinge(
          const Rect.fromLTRB(440, 0, 444, 1104),
          DisplayFeatureState.postureHalfOpened,
        ),
      ],
    );

    expect(find.text('Modo libro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('half-open horizontal fold separates tabletop viewer/controls', (
    tester,
  ) async {
    await _mountShell(
      tester,
      size: const Size(412, 915),
      features: [
        _hinge(
          const Rect.fromLTRB(0, 440, 412, 460),
          DisplayFeatureState.postureHalfOpened,
        ),
      ],
    );

    expect(find.text('Modo mesa'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('tabletop-viewer'))).bottom,
      lessThanOrEqualTo(440),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('tabletop-controls'))).top,
      greaterThanOrEqualTo(460),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact cover adds 250 ml without navigation', (tester) async {
    await _mountShell(
      tester,
      size: const Size(360, 400),
      features: const [],
    );

    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('+250 ml'));
    await tester.pump();
    await tester.pump();

    expect(find.text('250 ml / 2500 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
