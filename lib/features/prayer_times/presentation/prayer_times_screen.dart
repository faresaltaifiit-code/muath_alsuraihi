import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/prayer_times_service.dart';
import '../../../providers/prayer_times_provider.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

/// The compact entry on Home. It deliberately uses the gold time-of-day
/// treatment instead of the emerald playback treatment.
class PrayerTimesHomeStrip extends StatefulWidget {
  const PrayerTimesHomeStrip({super.key});

  @override
  State<PrayerTimesHomeStrip> createState() => _PrayerTimesHomeStripState();
}

class _PrayerTimesHomeStripState extends State<PrayerTimesHomeStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prayers = context.read<PrayerTimesProvider>();
      if (prayers.today == null && !prayers.isRefreshing) {
        unawaited(prayers.refreshPrayerTimes());
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayers = context.watch<PrayerTimesProvider>();
    final currentIqama = prayers.currentIqamaPrayer;
    final prayer = currentIqama ?? prayers.nextPrayer;
    final countdown = currentIqama != null
        ? prayers.timeUntilIqama
        : prayers.timeUntilNextPrayer;
    final label = currentIqama != null ? 'الإقامة' : 'الصلاة القادمة';
    final title = prayer == null
        ? (prayers.isRefreshing ? 'جاري تحديث المواقيت' : 'مواقيت الصلاة')
        : prayer.arabicName;

    return Semantics(
      button: true,
      label: 'مواقيت الصلاة. $title',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFC9A24A), Color(0xFFECDCB6)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrayerTimesScreen(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3A2E).withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: Color(0xFF0F3A2E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label · ${prayers.locationLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF0F3A2E)
                                    .withValues(alpha: .75),
                                fontSize: 11.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: const Color(0xFF0F3A2E),
                                      fontFamily: 'Amiri',
                                      fontSize: 20,
                                    ),
                              ),
                            ),
                            if (countdown != null && !countdown.isNegative) ...[
                              const Text(' — ',
                                  style: TextStyle(color: Color(0xFF0F3A2E))),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  'بعد ${_formatCompactDuration(countdown)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF0F3A2E),
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF0F3A2E)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompactDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prayers = context.read<PrayerTimesProvider>();
      if (prayers.today == null && !prayers.isRefreshing) {
        unawaited(prayers.refreshPrayerTimes());
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayers = context.watch<PrayerTimesProvider>();
    final theme = Theme.of(context);
    final currentIqama = prayers.currentIqamaPrayer;
    final nextPrayer = prayers.nextPrayer;
    final highlightedPrayer = currentIqama ?? nextPrayer;
    final countdown = currentIqama != null
        ? prayers.timeUntilIqama
        : prayers.timeUntilNextPrayer;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ),
      body: !prayers.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.emerald, size: 18),
                            const SizedBox(width: 6),
                            Text(prayers.locationLabel,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentIqama != null
                              ? 'متبقي على الإقامة'
                              : 'الصلاة القادمة',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          highlightedPrayer?.arabicName ?? 'مواقيت الغد قريبًا',
                          style: theme.textTheme.displaySmall?.copyWith(
                              color: AppColors.softGold, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentIqama != null
                              ? 'إقامة ${currentIqama.arabicName}'
                              : highlightedPrayer == null
                                  ? 'سيتم التحديث مع بداية يوم جديد'
                                  : 'أذان ${highlightedPrayer.arabicName}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatDuration(countdown),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.displayMedium?.copyWith(
                              fontFamily: 'Amiri', color: AppColors.softGold),
                        ),
                        const SizedBox(height: 8),
                        const Text('الإقامة توقيت تقريبي قابل للتعديل لاحقًا',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('اليوم', style: theme.textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: prayers.isRefreshing
                          ? null
                          : () => prayers.refreshPrayerTimes(),
                      icon: prayers.isRefreshing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded),
                      label: const Text('تحديث'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (prayers.today == null && prayers.isRefreshing)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (prayers.today != null)
                  ...PrayerName.values.map((prayer) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PrayerRow(
                          prayer: prayer,
                          time: prayers.today!.timeFor(prayer),
                          highlighted: prayer == highlightedPrayer,
                        ),
                      )),
                if (prayers.error != null) ...[
                  const SizedBox(height: 4),
                  Text(prayers.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 14),
                Card(
                  child: Column(children: [
                    SwitchListTile(
                      secondary:
                          const Icon(Icons.notifications_active_outlined),
                      title: const Text('تنبيهات الأذان والإقامة'),
                      subtitle: Text(prayers.alertsEnabled
                          ? 'مفعّلة للأيام الستة القادمة.'
                          : 'فعّلها لتصلك تنبيهات الصلاة.'),
                      value: prayers.alertsEnabled,
                      onChanged: prayers.setAlertsEnabled,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.my_location_rounded),
                      title: const Text('استخدام موقعي الحالي'),
                      subtitle:
                          const Text('يُستخدم عند الطلب لتحديث المواقيت.'),
                      trailing: prayers.isRefreshing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_left_rounded),
                      onTap: prayers.isRefreshing
                          ? null
                          : prayers.useCurrentLocation,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(
                  'الموقع والمواقيت محفوظة على جهازك لتشغيل هذه الميزة فقط، ولا تُرسل إلى خادم التطبيق.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.isNegative) return '--:--';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.highlighted,
  });

  final PrayerName prayer;
  final DateTime time;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlighted
          ? AppColors.emerald.withValues(alpha: .14)
          : theme.colorScheme.surface,
      child: ListTile(
        leading: Icon(
          prayer == PrayerName.fajr || prayer == PrayerName.isha
              ? Icons.nightlight_round
              : Icons.wb_sunny_outlined,
          color: highlighted ? AppColors.goldAccent : null,
        ),
        title: Text(prayer.arabicName),
        subtitle: Text('الإقامة بعد ${prayer.iqamaDelay.inMinutes} دقيقة'),
        trailing: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(_formatTime(time), style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour >= 12 ? 'م' : 'ص'}';
  }
}
