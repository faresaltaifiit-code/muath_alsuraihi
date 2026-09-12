import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surah_model.dart';
import '../../../providers/recitations_provider.dart';
import '../../player/presentation/player_screen.dart';

class SpecialRecitationsScreen extends StatelessWidget {
  const SpecialRecitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recitations = context.watch<RecitationsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('تلاوات مختارة')),
      body: recitations.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: recitations.specialRecitations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _SpecialCard(
                item: recitations.specialRecitations[index],
              ),
            ),
    );
  }
}

class _SpecialCard extends StatelessWidget {
  const _SpecialCard({required this.item});
  final SurahModel item;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(18, 12, 10, 12),
          leading: const CircleAvatar(child: Icon(Icons.auto_awesome_rounded)),
          title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(item.reciterName),
          trailing: IconButton.filledTonal(
            tooltip: 'تشغيل',
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PlayerScreen(surah: item)),
            ),
          ),
        ),
      );
}
