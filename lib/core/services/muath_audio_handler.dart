import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/surah_model.dart';

/// طبقة الصوت الأصلية: قائمة تشغيل محلية تعمل مع شاشة القفل والخلفية.
class MuathAudioHandler extends BaseAudioHandler with SeekHandler {
  MuathAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen(_publishCurrentItem);
  }

  final AudioPlayer _player = AudioPlayer();
  List<SurahModel> _playlist = const [];

  Future<void> loadSurah(
    SurahModel surah, {
    required List<SurahModel> playlist,
    bool autoplay = false,
    Duration? initialPosition,
  }) async {
    if (!surah.available || surah.audioPath.isEmpty) {
      throw ArgumentError('هذه التلاوة غير متوفرة حاليًا.');
    }

    _playlist = playlist.where((item) => item.available).toList();
    if (!_playlist.any((item) => item.audioPath == surah.audioPath)) {
      _playlist = [surah];
    }
    final startIndex = _playlist.indexWhere((item) => item.audioPath == surah.audioPath);
    final sources = _playlist
        .map((item) => AudioSource.asset(item.audioPath, tag: _mediaItem(item)))
        .toList();
    final duration = await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex < 0 ? 0 : startIndex,
      initialPosition: initialPosition,
    );
    _publishCurrentItem(_player.currentIndex);
    if (duration != null && mediaItem.value != null) {
      mediaItem.add(mediaItem.value!.copyWith(duration: duration));
    }
    if (autoplay) await play();
  }

  MediaItem _mediaItem(SurahModel item) => MediaItem(
        id: item.audioPath,
        title: item.number > 0 ? 'سورة ${item.name}' : item.name,
        artist: item.reciterName,
        duration: item.durationSeconds > 0
            ? Duration(seconds: item.durationSeconds)
            : null,
      );

  void _publishCurrentItem(int? index) {
    if (index == null || index < 0 || index >= _playlist.length) return;
    mediaItem.add(_mediaItem(_playlist[index]));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setVolume(double value) => _player.setVolume(value);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all,
    });
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  @override
  Future<void> rewind() => seek(_safeOffset(const Duration(seconds: -15)));

  @override
  Future<void> fastForward() => seek(_safeOffset(const Duration(seconds: 15)));

  Duration _safeOffset(Duration amount) {
    final value = _player.position + amount;
    if (value < Duration.zero) return Duration.zero;
    final duration = _player.duration;
    return duration != null && value > duration ? duration : value;
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek, MediaAction.setSpeed},
      androidCompactActionIndices: const [1, 2, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      repeatMode: switch (_player.loopMode) {
        LoopMode.off => AudioServiceRepeatMode.none,
        LoopMode.one => AudioServiceRepeatMode.one,
        LoopMode.all => AudioServiceRepeatMode.all,
      },
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }
}
