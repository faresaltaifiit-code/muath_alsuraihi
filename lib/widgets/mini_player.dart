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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.emerald, AppColors.forestGreen]),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: AppColors.softGold, size: 22),
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 19,
                                  ),
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
                      IconButton(
                        tooltip: player.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                        onPressed: player.togglePlayPause,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(42, 42),
                        ),
                        icon: Icon(player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                    ],
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: AppColors.goldAccent,
                    backgroundColor: theme.dividerColor,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
