import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/player_provider.dart';
import '../../library/presentation/juz_screen.dart';
import '../../library/presentation/library_screens.dart';
import '../../surahs/presentation/surahs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 26, 34, 24),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _HomeHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 38)),
              SliverToBoxAdapter(
                child: player.lastSurah == null
                    ? _StartListeningCard(onTap: () => _openSurahs(context))
                    : _ContinueListeningCard(player: player),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 54)),
              const SliverToBoxAdapter(child: _ExploreTitle()),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverGrid(
                delegate: SliverChildListDelegate.fixed([
                  _ExploreCard(
                    icon: Icons.menu_book_outlined,
                    color: const Color(0xFF1D856E),
                    title: 'السور',
                    subtitle: 'استعرض التلاوات',
                    onTap: () => _openSurahs(context),
                  ),
                  _ExploreCard(
                    icon: Icons.bookmark_added_outlined,
                    color: const Color(0xFFC99B3C),
                    title: 'الأجزاء',
                    subtitle: '30 جزءًا',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const JuzScreen()),
                    ),
                  ),
                  _ExploreCard(
                    icon: Icons.auto_awesome_outlined,
                    color: const Color(0xFF9373D6),
                    title: 'تلاوات مختارة',
                    subtitle: 'قريبًا',
                    onTap: () => _showSoon(context, 'التلاوات المختارة'),
                  ),
                  _ExploreCard(
                    icon: Icons.favorite_border_rounded,
                    color: const Color(0xFFD26070),
                    title: 'المفضلة',
                    subtitle: 'تلاواتك المحفوظة',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
                    ),
                  ),
                  _ExploreCard(
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF9A7B4D),
                    title: 'عن الشيخ',
                    subtitle: 'قريبًا',
                    onTap: () => _showSoon(context, 'نبذة الشيخ'),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: .83,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
            ],
          ),
        ),
      ),
    );
  }

  void _openSurahs(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SurahsScreen()));
  }

  void _showSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title قريبًا بإذن الله.')),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) => Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.darkSecondarySurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.menu_book_outlined, color: Colors.white, size: 46),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معاذ السريحي',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 27,
                      ),
                ),
                const SizedBox(height: 3),
                Text('المصحف المرتل · رمضان 1446هـ', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      );
}

class _ContinueListeningCard extends StatelessWidget {
  const _ContinueListeningCard({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final surah = player.lastSurah!;
    return _ListeningCard(
      title: 'تابع الاستماع',
      name: 'سورة ${surah.name}',
      detail: 'استكمل من ${_formatDuration(player.lastPosition)}',
      action: 'استكمل الاستماع',
      onTap: player.resumeLast,
    );
  }
}

class _StartListeningCard extends StatelessWidget {
  const _StartListeningCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ListeningCard(
        title: 'ابدأ الاستماع',
        name: 'اختر سورة',
        detail: 'اختر من المكتبة لبدء التلاوة.',
        action: 'استعرض السور',
        onTap: onTap,
      );
}

class _ListeningCard extends StatelessWidget {
  const _ListeningCard({
    required this.title,
    required this.name,
    required this.detail,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String name;
  final String detail;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B8B79), Color(0xFF135642)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(34),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 32, 34, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.softGold, size: 31),
                  const SizedBox(width: 10),
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 24)),
                ],
              ),
              const SizedBox(height: 36),
              Text(name, textAlign: TextAlign.right, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 31)),
              const SizedBox(height: 6),
              Text(detail, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: .76))),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(76),
                  backgroundColor: AppColors.softGold,
                  foregroundColor: AppColors.forestGreen,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 34),
                label: Text(action),
              ),
            ],
          ),
        ),
      );
}

class _ExploreTitle extends StatelessWidget {
  const _ExploreTitle();

  @override
  Widget build(BuildContext context) => Text(
        'استكشف التلاوات',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 29),
      );
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)),
                    child: Icon(icon, color: color, size: 32),
                  ),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23)),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      );
}

String _formatDuration(Duration value) {
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (value.inHours > 0) return '${value.inHours}:${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:$seconds';
  return '${value.inMinutes}:$seconds';
}
