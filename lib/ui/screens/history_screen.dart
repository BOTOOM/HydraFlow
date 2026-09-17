import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/drink.dart';
import '../../domain/models.dart';
import '../../state/controllers.dart';
import '../formatters.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final intake = context.watch<IntakeController>();
    final profile = context.watch<ProfileController>();
    final days = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );
    final picked = selectedDay;
    final pickedEntries = picked == null
        ? <IntakeEntry>[]
        : intake.entries
              .where((entry) => _sameDay(entry.timestamp, picked))
              .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Mira cómo se mueve tu ola durante la semana.'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SizedBox(
                height: 250,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totals = days
                        .map((day) => _totalFor(intake.entries, day))
                        .toList();
                    final max = historyChartMaximum(totals, intake.todayGoal);
                    final goalFraction = intake.todayGoal / max;
                    const percentLabelHeight = 16.0;
                    const labelGap = 4.0;
                    const dayLabelHeight = 24.0;
                    final barAreaHeight =
                        constraints.maxHeight -
                        percentLabelHeight -
                        labelGap -
                        dayLabelHeight;
                    return Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(days.length, (index) {
                            final day = days[index];
                            final total = totals[index];
                            final barHeight = (total / max * barAreaHeight)
                                .clamp(4.0, barAreaHeight);
                            final selected =
                                selectedDay != null &&
                                _sameDay(selectedDay!, day);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => selectedDay = day),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: percentLabelHeight,
                                        child: Text(
                                          '${(total / intake.todayGoal * 100).round()}%',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(height: labelGap),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? HydraTheme.coral
                                              : HydraTheme.aqua,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        height: dayLabelHeight - 6,
                                        child: Text(
                                          DateFormat(
                                            'E',
                                            'es',
                                          ).format(day).substring(0, 2),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: dayLabelHeight + barAreaHeight * goalFraction,
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(color: HydraTheme.coral),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(color: HydraTheme.coral),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'meta',
                                  style: TextStyle(color: HydraTheme.coral, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (picked != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registros del ${DateFormat('d MMMM', 'es').format(picked)}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (pickedEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No hay registros ese día.'),
                      )
                    else
                      ...pickedEntries.map((entry) {
                        final drink = drinkById(
                          entry.drinkId,
                          profile.customDrinks,
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            drink.icon,
                            color: drink.color ?? HydraTheme.aqua,
                          ),
                          title: Text(drink.name),
                          subtitle: Text(
                            DateFormat('HH:mm').format(entry.timestamp),
                          ),
                          trailing: Text(
                            formatVolume(entry.effectiveMl, profile.unit),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          ...days.reversed.map((day) {
            final total = _totalFor(intake.entries, day);
            return ListTile(
              onTap: () => setState(() => selectedDay = day),
              title: Text(DateFormat('EEEE, d/M', 'es').format(day)),
              trailing: Text(
                '${formatVolume(total, profile.unit)} / ${formatVolume(intake.todayGoal, profile.unit)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  int _totalFor(List<IntakeEntry> entries, DateTime day) => entries
      .where((entry) => _sameDay(entry.timestamp, day))
      .fold(0, (sum, entry) => sum + entry.effectiveMl);
}

double historyChartMaximum(Iterable<int> totals, int goalMl) {
  final goal = math.max(goalMl, 1);
  final highest = totals.fold<int>(0, math.max);
  return math.max(goal * 1.15, highest * 1.1);
}
