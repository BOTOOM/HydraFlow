import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_mood.dart';
import '../../state/controllers.dart';
import '../formatters.dart';
import '../widgets/droplet_avatar.dart';

class CoverHomeScreen extends StatelessWidget {
  const CoverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final intake = context.watch<IntakeController>();
    final profile = context.watch<ProfileController>();
    final reminders = context.watch<ReminderController>().settings;
    final avatar = avatarStateFor(
      totalMl: intake.todayTotal,
      goalMl: intake.todayGoal,
      now: DateTime.now(),
      wakeHour: reminders.wakeHour,
      wakeMinute: reminders.wakeMinute,
      sleepHour: reminders.sleepHour,
      sleepMinute: reminders.sleepMinute,
      lastDrinkAt: intake.entries.isEmpty
          ? null
          : intake.entries
              .map((entry) => entry.timestamp)
              .reduce((a, b) => a.isAfter(b) ? a : b),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropletAvatar(
              state: avatar,
              size: 72,
              celebrations: intake.celebrations,
            ),
            const SizedBox(height: 4),
            Text(
              '${(intake.progress * 100).round()}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              '${formatVolume(intake.todayTotal, profile.unit)} / '
              '${formatVolume(intake.todayGoal, profile.unit)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => intake.add('water', 250),
                    child: const Text('+250 ml'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => intake.add('water', 500),
                    child: const Text('+500 ml'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
