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
        body: Column(
          children: [
            Expanded(child: IndexedStack(index: _index, children: _screens)),
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'السور'),
            NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'المفضلة'),
            NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.more_rounded), label: 'المزيد'),
          ],
        ),
      );
  }
}

