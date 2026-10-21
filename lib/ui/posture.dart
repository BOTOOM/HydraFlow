import 'dart:ui';

enum HydraPosture { phone, cover, tablet, dualPane, book, tabletop }

class PostureInfo {
  const PostureInfo({required this.posture, this.hinge});

  final HydraPosture posture;
  final Rect? hinge;
}

PostureInfo postureOf(Size size, List<DisplayFeature> features) {
  DisplayFeature? hinge;
  for (final feature in features) {
    if (feature.type != DisplayFeatureType.cutout) {
      hinge = feature;
      break;
    }
  }

  if (hinge != null) {
    final bounds = hinge.bounds;
    final horizontal = bounds.width > bounds.height;
    if (hinge.state == DisplayFeatureState.postureHalfOpened) {
      return PostureInfo(
        posture: horizontal ? HydraPosture.tabletop : HydraPosture.book,
        hinge: bounds,
      );
    }
    if (!horizontal) {
      return PostureInfo(posture: HydraPosture.dualPane, hinge: bounds);
    }
    return PostureInfo(posture: HydraPosture.phone, hinge: bounds);
  }

  if (size.longestSide < 640) {
    return const PostureInfo(posture: HydraPosture.cover);
  }
  if (size.width >= 720) {
    return const PostureInfo(posture: HydraPosture.tablet);
  }
  return const PostureInfo(posture: HydraPosture.phone);
}
