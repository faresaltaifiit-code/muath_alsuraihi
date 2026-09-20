import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/recitations_provider.dart';
import '../../../widgets/app_design_widgets.dart';
import '../../player/presentation/player_screen.dart';

enum _SurahFilter { all, downloaded, favorite, short }

enum _SurahSort { mushaf, alphabetical, longest, shortest }

class SurahsScreen extends StatefulWidget {
  const SurahsScreen({super.key, this.focusSearch = false, this.juzNumber});

  final bool focusSearch;
  final int? juzNumber;

  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';
  _SurahFilter _filter = _SurahFilter.all;
  _SurahSort _sort = _SurahSort.mushaf;

  @override
  void initState() {
    super.initState();
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
    }
  }

  @override
  void didUpdateWidget(covariant SurahsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusSearch && !oldWidget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recitations = context.watch<RecitationsProvider>();
    final downloads = context.watch<DownloadsProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final player = context.watch<PlayerProvider>();
    final downloadedCount = recitations.surahs
        .where((surah) => surah.isBundled || downloads.isDownloaded(surah))
        .length;
    final results = _filteredSurahs(
      recitations.surahs,
      downloads: downloads,
      favorites: favorites,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 112),
          child: Column(
            children: [
              _SurahsHeader(
                total: recitations.surahs.length,
                downloaded: downloadedCount,
                sort: _sort,
                onSortChanged: (value) => setState(() => _sort = value),
                juzNumber: widget.juzNumber,
              ),
              const SizedBox(height: 16),
              _SearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                query: _query,
                onChanged: (value) => setState(() => _query = value.trim()),
                onCleared: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: 14),
              _Filters(
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _SurahResults(
                  state: recitations,
                  results: results,
                  downloads: downloads,
                  favorites: favorites,
                  player: player,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SurahModel> _filteredSurahs(
    List<SurahModel> source, {
    required DownloadsProvider downloads,
    required FavoritesProvider favorites,
  }) {
    final normalizedQuery = _normalizeArabic(_query);
    final results = source.where((surah) {
      if (widget.juzNumber != null && !_belongsToJuz(surah.number, widget.juzNumber!)) {
        return false;
      }
      final matchesQuery = normalizedQuery.isEmpty ||
          _normalizeArabic(surah.name).contains(normalizedQuery) ||
          surah.number.toString().contains(normalizedQuery);
      if (!matchesQuery) return false;
      return switch (_filter) {
        _SurahFilter.all => true,
        _SurahFilter.downloaded => surah.isBundled || downloads.isDownloaded(surah),
        _SurahFilter.favorite => favorites.contains(surah),
        _SurahFilter.short => surah.durationSeconds > 0 && surah.durationSeconds <= 600,
      };
    }).toList();
    switch (_sort) {
      case _SurahSort.mushaf:
        results.sort((a, b) => a.number.compareTo(b.number));
      case _SurahSort.alphabetical:
        results.sort((a, b) => _normalizeArabic(a.name).compareTo(_normalizeArabic(b.name)));
      case _SurahSort.longest:
        results.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
      case _SurahSort.shortest:
        results.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
    }
    return results;
  }
}

class _SurahsHeader extends StatelessWidget {
  const _SurahsHeader({
    required this.total,
    required this.downloaded,
    required this.sort,
    required this.onSortChanged,
    this.juzNumber,
  });

  final int total;
  final int downloaded;
  final _SurahSort sort;
  final ValueChanged<_SurahSort> onSortChanged;
  final int? juzNumber;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السور',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 36),
                ),
                Text('$total سورة · $downloaded محمّلة'),
              ],
            ),
          ),
          PopupMenuButton<_SurahSort>(
            tooltip: 'ترتيب السور',
            onSelected: onSortChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: _SurahSort.mushaf, child: Text('ترتيب المصحف')),
              PopupMenuItem(value: _SurahSort.alphabetical, child: Text('أبجدي')),
              PopupMenuItem(value: _SurahSort.longest, child: Text('الأطول')),
              PopupMenuItem(value: _SurahSort.shortest, child: Text('الأقصر')),
            ],
            child: _SortPill(label: _sortLabel(sort)),
          ),
        ],
      );
}

