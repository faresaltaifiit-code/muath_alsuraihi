import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/player_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.surah});
  final SurahModel surah;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<PlayerProvider>();
      if (player.currentSurah?.audioPath != widget.surah.audioPath) {
        player.prepareSurah(widget.surah);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final surah = player.currentSurah ?? widget.surah;
    final duration = player.duration > Duration.zero
        ? player.duration
        : Duration(seconds: surah.durationSeconds);
    final position = player.position > duration ? duration : player.position;

    return Scaffold(
      appBar: AppBar(title: const Text('قيد التشغيل')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.forestGreen, AppColors.emerald],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: AppColors.softGold, size: 82),
              ),
              const SizedBox(height: 34),
              Text('سورة ${surah.name}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(surah.reciterName, style: Theme.of(context).textTheme.bodyLarge),
              if (player.error != null) ...[
                const SizedBox(height: 14),
                Text(player.error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const Spacer(),
              Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                onChanged: duration > Duration.zero
                    ? (value) => player.seek(Duration(milliseconds: value.round()))
                    : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_format(position), _format(duration)],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'تكرار',
                    iconSize: 27,
                    color: player.repeatMode == AudioServiceRepeatMode.none
                        ? null
                        : AppColors.gold,
                    onPressed: player.cycleRepeatMode,
                    icon: Icon(player.repeatMode == AudioServiceRepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded),
                  ),
                  IconButton(
                    tooltip: 'رجوع 15 ثانية',
                    iconSize: 32,
                    onPressed: () => player.skipBy(const Duration(seconds: -15)),
                    icon: const Icon(Icons.replay_10_rounded),
                  ),
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: AppColors.forestGreen,
                      ),
                      onPressed: player.isReady ? player.togglePlayPause : null,
                      child: Icon(player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 42),
                    ),
                  ),
                  IconButton(
                    tooltip: 'تقديم 15 ثانية',
                    iconSize: 32,
                    onPressed: () => player.skipBy(const Duration(seconds: 15)),
                    icon: const Icon(Icons.forward_10_rounded),
                  ),
                  IconButton(
                    tooltip: 'المفضلة',
                    iconSize: 27,
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseSpeed(context, player),
                      icon: const Icon(Icons.speed_rounded),
                      label: Text('السرعة ${player.speed}×'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseSleepTimer(context, player),
                      icon: Icon(player.hasSleepTimer
                          ? Icons.bedtime_rounded
                          : Icons.bedtime_outlined),
                      label: const Text('مؤقت النوم'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Share.share('استمع إلى سورة ${surah.name} بصوت ${surah.reciterName} عبر تطبيق معاذ السريحي'),
                icon: const Icon(Icons.share_outlined),
                label: const Text('مشاركة التلاوة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _format(Duration duration) => Text(
        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
      );

  Future<void> _chooseSpeed(BuildContext context, PlayerProvider player) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) => _OptionsSheet(
        title: 'سرعة القراءة',
        options: const [0.75, 1.0, 1.25, 1.5],
        label: (value) => '$value×',
      ),
    );
    if (result != null) await player.changeSpeed(result);
  }

  Future<void> _chooseSleepTimer(BuildContext context, PlayerProvider player) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _OptionsSheet(
        title: 'إيقاف التشغيل بعد',
        options: const [5, 10, 15, 30, 45, 60],
        label: (value) => '$value دقيقة',
      ),
    );
    if (result != null) player.setSleepTimer(Duration(minutes: result));
  }
}

class _OptionsSheet<T> extends StatelessWidget {
  const _OptionsSheet({required this.title, required this.options, required this.label});
  final String title;
  final List<T> options;
  final String Function(T value) label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...options.map((value) => ListTile(
                  title: Text(label(value)),
                  onTap: () => Navigator.pop(context, value),
                )),
          ],
        ),
      );
}

