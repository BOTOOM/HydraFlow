import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  Future<void> play(String name) async {
    final extension = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? 'caf' : 'ogg';
    try {
      await _player.play(AssetSource('sounds/$name.$extension'));
    } catch (error) {
      if (kDebugMode) debugPrint('HydraFlow: no se pudo reproducir el sonido "$name": $error');
    }
  }
  Future<void> dispose() => _player.dispose();
}
