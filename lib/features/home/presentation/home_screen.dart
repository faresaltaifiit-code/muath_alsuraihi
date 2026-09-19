import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/recitations_provider.dart';
import '../../../providers/downloads_provider.dart';
import '../../library/presentation/special_recitations_screen.dart';
import '../../more/presentation/more_screen.dart';
import '../../player/presentation/player_screen.dart';
import '../../surahs/presentation/surahs_screen.dart';

const _showSheikhPicks = false;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final recitations = context.watch<RecitationsProvider>();
    final hasContinue = player.lastSurah != null;
    final hasRecent = player.recentSurahs.length >= 3;
    final hasSpecial = recitations.specialRecitations.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: CustomScrollView(
            slivers: [
            SliverToBoxAdapter(
              child: _Header(
                onSearch: () => _openLibrary(context),
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MoreScreen()),
                ),
              ),
            ),
            if (!hasContinue) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              const SliverToBoxAdapter(child: _WelcomeMessage()),
            ],
            if (hasContinue) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
              SliverToBoxAdapter(child: _ContinueListeningCard(player: player)),
            ],
            if (hasRecent) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              const SliverToBoxAdapter(child: _SectionTitle('آخر ما استمعت')),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _RecentList(items: player.recentSurahs)),
            ],
            if (_showSheikhPicks) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(child: _SectionTitle('مختارات الشيخ')),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(child: _SheikhPicksDesign()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            if (hasSpecial) ...[
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _LibraryCard(
                        count: recitations.surahs.where((surah) => surah.available).length,
                        onTap: () => _openLibrary(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SpecialRecitationsCard(
                        count: recitations.specialRecitations.length,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const SpecialRecitationsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: _LibraryCard(
                  count: recitations.surahs.where((surah) => surah.available).length,
                  onTap: () => _openLibrary(context),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  void _openLibrary(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SurahsScreen()));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onSettings});
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.emerald,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.softGold, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السلام عليكم', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 1),
                Text('معاذ السريحي', style: Theme.of(context).textTheme.titleMedium),
                Text('قرآن وتلاوات', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _HeaderAction(
            tooltip: 'البحث في السور',
            icon: Icons.search_rounded,
            onPressed: onSearch,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            tooltip: 'الإعدادات',
            icon: Icons.settings_outlined,
            onPressed: onSettings,
          ),
        ],
      );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).cardTheme.color,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
        ),
      );
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.waving_hand_rounded, color: AppColors.softGold, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'مرحبًا بك، اختر سورة وابدأ الاستماع.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ContinueListeningCard extends StatelessWidget {
  const _ContinueListeningCard({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final surah = player.lastSurah!;
    final duration = Duration(seconds: surah.durationSeconds);
    final progress = duration > Duration.zero
        ? (player.lastPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forestGreen, AppColors.emerald],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.softGold),
                SizedBox(width: 8),
                Text('استمر من حيث توقفت',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 12),
            Text('سورة ${surah.name}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                    )),
            const SizedBox(height: 2),
            Text(
              'توقفت عند ${_formatDuration(player.lastPosition)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .8)),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: AppColors.softGold,
                backgroundColor: Colors.white.withValues(alpha: .2),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              child: FilledButton.icon(
                onPressed: player.resumeLast,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: AppColors.softGold,
                  foregroundColor: AppColors.forestGreen,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('متابعة الاستماع'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(value, style: Theme.of(context).textTheme.titleLarge);
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.items});
  final List<SurahModel> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _RecentCard(surah: items[index]),
        ),
      );
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.surah});
  final SurahModel surah;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 144,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: surah)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 18, color: AppColors.emerald),
                      const Spacer(),
                      _SourceBadge(surah: surah),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'سورة ${surah.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(surah.durationText, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.surah});
  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    final downloaded = surah.isBundled || context.watch<DownloadsProvider>().isDownloaded(surah);
    return Tooltip(
      message: downloaded ? 'محملة' : 'بث',
      child: Icon(
        downloaded ? Icons.check_circle_rounded : Icons.cloud_outlined,
        color: downloaded ? AppColors.emerald : Theme.of(context).textTheme.bodySmall?.color,
        size: 17,
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ShortcutCard(
        icon: Icons.menu_book_rounded,
        title: 'المصحف',
        detail: '$count سورة',
        onTap: onTap,
      );
}

class _SheikhPicksDesign extends StatelessWidget {
  const _SheikhPicksDesign();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _pickLabels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final pick = _pickLabels[index];
            return SizedBox(
              width: 132,
              child: Card(
                color: AppColors.emerald.withValues(alpha: .16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(pick.icon, color: AppColors.emerald, size: 22),
                      const Spacer(),
                      Text(pick.label, style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

const _pickLabels = [
  _PickLabel('تلاوات خاشعة', Icons.nightlight_round),
  _PickLabel('تلاوات القيام', Icons.mosque_outlined),
  _PickLabel('تلاوات قصيرة', Icons.auto_awesome_rounded),
  _PickLabel('أدعية', Icons.volunteer_activism_outlined),
];

class _PickLabel {
  const _PickLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SpecialRecitationsCard extends StatelessWidget {
  const _SpecialRecitationsCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ShortcutCard(
        icon: Icons.auto_awesome_rounded,
        title: 'تلاوات خاصة',
        detail: '$count خاصة',
        onTap: onTap,
      );
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.icon, required this.title, required this.detail, required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.emerald, size: 30),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

String _formatDuration(Duration value) =>
    '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
