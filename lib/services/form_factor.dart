import 'dart:io';

import 'package:flutter/services.dart';

enum WatchShape { round, square }

const _deviceChannel = MethodChannel('hydraflow/device');

Future<WatchShape?> detectWatchShape() async {
  if (!Platform.isAndroid) return null;
  try {
    final result = await _deviceChannel.invokeMapMethod<String, Object?>(
      'formFactor',
    );
    if (result?['isWatch'] != true) return null;
    return result?['isRound'] == true ? WatchShape.round : WatchShape.square;
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
