import 'dart:math' as math;

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
      appBar: AppBar(
        title: const Text('الورد اليومي'),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: _WirdRing(size: 180, stats: stats)),
        const SizedBox(height: 22),
        Text('هدفك اليومي', style: Theme.of(context).textTheme.titleMedium),
        Text('بالسور أو بالوقت', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _GoalChip(
                  label: 'سور', type: DailyWirdType.surahs, stats: stats)),
          const SizedBox(width: 8),
          Expanded(
              child: _GoalChip(
                  label: 'دقيقة', type: DailyWirdType.minutes, stats: stats)),
          const SizedBox(width: 8),
          Expanded(
              child: _GoalChip(
                  label: 'جزء كامل', type: DailyWirdType.juz, stats: stats)),
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
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.softGold,
            foregroundColor: const Color(0xFF0F4A3A),
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.menu_book_outlined),
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
        CustomPaint(
          size: Size.square(size),
          painter: _WirdRingPainter(
            progress: stats.dailyProgressFraction,
            trackColor: Theme.of(context).dividerColor,
            strokeWidth: size > 100 ? 12 : 7,
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${stats.dailyProgress} / ${stats.goal}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Amiri', fontSize: size > 100 ? 30 : null)),
          ),
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
  Widget build(BuildContext context) {
    final selected = stats.goalType == type;
    final defaultGoal = type == DailyWirdType.minutes
        ? 15
        : type == DailyWirdType.juz
            ? 1
            : 3;
    final number = type == DailyWirdType.juz
        ? null
        : '${selected ? stats.goal : defaultGoal}';
    return Material(
      color: selected
          ? AppColors.goldAccent.withValues(alpha: .16)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => stats.setGoal(type, selected ? stats.goal : defaultGoal),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.goldAccent
                  : Theme.of(context).dividerColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (number != null)
              Text(number,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Amiri', color: AppColors.goldAccent)),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      ),
    );
  }
}

class _WirdRingPainter extends CustomPainter {
  const _WirdRingPainter(
      {required this.progress,
      required this.trackColor,
      required this.strokeWidth});
  final double progress;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, track);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: const [AppColors.emerald, AppColors.goldAccent],
      ).createShader(rect);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_WirdRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

String _goalLabel(DailyWirdType type) => switch (type) {
      DailyWirdType.surahs => 'سور اليوم',
      DailyWirdType.minutes => 'دقائق اليوم',
      DailyWirdType.juz => 'من الجزء'
    };
String _dayLabel(DateTime day) =>
    const ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'][day.weekday % 7];
