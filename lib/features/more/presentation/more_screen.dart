import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/recitations_provider.dart';
import 'about_privacy_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final downloads = context.watch<DownloadsProvider>();
    final recitations = context.watch<RecitationsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('المظهر', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('تلقائي'), icon: Icon(Icons.brightness_auto_rounded)),
                  ButtonSegment(value: ThemeMode.light, label: Text('فاتح'), icon: Icon(Icons.light_mode_rounded)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('ليلي'), icon: Icon(Icons.dark_mode_rounded)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (values) => settings.setThemeMode(values.first),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('التنزيلات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: const Text('المساحة المستخدمة'),
                  trailing: Text(_formatBytes(downloads.storageBytes)),
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_rounded),
                  title: Text(downloads.isDownloadingAll
                      ? '\u064a\u062a\u0645 \u062a\u0646\u0632\u064a\u0644 \u062c\u0645\u064a\u0639 \u0627\u0644\u062a\u0644\u0627\u0648\u0627\u062a'
                      : '\u062a\u0646\u0632\u064a\u0644 \u062c\u0645\u064a\u0639 \u0627\u0644\u062a\u0644\u0627\u0648\u0627\u062a'),
                  subtitle: downloads.isDownloadingAll
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: downloads.downloadAllExpectedBytes == 0
                                    ? null
                                    : downloads.downloadAllProgress,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                downloads.downloadAllExpectedBytes == 0
                                    ? 'جار تجهيز التنزيلات…'
                                    : 'يتم تنزيل ${downloads.downloadAllCompleted + 1} من ${downloads.downloadAllTotal} · ${(100 * (downloads.downloadAllProgress ?? 0)).round()}٪',
                              ),
                            ],
                          ),
                        )
                      : Text(
                          'حفظ جميع التلاوات للاستماع دون إنترنت · ${_formatBytes(downloads.downloadAllExpectedBytes)}',
                        ),
                  trailing: downloads.isDownloadingAll
                      ? Text('${(100 * (downloads.downloadAllProgress ?? 0)).round()}%')
                      : const Icon(Icons.chevron_left_rounded),
                  onTap: downloads.isDownloadingAll
                      ? null
                      : () => _confirmDownloadAll(
                            context,
                            downloads,
                            [...recitations.surahs, ...recitations.specialRecitations],
                          ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_rounded),
                  title: const Text('التحميل عبر Wi-Fi فقط'),
                  subtitle: const Text('عند إيقافه، يمكنك التحميل عبر أي شبكة.'),
                  value: downloads.wifiOnly,
                  onChanged: downloads.setWifiOnly,
                ),
                ListTile(
                  enabled: downloads.storageBytes > 0,
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('حذف كل التنزيلات'),
                  onTap: downloads.storageBytes == 0
                      ? null
                      : () => _confirmDeleteAll(context, downloads),
                ),
                if (downloads.error != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                    child: Text(
                      downloads.error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('عن الشيخ', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.softGold,
                      child: Icon(Icons.person_rounded, size: 42, color: AppColors.forestGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      AppStrings.reciterName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'يقدّم التطبيق تلاوات القارئ معاذ بن ماجد السريحي.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تتوفر الفاتحة والملك والإخلاص والفلق والناس داخل التطبيق للاستماع دون إنترنت. أما بقية التلاوات فتُبث عبر الإنترنت أو يمكنك تنزيل ما تريد للاستماع لاحقًا دون اتصال.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'التطبيق بدون إعلانات وبدون تتبع.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('عن التطبيق والخصوصية'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutPrivacyScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('${AppStrings.appName} · الإصدار 1.1.0', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmDownloadAll(
    BuildContext context,
    DownloadsProvider downloads,
    List<SurahModel> recitations,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u062a\u0646\u0632\u064a\u0644 \u062c\u0645\u064a\u0639 \u0627\u0644\u062a\u0644\u0627\u0648\u0627\u062a\u061f'),
        content: const Text(
          '\u0633\u064a\u0633\u062a\u062e\u062f\u0645 \u0647\u0630\u0627 \u0645\u0633\u0627\u062d\u0629 \u0645\u0646 \u0627\u0644\u062c\u0647\u0627\u0632\u060c \u0648\u064a\u0645\u0643\u0646 \u062d\u0630\u0641 \u0627\u0644\u062a\u0646\u0632\u064a\u0644\u0627\u062a \u0644\u0627\u062d\u0642\u064b\u0627.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\u0625\u0644\u063a\u0627\u0621'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\u062a\u0646\u0632\u064a\u0644'),
          ),
        ],
      ),
    );
    if (approved == true) {
      await downloads.downloadAll(recitations);
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, DownloadsProvider downloads) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف كل التنزيلات؟'),
        content: const Text('سيُحذف الصوت المحفوظ على هذا الجهاز فقط، ويمكن تنزيله لاحقًا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (approved == true) await downloads.deleteAll();
  }
}

