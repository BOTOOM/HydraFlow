import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/ui/screens/history_screen.dart';

void main() {
  test('keeps the goal near the top when all days are below it', () {
    expect(historyChartMaximum([0, 800, 2400], 3000), closeTo(3450, .001));
  });

  test('expands the scale when a day exceeds the goal', () {
    expect(historyChartMaximum([2800, 3000, 4500], 3000), closeTo(4950, .001));
  });

  test('handles an invalid goal without dividing by zero', () {
    expect(historyChartMaximum([0], 0), closeTo(1.15, .001));
  });
}
