import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surah_model.dart';
import '../../../providers/favorites_provider.dart';
import '../../player/presentation/player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: favorites.isEmpty
          ? const Center(child: Text('لم تضف تلاوات إلى المفضلة بعد'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              itemBuilder: (_, index) => _SurahListTile(surah: favorites[index]),
            ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  const _SurahListTile({required this.surah});
  final SurahModel surah;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text('سورة ${surah.name}'),
          subtitle: Text(surah.available ? surah.durationText : 'غير متوفرة حاليًا'),
          leading: CircleAvatar(child: Text('${surah.number}')),
          trailing: Icon(surah.available ? Icons.play_circle_fill_rounded : Icons.schedule_rounded),
          onTap: surah.available
              ? () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: surah)))
              : null,
        ),
      );
}

