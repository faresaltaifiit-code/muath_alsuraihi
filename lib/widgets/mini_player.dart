import 'dart:ui';

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
    if (surah == null || !player.hasPlaybackInSession) {
      return const SizedBox.shrink();
    }
    final duration = player.duration;
    final progress = duration > Duration.zero
        ? (player.position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final surface = Theme.of(context).colorScheme.surface.withValues(alpha: .88);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: surface,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: surah)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.forestGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.multitrack_audio_rounded, color: AppColors.softGold, size: 20),
                      ),
                      const SizedBox(width: 10),
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
                            Text(
                              surah.reciterName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: player.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                        onPressed: player.togglePlayPause,
                        icon: Icon(player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                      IconButton(
                        tooltip: 'التالي',
                        onPressed: player.next,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
