import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/domain/avatar_mood.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) => DateTime(2026, 1, 10, hour, minute);

  test('morning greeting right after waking with nothing logged', () {
    final s = avatarStateFor(totalMl: 0, goalMl: 3000, now: at(7, 20));
    expect(s.mood, Mood.morning);
  });

  test('happy when on pace', () {
    final s = avatarStateFor(totalMl: 1500, goalMl: 3000, now: at(14, 30));
    expect(s.mood, Mood.happy);
    expect(s.vitality, greaterThan(.5));
  });

  test('thirsty then wilted as the day passes without drinking', () {
    expect(avatarStateFor(totalMl: 300, goalMl: 3000, now: at(12)).mood, Mood.thirsty);
    final late = avatarStateFor(totalMl: 300, goalMl: 3000, now: at(19));
    expect(late.mood, Mood.wilted);
    expect(late.vitality, lessThan(.2));
  });

  test('radiant once goal is reached, full vitality', () {
    final s = avatarStateFor(totalMl: 3100, goalMl: 3000, now: at(16));
    expect(s.mood, Mood.radiant);
    expect(s.vitality, 1);
  });

  test('night moods depend on how close to the goal', () {
    expect(avatarStateFor(totalMl: 2600, goalMl: 3000, now: at(23)).mood, Mood.nightHappy);
    expect(avatarStateFor(totalMl: 1000, goalMl: 3000, now: at(23)).mood, Mood.nightSleepy);
    expect(avatarStateFor(totalMl: 0, goalMl: 3000, now: at(3)).mood, Mood.nightSleepy);
  });

  test('a recent drink lifts the mood one step for a while', () {
    // 19:00 with wake 7 / sleep 22 → expected 0.8; 1000/2800 is well behind.
    final base = avatarStateFor(totalMl: 1000, goalMl: 2800, now: at(19));
    expect(base.mood, Mood.wilted);
    final fresh = avatarStateFor(
      totalMl: 1000, goalMl: 2800, now: at(19), lastDrinkAt: at(18, 55),
    );
    expect(fresh.mood, Mood.thirsty);
    final stale = avatarStateFor(
      totalMl: 1000, goalMl: 2800, now: at(19), lastDrinkAt: at(18, 20),
    );
    expect(stale.mood, Mood.wilted);
  });

  test('awake fraction handles bedtime after midnight', () {
    final f = awakeFraction(at(23, 30), wakeHour: 8, wakeMinute: 0, sleepHour: 1, sleepMinute: 0);
    expect(f, closeTo(15.5 / 17, .001));
    final early = awakeFraction(at(0, 30), wakeHour: 8, wakeMinute: 0, sleepHour: 1, sleepMinute: 0);
    expect(early, closeTo(16.5 / 17, .001));
  });
}
