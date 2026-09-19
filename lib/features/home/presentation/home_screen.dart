import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/recitations_provider.dart';
import '../../library/presentation/special_recitations_screen.dart';
import '../../player/presentation/player_screen.dart';
import '../../surahs/presentation/surahs_screen.dart';

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
            SliverToBoxAdapter(child: _Header(onSearch: () => _openLibrary(context))),
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
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            SliverToBoxAdapter(child: _LibraryCard(onTap: () => _openLibrary(context))),
            if (hasSpecial) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _SpecialRecitationsCard(
                  count: recitations.specialRecitations.length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SpecialRecitationsScreen()),
                  ),
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
  const _Header({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(AppStrings.appName, style: Theme.of(context).textTheme.titleLarge)),
          IconButton(
            tooltip: 'البحث في السور',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
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
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 18),
            Text('سورة ${surah.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 5),
            Text(
              'الموضع ${_formatDuration(player.lastPosition)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .8)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: player.resumeLast,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
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
        height: 142,
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
        width: 172,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: surah)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.softGold,
                    foregroundColor: AppColors.forestGreen,
                    child: Text('${surah.number}'),
                  ),
                  const Spacer(),
                  Text('سورة ${surah.name}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(surah.durationText, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _NavigationCard(
        icon: Icons.menu_book_rounded,
        title: 'المكتبة',
        subtitle: 'تصفح السور، وابحث عنها، وأضفها إلى المفضلة',
        onTap: onTap,
      );
}

class _SpecialRecitationsCard extends StatelessWidget {
  const _SpecialRecitationsCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _NavigationCard(
        icon: Icons.auto_awesome_rounded,
        title: 'تلاوات خاصة',
        subtitle: '$count تلاوات، منها دعاء الختم وتلاوة الخسوف',
        onTap: onTap,
      );
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(18, 14, 12, 14),
          leading: CircleAvatar(
            backgroundColor: AppColors.softGold,
            foregroundColor: AppColors.forestGreen,
            child: Icon(icon),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: onTap,
        ),
      );
}

String _formatDuration(Duration value) =>
    '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
