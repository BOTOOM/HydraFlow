import 'dart:async';
import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _foldRegionsChannel = EventChannel('hydraflow/fold_regions');

List<DisplayFeature> displayFeaturesFromFoldEvent(Object? event) {
  if (event is! Map ||
      event['divisions'] is! List ||
      event['occlusions'] is! List) {
    return [];
  }

  final features = <DisplayFeature>[];
  for (final entry in event['divisions'] as List) {
    final bounds = _boundsFromEntry(entry);
    if (bounds == null) return [];
    features.add(
      DisplayFeature(
        bounds: bounds,
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    );
  }
  for (final entry in event['occlusions'] as List) {
    final bounds = _boundsFromEntry(entry);
    if (bounds == null) return [];
    features.add(
      DisplayFeature(
        bounds: bounds,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    );
  }
  return features;
}

Rect? _boundsFromEntry(Object? entry) {
  if (entry is! Map) return null;
  final values = [entry['x'], entry['y'], entry['width'], entry['height']];
  if (values.any((value) => value is! num || !value.isFinite)) return null;
  final numbers = values.cast<num>().map((value) => value.toDouble()).toList();
  return Rect.fromLTWH(numbers[0], numbers[1], numbers[2], numbers[3]);
}

class FoldRegions extends StatefulWidget {
  const FoldRegions({super.key, required this.child});
  final Widget child;

  @override
  State<FoldRegions> createState() => _FoldRegionsState();
}

class _FoldRegionsState extends State<FoldRegions> {
  List<DisplayFeature> _foldFeatures = const [];
  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _subscription = _foldRegionsChannel.receiveBroadcastStream().listen(
          _handleEvent,
          onError: (Object error) {
            if (error is! MissingPluginException && kDebugMode) {
              debugPrint('Fold region stream error: $error');
            }
          },
        );
      } on MissingPluginException {
        // Older iOS builds may not include the native plugin.
      }
    }
  }

  void _handleEvent(Object? event) {
    if (kDebugMode) debugPrint('Fold region event: $event');
    final features = displayFeaturesFromFoldEvent(event);
    if (!listEquals(features, _foldFeatures) && mounted) {
      setState(() => _foldFeatures = features);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        displayFeatures: [...mediaQuery.displayFeatures, ..._foldFeatures],
      ),
      child: widget.child,
    );
  }
}
