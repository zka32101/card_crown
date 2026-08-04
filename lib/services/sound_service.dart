import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// ゲーム全体のサウンド管理シングルトン
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool _enabled = true;
  double _volume = 0.8;

  final _sfxPool = <String, AudioPlayer>{};

  bool get enabled => _enabled;
  double get volume => _volume;

  void setEnabled(bool v) {
    _enabled = v;
    if (!v) stopAll();
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    for (final p in _sfxPool.values) {
      p.setVolume(_volume);
    }
  }

  Future<void> play(SoundEffect se) async {
    if (!_enabled) return;
    try {
      final player = _getOrCreate(se.name);
      await player.stop();
      await player.setVolume(_volume);
      await player.play(AssetSource('sounds/${se.file}'));
    } catch (e) {
      debugPrint('[SoundService] play ${se.name} failed: $e');
    }
  }

  void stopAll() {
    for (final p in _sfxPool.values) {
      p.stop();
    }
  }

  void dispose() {
    for (final p in _sfxPool.values) {
      p.dispose();
    }
    _sfxPool.clear();
  }

  AudioPlayer _getOrCreate(String key) {
    return _sfxPool.putIfAbsent(key, AudioPlayer.new);
  }
}

/// サウンド効果一覧
enum SoundEffect {
  tap('tap', 'tap.wav'),
  coin('coin', 'coin.wav'),
  victory('victory', 'victory.wav'),
  defeat('defeat', 'defeat.wav'),
  hit('hit', 'hit.wav'),
  cardFlip('cardFlip', 'card_flip.wav'),
  dailyBonus('dailyBonus', 'daily_bonus.wav');

  final String name;
  final String file;
  const SoundEffect(this.name, this.file);
}

/// 便利なショートカット関数
void playSound(SoundEffect se) => SoundService.instance.play(se);
