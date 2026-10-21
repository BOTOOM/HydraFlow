import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/ui/widgets/fold_split.dart';

void main() {
  Future<void> pumpSplit(
    WidgetTester tester, {
    required List<DisplayFeature> features,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            displayFeatures: features,
          ),
          child: const FoldSplit(
            first: ColoredBox(key: ValueKey('first'), color: Colors.red),
            second: ColoredBox(key: ValueKey('second'), color: Colors.blue),
            fallback: ColoredBox(
              key: ValueKey('fallback'),
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('splits above and below a horizontal fold', (tester) async {
    await pumpSplit(
      tester,
      features: [
        const DisplayFeature(
          bounds: Rect.fromLTWH(0, 390, 400, 20),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ],
    );

    expect(tester.getRect(find.byKey(const ValueKey('first'))).height, 390);
    expect(tester.getRect(find.byKey(const ValueKey('first'))).top, 0);
    expect(tester.getRect(find.byKey(const ValueKey('second'))).top, 410);
  });

  testWidgets('splits to the left and right of a vertical fold', (
    tester,
  ) async {
    await pumpSplit(
      tester,
      features: [
        const DisplayFeature(
          bounds: Rect.fromLTWH(190, 0, 20, 800),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ],
    );

    expect(tester.getRect(find.byKey(const ValueKey('first'))).width, 190);
    expect(tester.getRect(find.byKey(const ValueKey('second'))).left, 210);
  });

  testWidgets('uses the fallback when no fold is present', (tester) async {
    await pumpSplit(tester, features: []);

    expect(find.byKey(const ValueKey('fallback')), findsOneWidget);
    expect(find.byKey(const ValueKey('first')), findsNothing);
    expect(find.byKey(const ValueKey('second')), findsNothing);
  });
}
