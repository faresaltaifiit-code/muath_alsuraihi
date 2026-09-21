import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/surah_model.dart';
import '../constants/app_strings.dart';
import 'audio_download_service.dart';

/// طبقة الصوت الأصلية: قائمة تشغيل محلية تعمل مع شاشة القفل والخلفية.
class MuathAudioHandler extends BaseAudioHandler with SeekHandler {
  MuathAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    // playbackEventStream alone is not guaranteed to emit a regular position
    // update on every iOS playback route. Relay just_audio's position stream
    // so the UI, persistence, and ±10-second controls always use fresh time.
    _player.positionStream.listen((_) => _broadcastState(_player.playbackEvent));
    _player.durationStream.listen(_publishMeasuredDuration);
    _player.processingStateStream.listen(_handleProcessingState);
  }

  final AudioPlayer _player = AudioPlayer();
  List<SurahModel> _playlist = const [];
  bool _autoPlayNext = true;
  bool _shuffleEnabled = false;
  bool _stopAtEnd = false;
  int _activePlaylistIndex = 0;
  bool _isAutoAdvancing = false;
  Uri? _artworkUri;

  Future<void> loadSurah(
    SurahModel surah, {
    required List<SurahModel> playlist,
    required bool autoPlayNext,
    required bool shuffleEnabled,
    bool autoplay = false,
    Duration? initialPosition,
  }) async {
    final hasLocalDownload =
        await AudioDownloadService.localFileFor(surah.id) != null;
    if (!surah.available ||
        (!surah.isBundled && !hasLocalDownload && !_hasRemoteSource(surah))) {
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
    await _ensureArtworkUri();
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
    final item = _playlist[index];
    final source = await _audioSourceFor(item);
    final duration = await _player.setAudioSource(source);
    // Do not change the active item until the replacement source is ready.
    // This keeps the player controls on the current surah if a remote source
    // cannot be reached or a downloaded file is invalid.
    _activePlaylistIndex = index;
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
    if (state != ProcessingState.completed || _isAutoAdvancing) {
      return;
    }
    if (_stopAtEnd) {
      _stopAtEnd = false;
      unawaited(_player.pause());
      return;
    }
    if (!_autoPlayNext) {
      unawaited(_player.pause());
      return;
    }
    final candidates = _automaticCandidates();
    if (candidates.isEmpty) return;
    unawaited(_advanceAutomatically(candidates));
  }

  List<int> _automaticCandidates() {
    if (_shuffleEnabled) {
      final candidates = List<int>.generate(_playlist.length, (index) => index)
        ..remove(_activePlaylistIndex)
        ..shuffle();
      return candidates;
    }

    return List<int>.generate(
      _playlist.length - _activePlaylistIndex - 1,
      (offset) => _activePlaylistIndex + offset + 1,
    );
  }

  Future<void> _advanceAutomatically(List<int> candidates) async {
    _isAutoAdvancing = true;
    try {
      for (final index in candidates) {
        try {
          await _selectSingleSurah(index, autoplay: true);
          return;
        } catch (_) {
          // A stream can fail temporarily in the background. Try the next
          // available item instead of leaving automatic playback stuck.
        }
      }
      await _player.pause();
    } catch (_) {
      // A failed replacement must leave playback stopped rather than retrying
      // forever in the background.
      await _player.pause();
    } finally {
      _isAutoAdvancing = false;
    }
  }

  Future<void> _ensureArtworkUri() async {
    if (_artworkUri != null) return;
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}carplay-artwork.png');
      if (!await file.exists()) {
        final data = await rootBundle.load('assets/images/carplay-artwork.png');
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      _artworkUri = file.uri;
    } catch (_) {
      // Artwork is optional metadata, so playback stays available if copying fails.
    }
  }

  MediaItem _mediaItem(SurahModel item) => MediaItem(
        id: item.audioPath,
        title: 'سورة ${item.name}',
        artist: AppStrings.reciterName,
        album: 'قرآن وتلاوات',
        artUri: _artworkUri,
        duration: item.durationSeconds > 0 ? Duration(seconds: item.durationSeconds) : null,
      );
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
  Future<void> setStopAtEnd(bool enabled) async => _stopAtEnd = enabled;
  @override Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async { await _player.setLoopMode(repeatMode == AudioServiceRepeatMode.one ? LoopMode.one : LoopMode.off); }
  @override Future<void> skipToNext() async {
    if (_shuffleEnabled) {
      await _selectSingleSurah(_randomIndex(), autoplay: _player.playing);
      return;
    }
    if (_activePlaylistIndex + 1 < _playlist.length) {
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
    if (_activePlaylistIndex > 0) {
      await _selectSingleSurah(
        _activePlaylistIndex - 1,
        autoplay: _player.playing,
      );
    }
  }
  @override Future<void> rewind() => seek(_safeOffset(const Duration(seconds: -10)));
  @override Future<void> fastForward() => seek(_safeOffset(const Duration(seconds: 10)));
  Duration _safeOffset(Duration amount) { final value = _player.position + amount; if (value < Duration.zero) return Duration.zero; final duration = _player.duration; return duration != null && value > duration ? duration : value; }
  void _broadcastState(PlaybackEvent event) { final playing = _player.playing; playbackState.add(PlaybackState(controls: [MediaControl.skipToPrevious, if (playing) MediaControl.pause else MediaControl.play, MediaControl.skipToNext, MediaControl.stop], systemActions: const {MediaAction.seek, MediaAction.setSpeed}, androidCompactActionIndices: const [0, 1, 2], processingState: switch (_player.processingState) { ProcessingState.idle => AudioProcessingState.idle, ProcessingState.loading => AudioProcessingState.loading, ProcessingState.buffering => AudioProcessingState.buffering, ProcessingState.ready => AudioProcessingState.ready, ProcessingState.completed => AudioProcessingState.completed, }, playing: playing, updatePosition: _player.position, bufferedPosition: _player.bufferedPosition, speed: _player.speed, repeatMode: _player.loopMode == LoopMode.one ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none, queueIndex: _activePlaylistIndex)); }
  @override Future<void> stop() async { await _player.stop(); return super.stop(); }
}
