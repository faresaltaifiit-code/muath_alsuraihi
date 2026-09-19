import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/recitations_provider.dart';
import '../../../widgets/app_design_widgets.dart';
import '../../library/presentation/juz_screen.dart';
import '../../library/presentation/library_screens.dart';
import '../../player/presentation/player_screen.dart';
import '../../surahs/presentation/surahs_screen.dart';

const _showFridaySermon = false;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final recitations = context.watch<RecitationsProvider>();
    final recent = player.recentSurahs;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _Header(onSearch: () => _openSurahs(context))),
              if (player.lastSurah != null) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(child: _ContinueCard(player: player)),
              ],
              if (_showFridaySermon && _isFriday()) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                const SliverToBoxAdapter(child: _FridayCard()),
              ],
              if (recent.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 26)),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'استمعت مؤخرًا',
                    action: 'عرض الكل',
                    onAction: () => _openSurahs(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _RecentRow(items: recent)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'استكشف التلاوات',
                  action: 'فاجئني',
                  icon: Icons.shuffle_rounded,
                  onAction: () => _playRandom(context, recitations.surahs),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverGrid(
                delegate: SliverChildListDelegate.fixed([
                  _ExploreTile(
                    icon: Icons.menu_book_outlined,
                    color: AppColors.emerald,
                    title: 'السور',
                    subtitle:
                        '${recitations.surahs.where((item) => item.available).length} سورة',
                    onTap: () => _openSurahs(context),
                  ),
                  _ExploreTile(
                    icon: Icons.bookmark_added_outlined,
                    color: AppColors.goldAccent,
                    title: 'الأجزاء',
                    subtitle: '30 جزءًا',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const JuzScreen()),
                    ),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _FavoritesCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const FavoritesScreen()),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: _ComingSoonRow()),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isFriday() => DateTime.now().weekday == DateTime.friday;

  void _openSurahs(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SurahsScreen()));
  }

  Future<void> _playRandom(BuildContext context, List<SurahModel> items) async {
    final available = items.where((item) => item.available).toList();
    if (available.isEmpty) return;
    final selected = available[math.Random().nextInt(available.length)];
    await context.read<PlayerProvider>().prepareSurah(selected, autoplay: true);
    if (!context.mounted) return;
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: selected)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.emerald, AppColors.forestGreen],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.menu_book_outlined,
                color: AppColors.softGold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السلام عليكم',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13)),
                Text(
                  'معاذ السريحي',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontSize: 28),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'البحث في السور',
            onPressed: onSearch,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final surah = player.lastSurah!;
    final duration = Duration(seconds: surah.durationSeconds);
    final progress = duration > Duration.zero
        ? (player.lastPosition.inMilliseconds / duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.emerald, AppColors.forestGreen],
          ),
        ),
        child: Stack(
          children: [
            const PositionedDirectional(
                start: -42, top: -42, child: _HeroPattern()),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('تابع الاستماع',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('سورة ${surah.name}',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: Colors.white, fontSize: 38)),
                  Text(
                    'توقفت عند ${_formatDuration(player.lastPosition)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        color: AppColors.softGold,
                        backgroundColor: Colors.white.withValues(alpha: .22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: player.resumeLast,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.softGold,
                      foregroundColor: const Color(0xFF0F4A3A),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: const Text('استكمل الاستماع'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPattern extends StatelessWidget {
  const _HeroPattern();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: .13,
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(painter: _HeroPatternPainter()),
          ),
        ),
      );
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final scale in [.9, .42, .18]) {
      final path = Path();
      for (var index = 0; index < 16; index++) {
        final radius = size.width * scale * (index.isEven ? .5 : .35);
        final angle = -math.pi / 2 + index * math.pi / 8;
        final point = Offset(center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius);
        index == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FridayCard extends StatelessWidget {
  const _FridayCard();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title,
      required this.action,
      required this.onAction,
      this.icon});
  final String title;
  final String action;
  final IconData? icon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleLarge)),
          TextButton.icon(
            onPressed: onAction,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
            label: Text(action),
          ),
        ],
      );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.items});
  final List<SurahModel> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 158,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _RecentCard(surah: items[index]),
        ),
      );
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.surah});
  final SurahModel surah;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 128,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => PlayerScreen(surah: surah))),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.emerald, AppColors.forestGreen]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.softGold, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text('سورة ${surah.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontFamily: 'Amiri', fontSize: 18)),
                  Text('مؤخرًا',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12)),
                  const Spacer(),
                  Container(
                      height: 3,
                      decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(9))),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TintedIconTile(icon: icon, color: color),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

class _FavoritesCard extends StatelessWidget {
  const _FavoritesCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const TintedIconTile(
                    icon: Icons.favorite_border_rounded,
                    color: AppColors.favoriteRed),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المفضلة',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('تلاواتك المحفوظة',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ),
      );
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow();
  @override
  Widget build(BuildContext context) => Row(
        children: const [
          Expanded(
              child:
                  _SoonChip(icon: Icons.star_border_rounded, label: 'مختارة')),
          SizedBox(width: 10),
          Expanded(
              child: _SoonChip(
                  icon: Icons.person_outline_rounded, label: 'عن الشيخ')),
        ],
      );
}

class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).dividerColor, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSecondarySurface
                      : AppColors.lightSecondarySurface,
                  borderRadius: BorderRadius.circular(99)),
              child: const Text('قريبًا',
                  style: TextStyle(color: AppColors.goldAccent, fontSize: 11)),
            ),
          ],
        ),
      );
}

String _formatDuration(Duration value) {
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (value.inHours > 0)
    return '${value.inHours}:${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:$seconds';
  return '${value.inMinutes}:$seconds';
}
