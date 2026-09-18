import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  // AVFoundation (iOS/macOS) cannot decode Ogg Vorbis, so Apple platforms use AAC.
  static String get _extension => !kIsWeb && (Platform.isIOS || Platform.isMacOS) ? 'm4a' : 'ogg';

  Future<void> play(String name) async {
    try {
      await _player.play(AssetSource('sounds/$name.$_extension'));
    } on Exception catch (e) {
      debugPrint('HydraFlow: no se pudo reproducir $name: $e');
    }
  }

  Future<void> dispose() => _player.dispose();
}
