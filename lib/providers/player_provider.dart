import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/muath_audio_handler.dart';
import '../data/models/surah_model.dart';

class PlayerProvider extends ChangeNotifier {
  static const _lastPlaybackKey = 'last_playback';
  AudioHandler? _handler;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _sleepTimer;
  Timer? _fadeTimer;
  Timer? _saveTimer;

  List<SurahModel> _playlist = const [];
  SurahModel? _currentSurah;
  SurahModel? _lastSurah;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _lastPosition = Duration.zero;
  Duration? _repeatStart;
  Duration? _repeatEnd;
  bool _isPlaying = false;
  bool _isReady = false;
  bool _autoPlayNext = true;
  double _speed = 1;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  String? _error;

  SurahModel? get currentSurah => _currentSurah;
  SurahModel? get lastSurah => _lastSurah;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get lastPosition => _lastPosition;
  bool get isPlaying => _isPlaying;
  bool get isReady => _isReady;
  bool get autoPlayNext => _autoPlayNext;
  double get speed => _speed;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
  bool get hasSleepTimer => _sleepTimer?.isActive ?? false;
  bool get hasRepeatRange => _repeatStart != null && _repeatEnd != null;
  Duration? get repeatStart => _repeatStart;
  Duration? get repeatEnd => _repeatEnd;
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
      _loopRangeIfNeeded();
      _scheduleSave();
      notifyListeners();
    });
    _mediaItemSubscription = _handler!.mediaItem.listen((item) {
      if (item == null) return;
      _duration = item.duration ?? _duration;
      final active = _playlist.where((surah) => surah.audioPath == item.id);
      if (active.isNotEmpty) _currentSurah = active.first;
      notifyListeners();
    });
    _isReady = true;
    await _restoreLastPlayback();
    notifyListeners();
  }

  void setPlaylist(List<SurahModel> value) {
    final available = value.where((item) => item.available).toList();
    if (listEquals(_playlist.map((item) => item.audioPath).toList(),
        available.map((item) => item.audioPath).toList())) {
      return;
    }
    _playlist = available;
  }

  Future<void> prepareSurah(
    SurahModel surah, {
    bool autoplay = false,
    Duration? initialPosition,
  }) async {
    await initialize();
    _error = null;
    if (!surah.available) {
      _error = 'تلاوة سورة ${surah.name} غير متوفرة حاليًا.';
      notifyListeners();
      return;
    }
    _currentSurah = surah;
    _position = Duration.zero;
    _duration = surah.durationSeconds > 0
        ? Duration(seconds: surah.durationSeconds)
        : Duration.zero;
    _repeatStart = null;
    _repeatEnd = null;
    notifyListeners();
    try {
      final sourceList = _autoPlayNext && surah.number > 0 && _playlist.isNotEmpty
          ? _playlist
          : <SurahModel>[surah];
      await (_handler! as MuathAudioHandler).loadSurah(
        surah,
        playlist: sourceList,
        autoplay: autoplay,
        initialPosition: initialPosition,
      );
      _lastSurah = surah;
      _lastPosition = initialPosition ?? Duration.zero;
      await _savePlayback();
    } catch (_) {
      _error = 'تعذر تشغيل ملف التلاوة المحلي.';
      notifyListeners();
    }
  }

  Future<void> resumeLast() async {
    final surah = _lastSurah;
    if (surah == null) return;
    await prepareSurah(surah, autoplay: true, initialPosition: _lastPosition);
  }

  Future<void> togglePlayPause() async {
    if (_handler == null || _currentSurah == null) return;
    _isPlaying ? await _handler!.pause() : await _handler!.play();
  }

  Future<void> seek(Duration value) async {
    await (_handler?.seek(value) ?? Future.value());
    _position = value;
    _scheduleSave();
    notifyListeners();
  }

  Future<void> changeSpeed(double value) =>
      _handler?.setSpeed(value) ?? Future.value();

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

  Future<void> next() => _handler?.skipToNext() ?? Future.value();
  Future<void> previous() => _handler?.skipToPrevious() ?? Future.value();

  void setAutoPlayNext(bool value) {
    _autoPlayNext = value;
    notifyListeners();
  }

  void setRepeatStart() {
    _repeatStart = _position;
    if (_repeatEnd != null && _repeatEnd! <= _repeatStart!) _repeatEnd = null;
    notifyListeners();
  }

  void setRepeatEnd() {
    if (_repeatStart == null || _position <= _repeatStart!) return;
    _repeatEnd = _position;
    notifyListeners();
  }

  void clearRepeatRange() {
    _repeatStart = null;
    _repeatEnd = null;
    notifyListeners();
  }

  void _loopRangeIfNeeded() {
    if (_repeatStart != null && _repeatEnd != null && _position >= _repeatEnd!) {
      _handler?.seek(_repeatStart!);
    }
  }

  void setSleepTimer(Duration duration, {bool fadeOut = true}) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () async {
      if (fadeOut) {
        await _fadeAndPause();
      } else {
        await _handler?.pause();
      }
      _sleepTimer = null;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _fadeAndPause() async {
    _fadeTimer?.cancel();
    var step = 10;
    final completer = Completer<void>();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      final volume = step / 10;
      await (_handler as MuathAudioHandler?)?.setVolume(volume);
      step--;
      if (step < 0) {
        timer.cancel();
        await _handler?.pause();
        await (_handler as MuathAudioHandler?)?.setVolume(1);
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    _sleepTimer = null;
    notifyListeners();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), _savePlayback);
  }

  Future<void> _savePlayback() async {
    final surah = _currentSurah;
    if (surah == null) return;
    _lastSurah = surah;
    _lastPosition = _position;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _lastPlaybackKey,
      jsonEncode({
        'surah': surah.toJson(),
        'position_ms': _position.inMilliseconds,
      }),
    );
  }

  Future<void> _restoreLastPlayback() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_lastPlaybackKey);
    if (value == null) return;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      _lastSurah = SurahModel.fromJson(json['surah'] as Map<String, dynamic>);
      _lastPosition = Duration(milliseconds: (json['position_ms'] as num?)?.toInt() ?? 0);
    } catch (_) {
      await preferences.remove(_lastPlaybackKey);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    _saveTimer?.cancel();
    _playbackSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }
}
