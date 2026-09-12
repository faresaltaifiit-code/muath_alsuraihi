import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../features/player/presentation/player_screen.dart';
import '../providers/player_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final surah = player.currentSurah;
    if (surah == null) return const SizedBox.shrink();
    final duration = player.duration;
    final progress = duration > Duration.zero
        ? (player.position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: surah)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                color: AppColors.gold,
                backgroundColor: Colors.transparent,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 7, 8, 7),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          color: AppColors.softGold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah.number > 0 ? 'سورة ${surah.name}' : surah.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(surah.reciterName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'السابق',
                      onPressed: player.previous,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton.filledTonal(
                      tooltip: player.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                      onPressed: player.togglePlayPause,
                      icon: Icon(player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                    ),
                    IconButton(
                      tooltip: 'التالي',
                      onPressed: player.next,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
