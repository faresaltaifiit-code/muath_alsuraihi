import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/muath_audio_handler.dart';
import '../data/models/surah_model.dart';

class PlayerProvider extends ChangeNotifier {
  static const _lastSurahKey = 'last_played_surah';
  AudioHandler? _handler;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _sleepTimer;

  SurahModel? _currentSurah;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isReady = false;
  double _speed = 1;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  String? _error;

  SurahModel? get currentSurah => _currentSurah;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isReady => _isReady;
  double get speed => _speed;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
  bool get hasSleepTimer => _sleepTimer?.isActive ?? false;
  String? get error => _error;

  Future<void> initialize() async {
    if (_handler != null) return;
    final audioSession = await AudioSession.instance;
    await audioSession.configure(AudioSessionConfiguration.music());
    _handler = await AudioService.init(
      builder: MuathAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'muath_alsuraihi_audio',
        androidNotificationChannelName: 'تلاوات معاذ السريحي',
        androidStopForegroundOnPause: true,
      ),
    );
    _playbackSubscription = _handler!.playbackState.listen((state) {
      _position = state.updatePosition;
      _isPlaying = state.playing;
      _speed = state.speed;
      _repeatMode = state.repeatMode;
      notifyListeners();
    });
    _mediaItemSubscription = _handler!.mediaItem.listen((item) {
      _duration = item?.duration ?? _duration;
      notifyListeners();
    });
    _isReady = true;
    await _restoreLastSurah();
    notifyListeners();
  }

  Future<void> prepareSurah(SurahModel surah, {bool autoplay = false}) async {
    await initialize();
    _error = null;
    if (!surah.available) {
      _error = 'تلاوة سورة ${surah.name} غير متوفرة حاليًا.';
      notifyListeners();
      return;
    }
    _currentSurah = surah;
    _position = Duration.zero;
    _duration = Duration.zero;
    _duration = surah.durationSeconds > 0
        ? Duration(seconds: surah.durationSeconds)
        : Duration.zero;
    notifyListeners();
    try {
      await (_handler! as MuathAudioHandler).loadSurah(surah, autoplay: autoplay);
      await _saveLastSurah(surah);
    } catch (_) {
      _error = 'تعذر تشغيل ملف التلاوة المحلي.';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_handler == null || _currentSurah == null) return;
    _isPlaying ? await _handler!.pause() : await _handler!.play();
  }

  Future<void> seek(Duration value) => _handler?.seek(value) ?? Future.value();
  Future<void> changeSpeed(double value) => _handler?.setSpeed(value) ?? Future.value();

  Future<void> cycleRepeatMode() async {
    final next = switch (_repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.one => AudioServiceRepeatMode.all,
      _ => AudioServiceRepeatMode.none,
    };
    await _handler?.setRepeatMode(next);
  }

  Future<void> skipBy(Duration amount) async {
    final target = _position + amount;
    final safeTarget = target < Duration.zero
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration ? _duration : target);
    await seek(safeTarget);
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      _handler?.pause();
      _sleepTimer = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    notifyListeners();
  }

  Future<void> _saveLastSurah(SurahModel surah) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastSurahKey, jsonEncode(surah.toJson()));
  }

  Future<void> _restoreLastSurah() async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_lastSurahKey);
    if (json == null) return;
    try {
      _currentSurah = SurahModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      await preferences.remove(_lastSurahKey);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _playbackSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }
}