class _SortPill extends StatelessWidget {
  const _SortPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onCleared,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث باسم السورة أو رقمها',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'مسح البحث',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onCleared,
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 13, 16, 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.emerald, width: 1.2),
          ),
        ),
      );
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onSelected});
  final _SurahFilter selected;
  final ValueChanged<_SurahFilter> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(_SurahFilter.all, 'الكل'),
            const SizedBox(width: 8),
            _filterChip(_SurahFilter.downloaded, 'المحمّلة'),
            const SizedBox(width: 8),
            _filterChip(_SurahFilter.favorite, 'المفضلة'),
            const SizedBox(width: 8),
            _filterChip(_SurahFilter.short, 'القصيرة'),
          ],
        ),
      );

  Widget _filterChip(_SurahFilter filter, String label) => AppFilterChip(
        label: label,
        selected: selected == filter,
        onSelected: () => onSelected(filter),
      );
}

class _SurahResults extends StatelessWidget {
  const _SurahResults({
    required this.state,
    required this.results,
    required this.downloads,
    required this.favorites,
    required this.player,
  });

  final RecitationsProvider state;
  final List<SurahModel> results;
  final DownloadsProvider downloads;
  final FavoritesProvider favorites;
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: state.errorMessage!,
        actionLabel: 'إعادة المحاولة',
        onAction: state.loadSurahs,
      );
    }
    if (state.surahs.isEmpty) {
      return _StateMessage(
        icon: Icons.library_music_outlined,
        title: 'لا توجد تلاوات بعد',
        message: 'حدّث القائمة ثم أعد المحاولة.',
        actionLabel: 'تحديث القائمة',
        onAction: state.loadSurahs,
      );
    }
    if (results.isEmpty) {
      return const _StateMessage(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج مطابقة',
      );
    }
    return RefreshIndicator(
      onRefresh: state.loadSurahs,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: results.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index == results.length - 1 ? 0 : 10),
          child: _SurahRow(
            surah: results[index],
            downloads: downloads,
            favorites: favorites,
            player: player,
          ),
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.downloads,
    required this.favorites,
    required this.player,
  });

  final SurahModel surah;
  final DownloadsProvider downloads;
  final FavoritesProvider favorites;
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final nowPlaying = player.currentSurah?.audioPath == surah.audioPath;
    final isPlaying = nowPlaying && player.isPlaying;
    final isFavorite = favorites.contains(surah);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final titleColor = nowPlaying ? AppColors.darkText : onSurface;
    final meta = nowPlaying
        ? 'توقفت عند ${_formatDuration(player.position)}'
        : [surah.durationText, surah.fileSizeText]
            .where((value) => value.isNotEmpty)
            .join(' · ');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: nowPlaying ? null : theme.colorScheme.surface,
          gradient: nowPlaying
              ? const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.emerald, AppColors.forestGreen],
                )
              : null,
          border: nowPlaying ? null : Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openPlayer(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
            child: Row(
              children: [
                StarNumberBadge(number: surah.number, inverted: nowPlaying),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.number > 0 ? 'سورة ${surah.name}' : surah.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Amiri',
                          fontSize: 23,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                        surah.available ? meta : 'قريبًا',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: nowPlaying
                              ? AppColors.darkText.withValues(alpha: .8)
                              : null,
                          fontSize: 12.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (nowPlaying) _Equalizer(isPlaying: isPlaying),
                if (!nowPlaying)
                  _FavoriteButton(
                    selected: isFavorite,
                    onPressed: () => favorites.toggle(surah),
                  ),
                const SizedBox(width: 8),
                if (surah.available)
                  _DownloadButton(surah: surah, downloads: downloads)
                else
                  const _CircleStateIcon(
                    icon: Icons.schedule_rounded,
                    tooltip: 'قريبًا',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    if (!surah.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذه السورة غير متاحة حاليًا.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: surah)),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.selected, required this.onPressed});
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: selected ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          foregroundColor: selected
              ? AppColors.favoriteRed
              : Theme.of(context).textTheme.bodyMedium?.color,
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        icon: Icon(selected ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18),
      );
}

