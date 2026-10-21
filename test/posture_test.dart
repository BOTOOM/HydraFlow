import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/ui/posture.dart';

DisplayFeature _feature(
  Rect bounds, {
  DisplayFeatureType type = DisplayFeatureType.hinge,
  DisplayFeatureState state = DisplayFeatureState.postureFlat,
}) =>
    DisplayFeature(bounds: bounds, type: type, state: state);

void main() {
  group('postureOf', () {
    test('classifies a compact screen without a hinge as cover', () {
      expect(
        postureOf(const Size(360, 400), []).posture,
        HydraPosture.cover,
      );
    });

    test('classifies a wide screen without a hinge as tablet', () {
      expect(
        postureOf(const Size(900, 800), []).posture,
        HydraPosture.tablet,
      );
    });

    test('classifies other screens without a hinge as phone', () {
      expect(
        postureOf(const Size(412, 915), []).posture,
        HydraPosture.phone,
      );
    });

    test('classifies a flat vertical hinge as dual pane', () {
      final hinge = _feature(const Rect.fromLTRB(440, 0, 444, 1104));
      final result = postureOf(const Size(884, 1104), [hinge]);

      expect(result.posture, HydraPosture.dualPane);
      expect(result.hinge, hinge.bounds);
    });

    test('classifies a half-open vertical hinge as book', () {
      expect(
        postureOf(
          const Size(884, 1104),
          [
            _feature(
              const Rect.fromLTRB(440, 0, 444, 1104),
              state: DisplayFeatureState.postureHalfOpened,
            ),
          ],
        ).posture,
        HydraPosture.book,
      );
    });

    test('classifies a half-open horizontal hinge as tabletop', () {
      expect(
        postureOf(
          const Size(412, 915),
          [
            _feature(
              const Rect.fromLTRB(0, 440, 412, 460),
              state: DisplayFeatureState.postureHalfOpened,
            ),
          ],
        ).posture,
        HydraPosture.tabletop,
      );
    });

    test('classifies a flat horizontal hinge as phone', () {
      expect(
        postureOf(
          const Size(412, 915),
          [_feature(const Rect.fromLTRB(0, 440, 412, 460))],
        ).posture,
        HydraPosture.phone,
      );
    });

    test('ignores cutouts when choosing the first hinge', () {
      final cutout = _feature(
      const Rect.fromLTRB(0, 0, 80, 20),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
      );
      final hinge = _feature(
        const Rect.fromLTRB(440, 0, 444, 1104),
        state: DisplayFeatureState.postureHalfOpened,
      );
      final result = postureOf(const Size(884, 1104), [cutout, hinge]);

      expect(result.posture, HydraPosture.book);
      expect(result.hinge, hinge.bounds);
    });

    test('ignores a cutout when it is the only display feature', () {
      final cutout = _feature(
        const Rect.fromLTRB(0, 0, 80, 20),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      );

      expect(
        postureOf(const Size(360, 400), [cutout]).posture,
        HydraPosture.cover,
      );
    });
  });
}
