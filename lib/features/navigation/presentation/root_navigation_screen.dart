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
  bool _focusSurahsSearch = false;

  void _openSurahs({bool focusSearch = false}) {
    setState(() {
      _index = 1;
      _focusSurahsSearch = focusSearch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recitations = context.watch<RecitationsProvider>();
    final player = context.watch<PlayerProvider>();
    final showMiniPlayer =
        player.currentSurah != null && player.hasPlaybackInSession;
    context.read<PlayerProvider>().setPlaylist(recitations.surahs);
    return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  HomeScreen(onOpenSurahs: _openSurahs),
                  SurahsScreen(focusSearch: _focusSurahsSearch),
                  const FavoritesScreen(),
                  const MoreScreen(),
                ],
              ),
            ),
            if (showMiniPlayer)
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
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
            onDestinationSelected: (value) => setState(() {
              _index = value;
              _focusSurahsSearch = false;
            }),
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
  Widget build(BuildContext context) => Container(
        width: 54,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Icon(icon),
      );
}

