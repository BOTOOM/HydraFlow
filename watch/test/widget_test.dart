import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydraflow_watch/main.dart';

void main() {
  testWidgets('Watch app shows progress and quick-add buttons',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HydraFlowWatchApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('0%'), findsOneWidget);
    expect(find.textContaining('/ 2810 ml'), findsOneWidget);
    expect(find.textContaining('Agua +150'), findsOneWidget);
  });
}
