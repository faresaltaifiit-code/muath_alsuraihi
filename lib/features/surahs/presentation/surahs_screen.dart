import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/surah_model.dart';
import '../../player/presentation/player_screen.dart';
import '../../../providers/recitations_provider.dart';
import '../../../providers/favorites_provider.dart';

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
        message: 'أضف رابط ملف JSON في app_urls.dart ثم أعد تشغيل التطبيق.',
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
        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                color: AppColors.softGold,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text('${surah.number}',
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سورة ${surah.name}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(surah.durationText.isEmpty ? 'المدة غير متوفرة' : surah.durationText,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'تشغيل سورة ${surah.name}',
              onPressed: () {
                if (!surah.available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('هذه التلاوة غير متوفرة حاليًا.')),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PlayerScreen(surah: surah),
                ));
              },
              icon: Icon(surah.available ? Icons.play_arrow_rounded : Icons.schedule_rounded),
            ),
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
              Icon(icon, size: 54, color: AppColors.emerald),
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

void _comingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature سيكون جاهزًا في الخطوات القادمة.')),
  );
}

