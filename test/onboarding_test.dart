import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/ui/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding pages lay out without errors on a small phone', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('Continuar'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'welcome page');

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Cuéntanos de ti'), findsOneWidget);
    expect(find.text('Peso (kg)'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'profile page');

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Pequeños recordatorios'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'reminders page');
  });
}
