import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';

class FoldSplit extends StatefulWidget {
  const FoldSplit({
    super.key,
    required this.first,
    required this.second,
    required this.fallback,
  });

  final Widget first;
  final Widget second;
  final Widget fallback;

  @override
  State<FoldSplit> createState() => _FoldSplitState();
}

class _FoldSplitState extends State<FoldSplit> {
  final _areaKey = GlobalKey();
  Offset _globalOrigin = Offset.zero;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _areaKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final origin = renderObject.localToGlobal(Offset.zero);
      if (origin != _globalOrigin) setState(() => _globalOrigin = origin);
    });

    return SizedBox.expand(
      key: _areaKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (!size.width.isFinite || !size.height.isFinite) {
            return widget.fallback;
          }
          final area = Offset.zero & size;
          final feature = MediaQuery.displayFeaturesOf(context)
              .where(
                (candidate) =>
                    candidate.type == DisplayFeatureType.fold &&
                    candidate.state == DisplayFeatureState.postureHalfOpened,
              )
              .firstWhereOrNull((candidate) {
                final bounds = candidate.bounds.shift(-_globalOrigin);
                return bounds.overlaps(area);
              });

          if (feature == null) return widget.fallback;

          final bounds = feature.bounds.shift(-_globalOrigin);
          if (bounds.width > bounds.height) {
            final foldTop = bounds.top.clamp(0.0, size.height).toDouble();
            final foldHeight = bounds.height
                .clamp(0.0, size.height - foldTop)
                .toDouble();
            return Column(
              children: [
                SizedBox(
                  height: foldTop,
                  width: double.infinity,
                  child: widget.first,
                ),
                SizedBox(height: foldHeight),
                Expanded(child: widget.second),
              ],
            );
          }
          final foldLeft = bounds.left.clamp(0.0, size.width).toDouble();
          final foldWidth = bounds.width
              .clamp(0.0, size.width - foldLeft)
              .toDouble();
          return Row(
            children: [
              SizedBox(
                width: foldLeft,
                height: double.infinity,
                child: widget.first,
              ),
              SizedBox(width: foldWidth),
              Expanded(child: widget.second),
            ],
          );
        },
      ),
    );
  }
}

extension on Iterable<DisplayFeature> {
  DisplayFeature? firstWhereOrNull(bool Function(DisplayFeature) test) {
    for (final feature in this) {
      if (test(feature)) return feature;
    }
    return null;
  }
}
