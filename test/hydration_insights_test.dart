import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/domain/hydration_insights.dart';
import 'package:hydraflow/domain/models.dart';

IntakeEntry entry(DateTime at, int ml) => IntakeEntry(
  drinkId: 'water',
  volumeMl: ml,
  effectiveMl: ml,
  timestamp: at,
  goalMl: 3000,
);

void main() {
  final now = DateTime(2026, 9, 17, 15);

  test('no insights for a normal day', () {
    final entries = [
      entry(now.subtract(const Duration(minutes: 30)), 300),
      entry(now.subtract(const Duration(hours: 3)), 500),
    ];
    expect(
      hydrationInsightsFor(entries: entries, goalMl: 3000, now: now),
      isEmpty,
    );
  });

  test('caution when more than 1 L in the last hour, urgent above 1.4 L', () {
    final caution = [
      entry(now.subtract(const Duration(minutes: 10)), 600),
      entry(now.subtract(const Duration(minutes: 50)), 500),
    ];
    final c = hydrationInsightsFor(entries: caution, goalMl: 3000, now: now);
    expect(c.single.kind, InsightKind.fastIntake);
    expect(c.single.level, InsightLevel.caution);

    final urgent = [
      ...caution,
      entry(now.subtract(const Duration(minutes: 20)), 400),
    ];
    final u = hydrationInsightsFor(entries: urgent, goalMl: 3000, now: now);
    expect(u.single.level, InsightLevel.urgent);
  });

  test('entries older than an hour do not count as fast intake', () {
    final entries = [entry(now.subtract(const Duration(minutes: 61)), 1200)];
    expect(
      hydrationInsightsFor(entries: entries, goalMl: 3000, now: now),
      isEmpty,
    );
  });

  test('over-goal caution at 150 % of the goal, not at 120 %', () {
    final fine = [
      entry(now.subtract(const Duration(hours: 5)), 1800),
      entry(now.subtract(const Duration(hours: 2)), 1800),
    ];
    expect(
      hydrationInsightsFor(entries: fine, goalMl: 3000, now: now),
      isEmpty,
    );
    final over = [...fine, entry(now.subtract(const Duration(hours: 3)), 900)];
    final i = hydrationInsightsFor(entries: over, goalMl: 3000, now: now);
    expect(i.single.kind, InsightKind.overGoal);
    expect(i.single.body, contains('150 %'));
  });

  test('low streak: info at 3 days, caution at 5, today does not count', () {
    List<IntakeEntry> lowDays(int n) => [
      for (var d = 1; d <= n; d++) entry(now.subtract(Duration(days: d)), 1000),
    ];
    expect(
      hydrationInsightsFor(entries: lowDays(2), goalMl: 3000, now: now),
      isEmpty,
    );
    final three = hydrationInsightsFor(
      entries: [
        ...lowDays(3),
        entry(now.subtract(const Duration(days: 4)), 2000),
      ],
      goalMl: 3000,
      now: now,
    );
    expect(three.single.kind, InsightKind.lowStreak);
    expect(three.single.level, InsightLevel.info);
    final five = hydrationInsightsFor(
      entries: [
        ...lowDays(5),
        entry(now.subtract(const Duration(days: 6)), 2000),
      ],
      goalMl: 3000,
      now: now,
    );
    expect(five.single.level, InsightLevel.caution);
    expect(five.single.title, contains('5 días'));
  });

  test('days before the first log never count as low', () {
    final entries = [
      entry(now.subtract(const Duration(days: 2)), 400),
      entry(now.subtract(const Duration(days: 1)), 400),
    ];
    expect(
      hydrationInsightsFor(entries: entries, goalMl: 3000, now: now),
      isEmpty,
    );
    expect(hydrationInsightsFor(entries: [], goalMl: 3000, now: now), isEmpty);
  });

  test('a good day breaks the low streak', () {
    final entries = [
      entry(now.subtract(const Duration(days: 1)), 500),
      entry(now.subtract(const Duration(days: 2)), 2500),
      entry(now.subtract(const Duration(days: 3)), 500),
      entry(now.subtract(const Duration(days: 4)), 500),
    ];
    expect(
      hydrationInsightsFor(entries: entries, goalMl: 3000, now: now),
      isEmpty,
    );
  });
}
