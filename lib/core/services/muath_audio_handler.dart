import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/surah_model.dart';

class MuathAudioHandler extends BaseAudioHandler with SeekHandler {
  MuathAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> loadSurah(SurahModel surah, {bool autoplay = false}) async {
    if (!surah.available || surah.audioPath.isEmpty) {
      throw ArgumentError('هذه التلاوة غير متوفرة حاليًا.');
    }
    final item = MediaItem(
      id: surah.audioPath,
      title: 'سورة ${surah.name}',
      artist: surah.reciterName,
      duration: surah.durationSeconds > 0
          ? Duration(seconds: surah.durationSeconds)
          : null,
    );
    mediaItem.add(item);
    final detectedDuration =
        await _player.setAudioSource(AudioSource.asset(surah.audioPath));
    if (detectedDuration != null) {
      mediaItem.add(item.copyWith(duration: detectedDuration));
    }
    if (autoplay) await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all,
    });
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek, MediaAction.setSpeed},
      androidCompactActionIndices: const [0, 1, 2],
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

