import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/listening_stats_provider.dart';
import '../../../providers/player_provider.dart';

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

class DailyWirdScreen extends StatelessWidget {
  const DailyWirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<ListeningStatsProvider>();
    final player = context.read<PlayerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الورد اليومي')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: _WirdRing(size: 180, stats: stats)),
        const SizedBox(height: 22),
        Text('اختر هدفك', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _GoalChip(
              label: 'سور اليوم', type: DailyWirdType.surahs, stats: stats),
          _GoalChip(
              label: 'دقائق اليوم', type: DailyWirdType.minutes, stats: stats),
          _GoalChip(label: 'جزء كامل', type: DailyWirdType.juz, stats: stats),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          IconButton(
              onPressed: stats.goal > 1
                  ? () => stats.setGoal(stats.goalType, stats.goal - 1)
                  : null,
              icon: const Icon(Icons.remove_rounded)),
          Expanded(
              child: Center(
                  child: Text('${stats.goal}',
                      style: Theme.of(context).textTheme.displaySmall))),
          IconButton(
              onPressed: () => stats.setGoal(stats.goalType, stats.goal + 1),
              icon: const Icon(Icons.add_rounded)),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: player.lastSurah == null ? null : player.resumeLast,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('تابع الاستماع لإكمال اليوم'),
        ),
      ]),
    );
  }
}

class DailyWirdCard extends StatelessWidget {
  const DailyWirdCard({super.key});
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<ListeningStatsProvider>();
    return Card(
        child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DailyWirdScreen())),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _WirdRing(size: 72, stats: stats),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('الورد اليومي',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('هدفك الشخصي اليوم',
                      style: Theme.of(context).textTheme.bodyMedium),
                ])),
            const Icon(Icons.chevron_left_rounded),
          ])),
    ));
  }
}

class _WirdRing extends StatelessWidget {
  const _WirdRing({required this.size, required this.stats});
  final double size;
  final ListeningStatsProvider stats;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
                value: stats.dailyProgressFraction,
                strokeWidth: size > 100 ? 12 : 7,
                strokeCap: StrokeCap.round,
                color: AppColors.goldAccent,
                backgroundColor: Theme.of(context).dividerColor)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${stats.dailyProgress} / ${stats.goal}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontFamily: 'Amiri')),
          Text(_goalLabel(stats.goalType),
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ]));
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

class _GoalChip extends StatelessWidget {
  const _GoalChip(
      {required this.label, required this.type, required this.stats});
  final String label;
  final DailyWirdType type;
  final ListeningStatsProvider stats;
  @override
  Widget build(BuildContext context) => ChoiceChip(
      label: Text(label),
      selected: stats.goalType == type,
      onSelected: (_) => stats.setGoal(
          type,
          type == DailyWirdType.minutes
              ? 15
              : type == DailyWirdType.juz
                  ? 1
                  : 3));
}

String _goalLabel(DailyWirdType type) => switch (type) {
      DailyWirdType.surahs => 'سور اليوم',
      DailyWirdType.minutes => 'دقائق اليوم',
      DailyWirdType.juz => 'من الجزء'
    };
String _dayLabel(DateTime day) =>
    const ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'][day.weekday % 7];