class _CircleStateIcon extends StatelessWidget {
  const _CircleStateIcon({required this.icon, required this.tooltip});
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: null,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        icon: Icon(icon, size: 18),
      );
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.surah, required this.downloads});
  final SurahModel surah;
  final DownloadsProvider downloads;

  @override
  Widget build(BuildContext context) {
    final bundled = surah.isBundled;
    final downloaded = bundled || downloads.isDownloaded(surah);
    final hasFailed = downloads.error?.contains(surah.name) ?? false;
    if (downloaded) {
      return IconButton(
        tooltip: bundled ? 'متاحة داخل التطبيق' : 'محمّلة — اضغط للحذف',
        onPressed: bundled ? null : () => _confirmDelete(context),
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          backgroundColor: AppColors.emerald.withValues(alpha: .20),
          foregroundColor: AppColors.emerald,
        ),
        icon: const Icon(Icons.check_rounded, size: 18),
      );
    }
    if (downloads.isDownloading(surah)) {
      final value = downloads.progressFor(surah);
      return Tooltip(
        message: value == null ? 'جاري التحميل' : 'جاري التحميل ${(value * 100).round()}%',
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 2,
                color: AppColors.goldAccent,
                backgroundColor: Theme.of(context).dividerColor,
              ),
              Text(
                value == null ? '…' : '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return IconButton(
      tooltip: hasFailed ? 'تعذر التنزيل — أعد المحاولة' : 'تحميل سورة ${surah.name}',
      onPressed: () => downloads.download(surah),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        foregroundColor: hasFailed ? Colors.orange : Theme.of(context).textTheme.bodyMedium?.color,
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      icon: Icon(hasFailed ? Icons.warning_amber_rounded : Icons.download_rounded, size: 18),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف تنزيل سورة ${surah.name}؟'),
        content: const Text('سيُحذف الصوت المحفوظ على هذا الجهاز فقط.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (approved == true) await downloads.delete(surah);
  }
}

class _Equalizer extends StatefulWidget {
  const _Equalizer({required this.isPlaying});
  final bool isPlaying;

  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Equalizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) _controller.repeat(reverse: true);
    if (!widget.isPlaying && oldWidget.isPlaying) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 16,
        height: 18,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [8.0, 16.0, 11.0]
                .asMap()
                .entries
                .map((entry) {
                  final wave = widget.isPlaying
                      ? .4 + ((entry.key + 1) * .16 + _controller.value).remainder(.6)
                      : 1.0;
                  return Container(
                    width: 3,
                    height: entry.value * wave,
                    decoration: BoxDecoration(
                      color: AppColors.softGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                })
                .toList(),
          ),
        ),
      );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppColors.goldAccent),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!, textAlign: TextAlign.center),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

String _normalizeArabic(String value) => value
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp(r'[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .trim();

String _sortLabel(_SurahSort sort) => switch (sort) {
      _SurahSort.mushaf => 'ترتيب المصحف',
      _SurahSort.alphabetical => 'أبجدي',
      _SurahSort.longest => 'الأطول',
      _SurahSort.shortest => 'الأقصر',
    };

String _formatDuration(Duration value) {
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (value.inHours > 0) {
    return '${value.inHours}:${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:$seconds';
  }
  return '${value.inMinutes}:$seconds';
}

bool _belongsToJuz(int surahNumber, int juzNumber) {
  final range = _juzRanges[juzNumber - 1];
  return surahNumber >= range.$1 && surahNumber <= range.$2;
}

const _juzRanges = <(int, int)>[
  (1, 2), (2, 3), (3, 4), (4, 4), (4, 5), (5, 6), (6, 7),
  (7, 8), (8, 9), (9, 9), (9, 11), (11, 12), (12, 15), (15, 16),
  (17, 18), (18, 20), (21, 22), (23, 25), (25, 27), (27, 29),
  (29, 33), (33, 36), (36, 39), (39, 41), (41, 45), (46, 51),
  (51, 57), (58, 66), (67, 77), (78, 114),
];
