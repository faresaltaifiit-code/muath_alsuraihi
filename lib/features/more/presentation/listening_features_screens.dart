import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/listening_stats_provider.dart';

class ListeningStatsScreen extends StatelessWidget {
  const ListeningStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<ListeningStatsProvider>();
    final days = stats.lastSevenDays;
    final maxMinutes =
        days.fold(1, (max, item) => item.minutes > max ? item.minutes : max);
    return Scaffold(
      appBar: AppBar(title: const Text('إحصاءاتي')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('بياناتك هذي محفوظة على جهازك فقط، ولا تُرسل لأي مكان',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: _StatCard(
                    value: '${stats.totalListeningMinutes ~/ 60}',
                    label: 'ساعة استماع')),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: '${stats.completedSurahs}', label: 'سورة أكملتها')),
          ]),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آخر 7 أيام',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 130,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: days
                              .map((item) => Expanded(
                                      child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                              child: Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: FractionallySizedBox(
                                                    heightFactor: item.minutes /
                                                        maxMinutes,
                                                    child: DecoratedBox(
                                                        decoration:
                                                            BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                              begin: Alignment
                                                                  .bottomCenter,
                                                              end: Alignment
                                                                  .topCenter,
                                                              colors: [
                                                            AppColors.emerald,
                                                            AppColors.goldAccent
                                                          ]),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              99),
                                                    )),
                                                  ))),
                                          const SizedBox(height: 8),
                                          Text(_dayLabel(item.day),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ]),
                                  )))
                              .toList(),
                        )),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الأكثر استماعًا',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (stats.mostListened.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('ابدأ الاستماع لتظهر إحصاءاتك هنا.')),
              ...stats.mostListened.indexed.map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        backgroundColor:
                            AppColors.goldAccent.withValues(alpha: .22),
                        child: Text('${entry.$1 + 1}')),
                    title: Text(entry.$2.name),
                    trailing: Text('${entry.$2.count} مرات'),
                  )),
            ]),
          )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: stats.clear,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('مسح الإحصاءات'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(children: [
            Text(value, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium)
          ])));
}

String _dayLabel(DateTime day) =>
    const ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'][day.weekday % 7];
