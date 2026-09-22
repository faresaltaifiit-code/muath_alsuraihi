import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surah_model.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/player_provider.dart';
import '../../player/presentation/player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;
    final downloads = context.watch<DownloadsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: favorites.isEmpty
          ? const Center(child: Text('لم تضف تلاوات إلى المفضلة بعد'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  '${favorites.length} تلاوات محفوظة',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _playPlaylist(context, favorites),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('تشغيل الكل'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _playPlaylist(
                          context,
                          favorites,
                          shuffled: true,
                        ),
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('عشوائي'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final surah in favorites)
                  _FavoriteListTile(
                    surah: surah,
                    downloaded:
                        surah.isBundled || downloads.isDownloaded(surah),
                    onPlay: () => _playPlaylist(
                      context,
                      favorites,
                      initialSurah: surah,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _playPlaylist(
    BuildContext context,
    List<SurahModel> favorites, {
    SurahModel? initialSurah,
    bool shuffled = false,
  }) async {
    final available = favorites.where((item) => item.available).toList();
    if (available.isEmpty) return;
    await context.read<PlayerProvider>().playPlaylist(
          available,
          initialSurah: initialSurah,
          shuffled: shuffled,
        );
    if (!context.mounted) return;
    final current = context.read<PlayerProvider>().currentSurah ?? available.first;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: current)),
    );
  }
}

class _FavoriteListTile extends StatelessWidget {
  const _FavoriteListTile({
    required this.surah,
    required this.downloaded,
    required this.onPlay,
  });

  final SurahModel surah;
  final bool downloaded;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text(surah.number > 0 ? 'سورة ${surah.name}' : surah.name),
          subtitle: Text(
            surah.available
                ? (downloaded ? 'محملة · ${surah.durationText}' : surah.durationText)
                : 'غير متوفرة حاليًا',
          ),
          leading: CircleAvatar(
            child: Text(surah.number > 0 ? '${surah.number}' : '★'),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (downloaded)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 6),
                  child: Icon(Icons.download_done_rounded),
                ),
              Icon(
                surah.available
                    ? Icons.play_circle_fill_rounded
                    : Icons.schedule_rounded,
              ),
            ],
          ),
          onTap: surah.available ? onPlay : null,
        ),
      );
}

