import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ishi/core/managers/prefs_manager.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // --- PLAYERS ---
  final AudioPlayer _bgmPlayer = AudioPlayer();
  String? currentMusic;

  /// Dedicated Instances (for `allowOverlap = false`)\
  /// Key: filename -> Value: AudioPlayer.
  final Map<String, AudioPlayer> _dedicatedSfxPlayers = {};

  /// Polyphonic Pool (for `allowOverlap = true`)\
  /// A fixed array of players to prevent infinite instantiation.
  final List<AudioPlayer> _sfxPool = [];
  int _poolIndex = 0;

  // --- VOLUME STATES (0.0 to 1.0) ---
  double masterVolume = 1.0;
  double musicVolume = 1.0;
  double sfxVolume = 1.0;

  bool isMuted = false;

  /// Initializes the BGM release mode and pre-warms the SFX pool.
  Future<void> init({int poolSize = 5}) async {
    await _bgmPlayer.setReleaseMode(.loop);

    // Pre-warm the overlapping pool so there is no delay on first play
    for (int i = 0; i < poolSize; i++) {
      _sfxPool.add(AudioPlayer()..setReleaseMode(.stop));
    }

    masterVolume = await PrefsManager.getDouble(.masterVolume) ?? 1.0;
    musicVolume = await PrefsManager.getDouble(.musicVolume) ?? 1.0;
    sfxVolume = await PrefsManager.getDouble(.sfxVolume) ?? 1.0;

    _updateActiveVolumes();
  }

  // --- VOLUME MATH ---

  /// Applies a logarithmic curve to the volume so it sounds natural to human ears
  double _getRealVolume(double categoryVolume) {
    if (isMuted) return 0.0;
    double linearVolume = masterVolume * categoryVolume;
    return (linearVolume * linearVolume).toDouble();
  }

  // --- LIVE VOLUME SETTERS ---

  void setMasterVolume(double value) {
    masterVolume = value.clamp(0.0, 1.0);
    PrefsManager.setDouble(.masterVolume, masterVolume);
    _updateActiveVolumes();
  }

  void setMusicVolume(double value) {
    musicVolume = value.clamp(0.0, 1.0);
    PrefsManager.setDouble(.musicVolume, musicVolume);
    _bgmPlayer.setVolume(_getRealVolume(musicVolume));
  }

  void setSfxVolume(double value) {
    sfxVolume = value.clamp(0.0, 1.0);
    PrefsManager.setDouble(.sfxVolume, sfxVolume);
    if (_sfxPool.isEmpty) return;
    for (AudioPlayer audioPlayer in _sfxPool) {
      audioPlayer.setVolume(sfxVolume);
    }
  }

  /// Toggles global mute state.
  Future<void> toggleMute() async {
    isMuted = !isMuted;
    await _updateActiveVolumes();
  }

  /// Instantly applies volume changes to the looping background music.
  Future<void> _updateActiveVolumes() async {
    _bgmPlayer.setVolume(_getRealVolume(musicVolume));

    if (_sfxPool.isEmpty) return;
    for (AudioPlayer audioPlayer in _sfxPool) {
      await audioPlayer.stop();
    }
  }

  // --- PLAYBACK METHODS ---

  /// Plays a looping background track.
  Future<void> playMusic(String filename) async {
    if (currentMusic == filename) return;
    currentMusic = filename;

    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(_getRealVolume(musicVolume));
      await _bgmPlayer.play(AssetSource('audio/music/$filename'));
    } catch (e) {
      currentMusic = null;
      debugPrint("Music PLayback Error: $e");
    }
  }

  /// Stops the background music.
  Future<void> stopMusic() async {
    await _bgmPlayer.stop();
    currentMusic = null;
  }

  /// Plays a sound effect with instancing memory management.\
  /// Set [allowOverlap] to true if you want rapid-fire sounds to stack.
  Future<void> playSFX(String filename, {bool allowOverlap = false}) async {
    if (isMuted || _getRealVolume(sfxVolume) == 0.0) return;

    final source = AssetSource('audio/sfx/$filename');
    final actualVolume = _getRealVolume(sfxVolume);

    if (!allowOverlap) {
      // DEDICATED INSTANCING
      // Fetch the dedicated player for this exact file, or create it if missing
      if (!_dedicatedSfxPlayers.containsKey(filename)) {
        _dedicatedSfxPlayers[filename] = AudioPlayer()..setReleaseMode(.stop);
      }

      final player = _dedicatedSfxPlayers[filename]!;

      await player.setVolume(actualVolume);
      await player.stop();
      await player.play(source);
    } else {
      // ROUND-ROBIN POOLING
      // Grab the next available player in the polyphony array
      final player = _sfxPool[_poolIndex];

      await player.setVolume(actualVolume);
      await player.stop();
      await player.play(source);

      // Cycle the index (e.g., 0, 1, 2, 3, 4, 0, 1...)
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;
    }
  }

  /// Dispose of all players when the app closes.
  void dispose() {
    _bgmPlayer.dispose();
    for (AudioPlayer audioPlayer in _dedicatedSfxPlayers.values) {
      audioPlayer.dispose();
    }
    for (AudioPlayer audioPlayer in _sfxPool) {
      audioPlayer.dispose();
    }
  }
}
