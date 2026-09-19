import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/surah_model.dart';
import 'audio_download_service.dart';

/// طبقة الصوت الأصلية: قائمة تشغيل محلية تعمل مع شاشة القفل والخلفية.
class MuathAudioHandler extends BaseAudioHandler with SeekHandler {
  MuathAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      if (_sequenceLoaded && index != null) {
        _activePlaylistIndex = index;
        _publishCurrentItem(index);
      }
    });
    _player.durationStream.listen(_publishMeasuredDuration);
    _player.processingStateStream.listen(_handleProcessingState);
  }

  final AudioPlayer _player = AudioPlayer();
  List<SurahModel> _playlist = const [];
  bool _autoPlayNext = true;
  bool _shuffleEnabled = false;
  bool _sequenceLoaded = false;
  int _activePlaylistIndex = 0;
  bool _isAutoAdvancing = false;

  Future<void> loadSurah(
    SurahModel surah, {
    required List<SurahModel> playlist,
    required bool autoPlayNext,
    required bool shuffleEnabled,
    bool autoplay = false,
    Duration? initialPosition,
  }) async {
    if (!surah.available || (!surah.isBundled && !_hasRemoteSource(surah))) {
      throw ArgumentError('هذه التلاوة غير متوفرة حاليًا.');
    }
    _playlist = playlist
        .where((item) => item.available)
        .map((item) => item.audioPath == surah.audioPath ? surah : item)
        .toList();
    if (!_playlist.any((item) => item.audioPath == surah.audioPath)) _playlist = [surah];
    final startIndex = _playlist.indexWhere((item) => item.audioPath == surah.audioPath);
    _activePlaylistIndex = startIndex < 0 ? 0 : startIndex;
    _autoPlayNext = autoPlayNext;
    _shuffleEnabled = shuffleEnabled;
    _sequenceLoaded = false;
    queue.add(_playlist.map(_mediaItem).toList());
    final source = await _audioSourceFor(surah);
    final duration = await _player.setAudioSource(
      source,
      initialPosition: initialPosition,
    );
    _publishCurrentItem(_activePlaylistIndex);
    if (duration != null && mediaItem.value != null) mediaItem.add(mediaItem.value!.copyWith(duration: duration));
    if (autoplay) unawaited(play());
  }

  bool _hasRemoteSource(SurahModel item) =>
      item.remoteAudioUrl != null && item.remoteAudioUrl!.isNotEmpty;

  Future<AudioSource> _audioSourceFor(SurahModel item) async {
    final tag = _mediaItem(item);
    final localDownload = await AudioDownloadService.localFileFor(item.id);
    if (localDownload != null) return AudioSource.file(localDownload.path, tag: tag);
    if (item.isBundled && item.audioPath.isNotEmpty) {
      return AudioSource.asset(item.audioPath, tag: tag);
    }
    if (_hasRemoteSource(item)) {
      return AudioSource.uri(Uri.parse(item.remoteAudioUrl!), tag: tag);
    }
    throw StateError('No bundled, downloaded, or remote source is available.');
  }

  Future<void> _selectSingleSurah(int index, {required bool autoplay}) async {
    if (index < 0 || index >= _playlist.length) return;
    _activePlaylistIndex = index;
    final duration = await _player.setAudioSource(
      await _audioSourceFor(_playlist[index]),
    );
    _publishCurrentItem(index);
    if (duration != null && mediaItem.value != null) {
      mediaItem.add(mediaItem.value!.copyWith(duration: duration));
    }
    if (autoplay) await play();
  }

  int _randomIndex() {
    if (_playlist.length < 2) return _activePlaylistIndex;
    var index = Random().nextInt(_playlist.length);
    while (index == _activePlaylistIndex) {
      index = Random().nextInt(_playlist.length);
    }
    return index;
  }

  void _handleProcessingState(ProcessingState state) {
    if (state != ProcessingState.completed ||
        !_autoPlayNext ||
        _isAutoAdvancing) {
      return;
    }
    final nextIndex = _shuffleEnabled
        ? _randomIndex()
        : _activePlaylistIndex + 1;
    if (nextIndex < 0 || nextIndex >= _playlist.length) return;
    unawaited(_advanceAutomatically(nextIndex));
  }

  Future<void> _advanceAutomatically(int index) async {
    _isAutoAdvancing = true;
    try {
      await _selectSingleSurah(index, autoplay: true);
    } finally {
      _isAutoAdvancing = false;
    }
  }

  MediaItem _mediaItem(SurahModel item) => MediaItem(id: item.audioPath, title: item.number > 0 ? 'سورة ${item.name}' : item.name, artist: item.reciterName, duration: item.durationSeconds > 0 ? Duration(seconds: item.durationSeconds) : null);
  void _publishCurrentItem(int? index) { if (index != null && index >= 0 && index < _playlist.length) mediaItem.add(_mediaItem(_playlist[index])); }
  void _publishMeasuredDuration(Duration? duration) { final current = mediaItem.value; if (duration != null && current != null) mediaItem.add(current.copyWith(duration: duration)); }
  @override Future<void> play() => _player.play();
  @override Future<void> pause() => _player.pause();
  @override Future<void> seek(Duration position) => _player.seek(position);
  @override Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  Future<void> setVolume(double value) => _player.setVolume(value);
  Future<void> setAutoPlayNext(bool enabled) async {
    _autoPlayNext = enabled;
    await _player.setLoopMode(LoopMode.off);
  }
  @override Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async { await _player.setLoopMode(switch (repeatMode) { AudioServiceRepeatMode.none => LoopMode.off, AudioServiceRepeatMode.one => LoopMode.one, AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all, }); }
  @override Future<void> skipToNext() async {
    if (_shuffleEnabled) {
      await _selectSingleSurah(_randomIndex(), autoplay: _player.playing);
      return;
    }
    if (_sequenceLoaded && _player.hasNext) await _player.seekToNext();
    if (!_sequenceLoaded && _activePlaylistIndex + 1 < _playlist.length) {
      await _selectSingleSurah(
        _activePlaylistIndex + 1,
        autoplay: _player.playing,
      );
    }
  }
  @override Future<void> skipToPrevious() async {
    if (_shuffleEnabled) {
      await _selectSingleSurah(_randomIndex(), autoplay: _player.playing);
      return;
    }
    if (_sequenceLoaded && _player.hasPrevious) await _player.seekToPrevious();
    if (!_sequenceLoaded && _activePlaylistIndex > 0) {
      await _selectSingleSurah(
        _activePlaylistIndex - 1,
        autoplay: _player.playing,
      );
    }
  }
  @override Future<void> rewind() => seek(_safeOffset(const Duration(seconds: -10)));
  @override Future<void> fastForward() => seek(_safeOffset(const Duration(seconds: 10)));
  Duration _safeOffset(Duration amount) { final value = _player.position + amount; if (value < Duration.zero) return Duration.zero; final duration = _player.duration; return duration != null && value > duration ? duration : value; }
  void _broadcastState(PlaybackEvent event) { final playing = _player.playing; playbackState.add(PlaybackState(controls: [MediaControl.skipToPrevious, if (playing) MediaControl.pause else MediaControl.play, MediaControl.skipToNext, MediaControl.stop], systemActions: const {MediaAction.seek, MediaAction.setSpeed}, androidCompactActionIndices: const [0, 1, 2], processingState: switch (_player.processingState) { ProcessingState.idle => AudioProcessingState.idle, ProcessingState.loading => AudioProcessingState.loading, ProcessingState.buffering => AudioProcessingState.buffering, ProcessingState.ready => AudioProcessingState.ready, ProcessingState.completed => AudioProcessingState.completed, }, playing: playing, updatePosition: _player.position, bufferedPosition: _player.bufferedPosition, speed: _player.speed, repeatMode: switch (_player.loopMode) { LoopMode.off => AudioServiceRepeatMode.none, LoopMode.one => AudioServiceRepeatMode.one, LoopMode.all => AudioServiceRepeatMode.all, }, queueIndex: _sequenceLoaded ? event.currentIndex : _activePlaylistIndex)); }
  @override Future<void> stop() async { await _player.stop(); return super.stop(); }
}
