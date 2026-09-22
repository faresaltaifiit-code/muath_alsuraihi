import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/muath_audio_handler.dart';
import '../data/models/surah_model.dart';

class PlayerProvider extends ChangeNotifier {
  static const _lastPlaybackKey = 'last_playback';
  static const _recentPlaybackKey = 'recent_playback';
  static const _recentLimit = 10;
  AudioHandler? _handler;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _sleepTimer;
  Timer? _fadeTimer;
  Timer? _saveTimer;

  List<SurahModel> _playlist = const [];
  List<SurahModel> _catalogPlaylist = const [];
  bool _usesCustomPlaylist = false;
  SurahModel? _currentSurah;
  SurahModel? _lastSurah;
  List<ListeningHistoryEntry> _recentHistory = const [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _lastPosition = Duration.zero;
  bool _isPlaying = false;
  bool _hasPlaybackInSession = false;
  bool _isReady = false;
  bool _autoPlayNext = true;
  bool _shuffleEnabled = false;
  bool _sleepAtEnd = false;
  double _speed = 1;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  String? _error;

  SurahModel? get currentSurah => _currentSurah;
  SurahModel? get lastSurah => _lastSurah;
  /// Stored only on this device. Nothing in this list is sent anywhere.
  List<ListeningHistoryEntry> get recentHistory =>
      List.unmodifiable(_recentHistory);
  /// Compatibility view for existing callers that only need the surah models.
  List<SurahModel> get recentSurahs =>
      List.unmodifiable(_recentHistory.map((entry) => entry.surah));
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get lastPosition => _lastPosition;
  bool get isPlaying => _isPlaying;
  /// True only after the user starts or resumes playback in this app session.
  bool get hasPlaybackInSession => _hasPlaybackInSession;
  bool get isReady => _isReady;
  bool get autoPlayNext => _autoPlayNext;
  bool get shuffleEnabled => _shuffleEnabled;
  double get speed => _speed;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
  bool get hasSleepTimer => _sleepTimer?.isActive ?? false;
  bool get sleepAtEnd => _sleepAtEnd;
  String? get error => _error;
  List<SurahModel> get upcomingSurahs {
    final current = _currentSurah;
    if (current == null) return const [];
    final index = _playlist.indexWhere((item) => item.audioPath == current.audioPath);
    if (index < 0) return const [];
    if (_shuffleEnabled) {
      return _playlist.where((item) => item.audioPath != current.audioPath).toList();
    }
    return _playlist.skip(index + 1).toList();
  }

  Future<void> playFromQueue(SurahModel surah) =>
      prepareSurah(surah, autoplay: true, keepCurrentPlaylist: true);

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
    await _restoreRecentPlayback();
    notifyListeners();
  }

  void setPlaylist(List<SurahModel> value) {
    final available = value.where((item) => item.available).toList();
    final sameSources = listEquals(
      _catalogPlaylist.map((item) => item.remoteAudioUrl).toList(),
      available.map((item) => item.remoteAudioUrl).toList(),
    );
    final sameBundledState = listEquals(
      _catalogPlaylist.map((item) => item.isBundled).toList(),
      available.map((item) => item.isBundled).toList(),
    );
    if (sameSources && sameBundledState) {
      return;
    }
    _catalogPlaylist = available;
    if (!_usesCustomPlaylist) _playlist = available;
  }

  /// Starts an explicit user playlist, such as the Favorites collection.
  /// The audio handler receives this queue, so next/previous stay inside it.
  Future<void> playPlaylist(
    List<SurahModel> items, {
    SurahModel? initialSurah,
    bool shuffled = false,
  }) async {
    final available = items.where((item) => item.available).toList();
    if (available.isEmpty) return;
    _usesCustomPlaylist = true;
    _playlist = available;
    _shuffleEnabled = shuffled;
    final selected = initialSurah != null &&
            available.any((item) => item.audioPath == initialSurah.audioPath)
        ? initialSurah
        : (shuffled
            ? available[Random().nextInt(available.length)]
            : available.first);
    await prepareSurah(
      selected,
      autoplay: true,
      keepCurrentPlaylist: true,
    );
  }

  Future<void> prepareSurah(
    SurahModel surah, {
    bool autoplay = false,
    Duration? initialPosition,
    bool keepCurrentPlaylist = false,
  }) async {
    await initialize();
    if (!keepCurrentPlaylist) {
      _usesCustomPlaylist = false;
      if (_catalogPlaylist.isNotEmpty) _playlist = _catalogPlaylist;
    }
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
    notifyListeners();
    try {
      final sourceList = surah.number > 0 && _playlist.isNotEmpty
          ? _playlist
          : <SurahModel>[surah];
      await (_handler! as MuathAudioHandler).loadSurah(
        surah,
        playlist: sourceList,
        autoPlayNext: _autoPlayNext,
        shuffleEnabled: _shuffleEnabled,
        autoplay: autoplay,
        initialPosition: initialPosition,
      );
      _hasPlaybackInSession = true;
      _lastSurah = surah;
      _lastPosition = initialPosition ?? Duration.zero;
      await _savePlayback();
    } catch (_) {
      _error = surah.remoteAudioUrl?.isNotEmpty == true
          ? 'تعذر تشغيل البث. تأكد من اتصال الإنترنت ثم أعد المحاولة.'
          : 'تعذر تشغيل ملف التلاوة المحلي.';
      notifyListeners();
    }
  }

