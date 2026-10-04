import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surah_model.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/recitations_provider.dart';
import '../../../widgets/app_design_widgets.dart';
import '../../player/presentation/player_screen.dart';

enum _SearchFilter { all, surahs, special }

class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  String _query = '';
  _SearchFilter _filter = _SearchFilter.all;

  @override
  Widget build(BuildContext context) {
    final recitations = context.watch<RecitationsProvider>();
    final surahs = _matching(recitations.surahs);
    final special = _matching(recitations.specialRecitations);
    final results = <_ResultGroup>[
      if (_filter == _SearchFilter.all || _filter == _SearchFilter.surahs)
        _ResultGroup('السور', surahs, Icons.menu_book_outlined),
      if (_filter == _SearchFilter.all || _filter == _SearchFilter.special)
        _ResultGroup('تلاوات مختارة', special, Icons.auto_awesome_rounded),
    ].where((group) => group.items.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'ابحث في السور والتلاوات',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip(_SearchFilter.all,
                  'الكل (${surahs.length + special.length})'),
              const SizedBox(width: 8),
              _chip(_SearchFilter.surahs, 'السور (${surahs.length})'),
              const SizedBox(width: 8),
              _chip(_SearchFilter.special, 'تلاوات مختارة (${special.length})'),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('لا توجد نتائج مطابقة'))
                : ListView(children: [
                    for (final group in results) ...[
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 4, top: 8, bottom: 4),
                        child: Text(group.title,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      ...group.items
                          .map((item) => _ResultRow(item: item, group: group)),
                    ],
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(_SearchFilter value, String label) => AppFilterChip(
        label: label,
        selected: _filter == value,
        onSelected: () => setState(() => _filter = value),
      );

  List<SurahModel> _matching(List<SurahModel> items) {
    final query = _normalize(_query);
    if (query.isEmpty) return items;
    return items
        .where((item) =>
            _normalize(item.name).contains(query) ||
            '${item.number}'.contains(query))
        .toList();
  }
}

class _ResultGroup {
  const _ResultGroup(this.title, this.items, this.icon);
  final String title;
  final List<SurahModel> items;
  final IconData icon;
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item, required this.group});
  final SurahModel item;
  final _ResultGroup group;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: TintedIconTile(
          icon: group.icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(item.number > 0 ? 'سورة ${item.name}' : item.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.number > 0
            ? 'السورة ${item.number} · ${item.durationText}'
            : 'تلاوة مختارة · ${item.durationText}'),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () async {
          await context.read<PlayerProvider>().playPlaylist(
                group.items,
                initialSurah: item,
              );
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PlayerScreen(surah: item),
          ));
        },
      );
}

String _normalize(String value) => value
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp(r'[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .trim();
