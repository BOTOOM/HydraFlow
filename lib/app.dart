import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/intake_database.dart';
import 'data/preferences_repository.dart';
import 'services/form_factor.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'state/controllers.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/cover_home_screen.dart';
import 'ui/posture.dart';
import 'ui/watch/watch_home_screen.dart';
import 'ui/theme.dart';
import 'domain/models.dart';

class HydraFlowApp extends StatefulWidget {
  const HydraFlowApp({
    super.key,
    required this.preferences,
    this.watchShape,
  });
  final PreferencesRepository preferences;
  final WatchShape? watchShape;
  @override State<HydraFlowApp> createState() => _HydraFlowAppState();
}
class _HydraFlowAppState extends State<HydraFlowApp> {
  late final NotificationService notifications;
  late final SoundService sounds;
  late final ProfileController profile;
  late final ReminderController reminders;
  late final IntakeController intake;
  bool ready = false;
  @override void initState() {
    super.initState();
    notifications = NotificationService();
    sounds = SoundService();
    profile = ProfileController(widget.preferences);
    reminders = ReminderController(widget.preferences, notifications);
    intake = IntakeController(IntakeDatabase(), profile, sounds, notifications);
    _load();
  }
  Future<void> _load() async {
    await notifications.init();
    await profile.load();
    await reminders.load();
    await intake.load();
    if (mounted) setState(() => ready = true);
  }
  @override void dispose() { sounds.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (!ready) return MaterialApp(theme: widget.watchShape == null ? HydraTheme.light() : HydraTheme.dark(), home: const Scaffold(body: Center(child: CircularProgressIndicator())));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider.value(value: reminders),
        ChangeNotifierProvider.value(value: intake),
        Provider.value(value: sounds),
      ],
      child: widget.watchShape == null
          ? Consumer<ProfileController>(builder: (context, state, child) => MaterialApp(
              title: 'HydraFlow', debugShowCheckedModeBanner: false,
              theme: HydraTheme.light(), darkTheme: HydraTheme.dark(),
              themeMode: state.theme == ThemePreference.system ? ThemeMode.system : state.theme == ThemePreference.dark ? ThemeMode.dark : ThemeMode.light,
              home: state.complete ? const Shell() : const OnboardingScreen(),
            ))
          : MaterialApp(
              title: 'HydraFlow',
              debugShowCheckedModeBanner: false,
              theme: HydraTheme.dark(),
              home: WatchHomeScreen(shape: widget.watchShape!),
            ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int selected = 0;
  @override Widget build(BuildContext context) {
    final posture = postureOf(
      MediaQuery.sizeOf(context),
      MediaQuery.displayFeaturesOf(context),
    );
    if (posture.posture == HydraPosture.cover) {
      return const Scaffold(body: SafeArea(child: CoverHomeScreen()));
    }

    final foldLayout = switch (posture.posture) {
      HydraPosture.dualPane ||
      HydraPosture.book ||
      HydraPosture.tabletop => true,
      _ => false,
    };
    final tablet = posture.posture == HydraPosture.tablet;
    final screens = [
      HomeScreen(postureInfo: posture),
      foldLayout ? const SafeArea(child: HistoryScreen()) : const HistoryScreen(),
      foldLayout ? const SafeArea(child: SettingsScreen()) : const SettingsScreen(),
    ];
    final content = IndexedStack(index: selected, children: screens);
    return Scaffold(
      body: foldLayout
          ? content
          : SafeArea(
              child: tablet
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: selected,
                          onDestinationSelected: (i) =>
                              setState(() => selected = i),
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.waves_outlined),
                              selectedIcon: Icon(Icons.waves),
                              label: Text('Hoy'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.bar_chart_outlined),
                              selectedIcon: Icon(Icons.bar_chart),
                              label: Text('Historial'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.tune_outlined),
                              selectedIcon: Icon(Icons.tune),
                              label: Text('Ajustes'),
                            ),
                          ],
                        ),
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
      bottomNavigationBar: tablet
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.waves_outlined),
                  selectedIcon: Icon(Icons.waves),
                  label: 'Hoy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Historial',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Ajustes',
                ),
              ],
            ),
    );
  }
}
