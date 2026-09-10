import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../surahs/presentation/surahs_screen.dart';
import '../../library/presentation/library_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Header(theme: theme),
                  const SizedBox(height: 24),
                  const _ContinueListeningCard(),
                  const SizedBox(height: 30),
                  Text('استكشف التلاوات', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _HomeSectionCard(item: _sections[index]),
                  childCount: _sections.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.12,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.forestGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.appName, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('المصحف المرتل · رمضان 1446هـ',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueListeningCard extends StatelessWidget {
  const _ContinueListeningCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            color: AppColors.forestGreen.withValues(alpha: 0.22),
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
                Text(
                  'تابع الاستماع',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('اختر سورة لبدء التلاوة',
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'سيظهر آخر موضع استماعك هنا تلقائيًا.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SurahsScreen()),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.softGold,
                  foregroundColor: AppColors.forestGreen,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('ابدأ الاستماع'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionCard extends StatelessWidget {
  const _HomeSectionCard({required this.item});

  final _HomeSection item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: item.title,
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (item.title == 'السور') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SurahsScreen()),
              );
              return;
            }
            if (item.title == 'المفضلة') {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const FavoritesScreen(),
              ));
              return;
            }
            _showComingSoon(context, item.title);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const Spacer(),
                Text(item.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(item.subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String sectionName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$sectionName سيكون جاهزًا في الخطوات القادمة.')),
  );
}

const _sections = [
  _HomeSection(
    title: 'السور',
    subtitle: '114 سورة',
    icon: Icons.menu_book_rounded,
    color: AppColors.emerald,
  ),
  _HomeSection(
    title: 'الأجزاء',
    subtitle: '30 جزءًا',
    icon: Icons.bookmark_added_rounded,
    color: AppColors.gold,
  ),
  _HomeSection(
    title: 'تلاوات مختارة',
    subtitle: 'استمع الآن',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF7565A8),
  ),
  _HomeSection(
    title: 'المفضلة',
    subtitle: 'تلاواتك المحفوظة',
    icon: Icons.favorite_rounded,
    color: Color(0xFFB4515A),
  ),
  _HomeSection(
    title: 'عن الشيخ',
    subtitle: 'نبذة ومعلومات',
    icon: Icons.person_rounded,
    color: Color(0xFF756347),
  ),
];

class _HomeSection {
  const _HomeSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

