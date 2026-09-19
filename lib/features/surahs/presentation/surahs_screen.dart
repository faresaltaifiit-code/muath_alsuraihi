import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surah_model.dart';
import '../../player/presentation/player_screen.dart';
import '../../../providers/recitations_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/downloads_provider.dart';

class SurahsScreen extends StatefulWidget {
  const SurahsScreen({super.key});

  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecitationsProvider>();
    final results = state.surahs.where(_matchesQuery).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('السور')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث باسم السورة أو رقمها',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(state, results)),
        ],
      ),
    );
  }

  bool _matchesQuery(SurahModel surah) =>
      _query.isEmpty ||
      surah.name.contains(_query) ||
      surah.number.toString().contains(_query);

  Widget _buildContent(RecitationsProvider state, List<SurahModel> results) {
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
        message: 'تأكد من وجود ملف قائمة التلاوات داخل التطبيق ثم أعد التشغيل.',
        actionLabel: 'تحديث القائمة',
        onAction: state.loadSurahs,
      );
    }
    if (results.isEmpty) {
      return const _StateMessage(
        icon: Icons.search_off_rounded,
        title: 'لم نجد سورة بهذا الاسم',
      );
    }
    return RefreshIndicator(
      onRefresh: state.loadSurahs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: results.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _SurahCard(surah: results[index]),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({required this.surah});
  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloads = context.watch<DownloadsProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text('${surah.number}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سورة ${surah.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (surah.available &&
                      (surah.durationText.isNotEmpty ||
                          surah.fileSizeText.isNotEmpty)) ...[
                    const SizedBox(height: 2),
                    Text(
                      [surah.durationText, surah.fileSizeText]
                          .where((value) => value.isNotEmpty)
                          .join(' • '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (!surah.available) ...[
                    const SizedBox(height: 2),
                    Text('قريبًا', style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'تشغيل سورة ${surah.name}',
              onPressed: () {
                if (!surah.available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('سورة آل عمران قريبًا بإذن الله.')),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PlayerScreen(surah: surah),
                ));
              },
              icon: Icon(surah.available ? Icons.play_arrow_rounded : Icons.schedule_rounded),
            ),
            if (surah.available) _DownloadButton(surah: surah, downloads: downloads),
            IconButton(
              tooltip: 'المفضلة',
              onPressed: () => context.read<FavoritesProvider>().toggle(surah),
              icon: Icon(context.watch<FavoritesProvider>().contains(surah)
                  ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.surah, required this.downloads});
  final SurahModel surah;
  final DownloadsProvider downloads;

  @override
  Widget build(BuildContext context) {
    final hasFailed = downloads.error?.contains(surah.name) ?? false;
    if (downloads.isDownloaded(surah)) {
      return IconButton(
        tooltip: 'محملة — اضغط للحذف',
        icon: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.secondary, size: 18),
        onPressed: () => _confirmDelete(context),
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
              CircularProgressIndicator(value: value, strokeWidth: 2),
              Text(value == null ? '…' : '${(value * 100).round()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
            ],
          ),
        ),
      );
    }
    if (hasFailed) {
      return IconButton(
        tooltip: 'تعذر التنزيل — إعادة المحاولة',
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
        onPressed: () => downloads.download(surah),
      );
    }
    return IconButton(
      tooltip: 'تحميل سورة ${surah.name}',
      onPressed: () => downloads.download(surah),
      icon: const Icon(Icons.download_rounded),
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
              Icon(icon, size: 54, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
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

// ignore: unused_element
void _comingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature سيكون جاهزًا في الخطوات القادمة.')),
  );
}

