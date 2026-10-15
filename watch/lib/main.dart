import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_watchos/flutter_watchos.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydraflow/domain/avatar_mood.dart';
import 'package:hydraflow/domain/drink.dart';
import 'package:hydraflow/domain/models.dart';
import 'package:hydraflow/ui/widgets/droplet_avatar.dart';

void main() => runApp(const HydraFlowWatchApp());

class HydraFlowWatchApp extends StatelessWidget {
  const HydraFlowWatchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HydraFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF17A2C7),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const WatchHome(),
      );
}

/// Demo profile used to compute the daily goal on the watch. The phone app
/// keeps the real profile; here we demo with a reasonable default.
const _demoProfile = UserProfile(
  sex: Sex.other,
  age: 30,
  weightKg: 70,
  activityLevel: ActivityLevel.moderate,
  climate: Climate.temperate,
);

class WatchHome extends StatefulWidget {
  const WatchHome({super.key});

  @override
  State<WatchHome> createState() => _WatchHomeState();
}

class _WatchHomeState extends State<WatchHome> {
  static const _prefsKey = 'watch_entries_v1';
  static const _prefsDayKey = 'watch_entries_day';

  final List<IntakeEntry> _entries = [];
  int _celebrations = 0;
  late final int _goalMl = _demoProfile.goalMl();
  bool _loaded = false;

  int get _totalMl =>
      _entries.fold(0, (sum, e) => sum + e.effectiveMl);

  AvatarState get _avatar => avatarStateFor(
        totalMl: _totalMl,
        goalMl: _goalMl,
        now: DateTime.now(),
        wakeHour: 7,
        sleepHour: 22,
        lastDrinkAt: _entries.isEmpty ? null : _entries.last.timestamp,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    if (prefs.getString(_prefsDayKey) != today) {
      await prefs.setString(_prefsDayKey, today);
      await prefs.remove(_prefsKey);
    }
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      for (final item in jsonDecode(raw) as List) {
        _entries.add(IntakeEntry.fromMap(item as Map<String, dynamic>));
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_entries.map((e) => e.toMap()).toList()),
    );
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _addDrink(Drink drink, int volumeMl) {
    final entry = IntakeEntry(
      drinkId: drink.id,
      volumeMl: volumeMl,
      effectiveMl: drink.effectiveMl(volumeMl),
      timestamp: DateTime.now(),
      goalMl: _goalMl,
    );
    setState(() {
      _entries.add(entry);
      _celebrations++;
    });
    _save();
    WatchHaptics.play(WatchHapticType.success);
    if (_avatar.ratio >= 1) {
      WatchHaptics.play(WatchHapticType.notification);
    }
  }

  void _removeLast() {
    if (_entries.isEmpty) return;
    setState(() => _entries.removeLast());
    _save();
    WatchHaptics.play(WatchHapticType.click);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final avatar = _avatar;
    final percent = (avatar.ratio * 100).clamp(0, 999).round();
    final water = drinkById('water');

    return Scaffold(
      body: WatchCrownScroll(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          children: [
            const SizedBox(height: 8),
            Center(
              child: DropletAvatar(
                state: avatar,
                size: 64,
                celebrations: _celebrations,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7BE7F4),
                ),
              ),
            ),
            Center(
              child: Text(
                '$_totalMl / $_goalMl ml',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  avatar.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final size in water.sizes.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FilledButton.icon(
                  onPressed: () => _addDrink(water, size),
                  icon: const Icon(Icons.water_drop_outlined, size: 16),
                  label: Text('Agua +$size ml'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DrinkPicker(onAdd: _addDrink)),
              ),
              icon: const Icon(Icons.local_drink_outlined, size: 16),
              label: const Text('Otra bebida'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
              ),
            ),
            if (_entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Hoy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              for (final e in _entries.reversed.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        drinkById(e.drinkId).icon,
                        size: 14,
                        color: const Color(0xFF7BE7F4),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${drinkById(e.drinkId).name} ${e.volumeMl} ml',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _removeLast,
                icon: const Icon(Icons.undo, size: 14),
                label: const Text('Deshacer último'),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class DrinkPicker extends StatelessWidget {
  const DrinkPicker({super.key, required this.onAdd});

  final void Function(Drink drink, int volumeMl) onAdd;

  @override
  Widget build(BuildContext context) {
    final list = drinks.where((d) => d.id != 'custom').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Bebida'), titleSpacing: 0),
      body: WatchCrownScroll(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final drink = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(drink.icon, size: 18),
                title: Text(drink.name, style: const TextStyle(fontSize: 13)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SizePicker(drink: drink, onAdd: onAdd),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SizePicker extends StatelessWidget {
  const SizePicker({super.key, required this.drink, required this.onAdd});

  final Drink drink;
  final void Function(Drink drink, int volumeMl) onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drink.name), titleSpacing: 0),
      body: WatchCrownScroll(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          children: [
            for (final size in drink.sizes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FilledButton(
                  onPressed: () {
                    onAdd(drink, size);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: Text('+$size ml'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
