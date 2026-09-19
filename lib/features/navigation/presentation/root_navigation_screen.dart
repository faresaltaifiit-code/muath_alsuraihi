import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../home/presentation/home_screen.dart';
import '../../library/presentation/library_screens.dart';
import '../../more/presentation/more_screen.dart';
import '../../surahs/presentation/surahs_screen.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/recitations_provider.dart';
import '../../../widgets/mini_player.dart';

class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({super.key});
  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  int _index = 0;
  static const _screens = [HomeScreen(), SurahsScreen(), FavoritesScreen(), MoreScreen()];

  @override
  Widget build(BuildContext context) {
    final recitations = context.watch<RecitationsProvider>();
    context.read<PlayerProvider>().setPlaylist(recitations.surahs);
    return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: IndexedStack(index: _index, children: _screens)),
            const PositionedDirectional(
              start: 12,
              end: 12,
              bottom: 12,
              child: MiniPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: _SelectedNavIcon(Icons.home_outlined), label: 'الرئيسية'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: _SelectedNavIcon(Icons.menu_book_outlined), label: 'السور'),
              NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: _SelectedNavIcon(Icons.favorite_border_rounded), label: 'المفضلة'),
              NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: _SelectedNavIcon(Icons.more_horiz_rounded), label: 'المزيد'),
            ],
          ),
        ),
      );
  }
}

class _SelectedNavIcon extends StatelessWidget {
  const _SelectedNavIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 3),
          const SizedBox(
            width: 4,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFE8D8B5), shape: BoxShape.circle),
            ),
          ),
        ],
      );
}

