import 'dart:ui' show DisplayFeatureState, DisplayFeatureType, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:hydraflow/services/fold_regions.dart';

void main() {
  test('parses a horizontal division with its exact bounds', () {
    final features = displayFeaturesFromFoldEvent({
      'divisions': [
        {'x': 0, 'y': 390, 'width': 400, 'height': 20},
      ],
      'occlusions': [],
    });

    expect(features, hasLength(1));
    expect(features.single.bounds, const Rect.fromLTWH(0, 390, 400, 20));
    expect(features.single.type, DisplayFeatureType.fold);
    expect(features.single.state, DisplayFeatureState.postureHalfOpened);
  });

  test('parses occlusions as cutouts', () {
    final features = displayFeaturesFromFoldEvent({
      'divisions': [],
      'occlusions': [
        {'x': 3, 'y': 4, 'width': 5, 'height': 6},
      ],
    });

    expect(features, hasLength(1));
    expect(features.single.bounds, const Rect.fromLTWH(3, 4, 5, 6));
    expect(features.single.type, DisplayFeatureType.cutout);
    expect(features.single.state, DisplayFeatureState.unknown);
  });

  test('returns no features for malformed events', () {
    expect(displayFeaturesFromFoldEvent(null), isEmpty);
    expect(displayFeaturesFromFoldEvent({'divisions': []}), isEmpty);
    expect(
      displayFeaturesFromFoldEvent({'divisions': 'wrong', 'occlusions': []}),
      isEmpty,
    );
    expect(
      displayFeaturesFromFoldEvent({
        'divisions': [
          {'x': 0, 'y': 'wrong', 'width': 400, 'height': 20},
        ],
        'occlusions': [],
      }),
      isEmpty,
    );
  });
}
