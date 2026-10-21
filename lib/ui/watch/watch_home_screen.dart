import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_mood.dart';
import '../../domain/drink.dart';
import '../../domain/models.dart';
import '../../state/controllers.dart';
import '../../services/form_factor.dart';
import '../formatters.dart';
import '../theme.dart';
import '../widgets/droplet_avatar.dart';

class WatchHomeScreen extends StatefulWidget {
  const WatchHomeScreen({super.key, required this.shape});

  final WatchShape shape;

  @override
  State<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends State<WatchHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final intake = context.watch<IntakeController>();
    final profile = context.watch<ProfileController>();
    final reminders = context.watch<ReminderController>().settings;
    final entries = [...intake.todayEntries]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final avatar = avatarStateFor(
      totalMl: intake.todayTotal,
      goalMl: intake.todayGoal,
      now: DateTime.now(),
      wakeHour: reminders.wakeHour,
      wakeMinute: reminders.wakeMinute,
      sleepHour: reminders.sleepHour,
      sleepMinute: reminders.sleepMinute,
      lastDrinkAt: entries.isEmpty ? null : entries.first.timestamp,
    );
    final content = _homeContent(
      context,
      intake: intake,
      profile: profile,
      avatar: avatar,
      entries: entries,
    );
    final screenSize = MediaQuery.sizeOf(context);

    if (widget.shape == WatchShape.round) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * .12,
                  vertical: screenSize.height * .15,
                ),
                children: content,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('watch-ring'),
                  painter: _WatchProgressPainter(intake.progress),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: ClipRRect(
                key: const ValueKey('watch-bar'),
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: intake.progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(HydraTheme.aqua),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _homeContent(
    BuildContext context, {
    required IntakeController intake,
    required ProfileController profile,
    required AvatarState avatar,
    required List<IntakeEntry> entries,
  }) {
    final water = drinkById('water', profile.customDrinks);
    final latest = entries.isEmpty ? null : entries.first;
    return [
      Column(
        children: [
          DropletAvatar(
            state: avatar,
            size: 56,
            celebrations: intake.celebrations,
          ),
          Text(
            '${(intake.progress * 100).round()}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            formatVolumePair(intake.todayTotal, intake.todayGoal, profile.unit),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            avatar.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final size in water.sizes.take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _addWater(context, size),
              child: Text('Agua +$size ml'),
            ),
          ),
        ),
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () => _openDrinkList(context, profile),
          icon: const Icon(Icons.local_drink_outlined, size: 18),
          label: const Text('Otra bebida'),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Hoy',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      if (entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Aún no hay sorbos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
      for (final entry in entries.take(6))
        _WatchEntryTile(
          entry: entry,
          drink: drinkById(entry.drinkId, profile.customDrinks),
          unit: profile.unit,
        ),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: latest == null ? null : () => _undo(context, latest),
          child: const Text('Deshacer último'),
        ),
      ),
    ];
  }

  Future<void> _addWater(BuildContext context, int size) async {
    await context.read<IntakeController>().add('water', size);
    await HapticFeedback.lightImpact();
  }

  Future<void> _undo(BuildContext context, IntakeEntry entry) async {
    await context.read<IntakeController>().remove(entry);
    await HapticFeedback.lightImpact();
  }

  void _openDrinkList(BuildContext context, ProfileController profile) {
    final options = [
      ...drinks.where((drink) => drink.id != 'custom'),
      ...profile.customDrinks.map(
        (item) => drinkById(item.id, profile.customDrinks),
      ),
    ];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WatchDrinkListScreen(
          shape: widget.shape,
          drinks: options,
          unit: profile.unit,
        ),
      ),
    );
  }
}

class _WatchEntryTile extends StatelessWidget {
  const _WatchEntryTile({
    required this.entry,
    required this.drink,
    required this.unit,
  });

  final IntakeEntry entry;
  final Drink drink;
  final UnitPreference unit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(drink.icon, size: 16, color: HydraTheme.aqua),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${drink.name} · ${DateFormat('HH:mm').format(entry.timestamp)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Text(
              formatVolume(entry.effectiveMl, unit),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
}

class _WatchDrinkListScreen extends StatelessWidget {
  const _WatchDrinkListScreen({
    required this.shape,
    required this.drinks,
    required this.unit,
  });

  final WatchShape shape;
  final List<Drink> drinks;
  final UnitPreference unit;

  @override
  Widget build(BuildContext context) => _WatchSubpageFrame(
        shape: shape,
        title: 'Otra bebida',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final drink in drinks)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _WatchDrinkSizesScreen(
                          shape: shape,
                          drink: drink,
                          unit: unit,
                        ),
                      ),
                    ),
                    child: Text(
                      drink.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _WatchDrinkSizesScreen extends StatelessWidget {
  const _WatchDrinkSizesScreen({
    required this.shape,
    required this.drink,
    required this.unit,
  });

  final WatchShape shape;
  final Drink drink;
  final UnitPreference unit;

  @override
  Widget build(BuildContext context) => _WatchSubpageFrame(
        shape: shape,
        title: drink.name,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final size in drink.sizes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await context.read<IntakeController>().add(drink.id, size);
                      await HapticFeedback.lightImpact();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: Text('+${formatVolume(size, unit)}'),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _WatchSubpageFrame extends StatelessWidget {
  const _WatchSubpageFrame({
    required this.shape,
    required this.title,
    required this.child,
  });

  final WatchShape shape;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = shape == WatchShape.round
        ? EdgeInsets.fromLTRB(
            size.width * .12,
            size.height * .15,
            size.width * .12,
            size.height * .15,
          )
        : const EdgeInsets.all(8);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              SizedBox(
                height: 26,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 26,
                          height: 26,
                        ),
                        iconSize: 18,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchProgressPainter extends CustomPainter {
  const _WatchProgressPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 4,
    );
    final track = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final arc = Paint()
      ..color = HydraTheme.aqua
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _WatchProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
