import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  Future<void> play(String name) => _player.play(AssetSource('sounds/$name.ogg'));
  Future<void> dispose() => _player.dispose();
}