  Future<void> retryCurrent() async {
    final surah = _currentSurah;
    if (surah == null) return;
    await prepareSurah(surah, autoplay: true, keepCurrentPlaylist: true);
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
      AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
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

  Future<void> next() async {
    await (_handler?.skipToNext() ?? Future.value());
  }
  Future<void> previous() => _handler?.skipToPrevious() ?? Future.value();

  Future<void> setAutoPlayNext(bool value) async {
    if (_autoPlayNext == value) return;
    _autoPlayNext = value;
    notifyListeners();
    final current = _currentSurah;
    if (current != null) {
      await prepareSurah(
        current,
        autoplay: _isPlaying,
        initialPosition: _position,
        keepCurrentPlaylist: true,
      );
    }
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    notifyListeners();
    final current = _currentSurah;
    if (current != null) {
      await prepareSurah(
        current,
        autoplay: _isPlaying,
        initialPosition: _position,
        keepCurrentPlaylist: true,
      );
    }
  }

  void setSleepTimer(Duration duration, {bool fadeOut = true}) {
    _sleepTimer?.cancel();
    _sleepAtEnd = false;
    unawaited((_handler as MuathAudioHandler?)?.setStopAtEnd(false) ?? Future.value());
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
    _sleepAtEnd = false;
    unawaited((_handler as MuathAudioHandler?)?.setStopAtEnd(false) ?? Future.value());
    // A cancelled fade must not leave the next playback quiet.
    unawaited((_handler as MuathAudioHandler?)?.setVolume(1) ?? Future.value());
    notifyListeners();
  }

  void setSleepAtEnd() {
    _sleepTimer?.cancel();
    _sleepAtEnd = true;
    unawaited((_handler as MuathAudioHandler?)?.setStopAtEnd(true) ?? Future.value());
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
    _recordRecent(surah, _position);
    await preferences.setString(
      _recentPlaybackKey,
      jsonEncode(_recentHistory.map((entry) => entry.toJson()).toList()),
    );
    notifyListeners();
  }

  void _recordRecent(SurahModel surah, Duration position) {
    final entry = ListeningHistoryEntry(
      surah: surah,
      position: position,
      listenedAt: DateTime.now(),
    );
    _recentHistory = <ListeningHistoryEntry>[
      entry,
      ..._recentHistory.where((item) => item.surah.audioPath != surah.audioPath),
    ].take(_recentLimit).toList();
  }

  Future<void> _restoreRecentPlayback() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_recentPlaybackKey);
    if (value == null) return;
    try {
      final items = jsonDecode(value) as List<dynamic>;
      _recentHistory = items
          .whereType<Map<String, dynamic>>()
          .map((item) {
            if (item.containsKey('surah')) {
              return ListeningHistoryEntry.fromJson(item);
            }
            // Migrate the previous local-only list format without losing it.
            return ListeningHistoryEntry(
              surah: SurahModel.fromJson(item),
              position: Duration.zero,
              listenedAt: DateTime.fromMillisecondsSinceEpoch(0),
            );
          })
          .take(_recentLimit)
          .toList();
    } catch (_) {
      await preferences.remove(_recentPlaybackKey);
    }
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

@visibleForTesting
SurahModel? pickRandomSurah(
  List<SurahModel> playlist,
  SurahModel? current, {
  Random? random,
}) {
  if (playlist.isEmpty) return null;
  final candidates = playlist
      .where((surah) => surah.audioPath != current?.audioPath)
      .toList();
  final choices = candidates.isEmpty ? playlist : candidates;
  return choices[(random ?? Random()).nextInt(choices.length)];
}

@immutable
class ListeningHistoryEntry {
  const ListeningHistoryEntry({
    required this.surah,
    required this.position,
    required this.listenedAt,
  });

  final SurahModel surah;
  final Duration position;
  final DateTime listenedAt;

  Map<String, dynamic> toJson() => {
        'surah': surah.toJson(),
        'position_ms': position.inMilliseconds,
        'listened_at_ms': listenedAt.millisecondsSinceEpoch,
      };

  factory ListeningHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ListeningHistoryEntry(
        surah: SurahModel.fromJson(json['surah'] as Map<String, dynamic>),
        position: Duration(milliseconds: (json['position_ms'] as num?)?.toInt() ?? 0),
        listenedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['listened_at_ms'] as num?)?.toInt() ?? 0,
        ),
      );
}
