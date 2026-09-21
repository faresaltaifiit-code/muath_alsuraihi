import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surah_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/recitations_provider.dart';
import '../../player/presentation/player_screen.dart';

enum SpecialRecitationsCategory { selected, sermons, supplications }

class SpecialRecitationsScreen extends StatefulWidget {
  const SpecialRecitationsScreen({
    super.key,
    this.initialCategory = SpecialRecitationsCategory.selected,
  });

  final SpecialRecitationsCategory initialCategory;

  @override
  State<SpecialRecitationsScreen> createState() =>
      _SpecialRecitationsScreenState();
}

class _SpecialRecitationsScreenState extends State<SpecialRecitationsScreen> {
  late SpecialRecitationsCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final recitations = context.watch<RecitationsProvider>();
    final items = recitations.specialRecitations
        .where((item) => _matchesCategory(item, _category))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('المحتوى')),
      body: recitations.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SpecialRecitationsCategory.values
                        .map(
                          (category) => ChoiceChip(
                            label: Text(_categoryLabel(category)),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد محتوى في هذا القسم حاليًا',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _SpecialCard(item: items[index]),
                        ),
                ),
              ],
            ),
    );
  }

  static bool _matchesCategory(
    SurahModel item,
    SpecialRecitationsCategory category,
  ) => switch (category) {
        SpecialRecitationsCategory.sermons =>
          item.id.startsWith('friday_sermon_'),
        SpecialRecitationsCategory.supplications => item.id == 'douaa_khatm',
        SpecialRecitationsCategory.selected =>
          item.id != 'douaa_khatm' && !item.id.startsWith('friday_sermon_'),
      };

  static String _categoryLabel(SpecialRecitationsCategory category) =>
      switch (category) {
        SpecialRecitationsCategory.selected => 'تلاوات مختارة',
        SpecialRecitationsCategory.sermons => 'خطب الجمعة',
        SpecialRecitationsCategory.supplications => 'أدعية',
      };
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
          subtitle: const Text(
            kReciterName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
