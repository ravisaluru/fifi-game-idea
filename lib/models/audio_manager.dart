import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();
  bool _muted = false;

  bool get isMuted => _muted;

  void toggleMute() {
    _muted = !_muted;
    _music.setVolume(_muted ? 0 : 0.5);
  }

  Future<void> playBgMusic(String assetPath) async {
    if (_muted) return;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(0.5);
    await _music.play(AssetSource(assetPath));
  }

  Future<void> playSfx(String assetPath) async {
    if (_muted) return;
    await _sfx.play(AssetSource(assetPath));
  }

  Future<void> stopMusic() => _music.stop();

  void dispose() {
    _music.dispose();
    _sfx.dispose();
  }
}
