import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/downloads_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final downloads = context.watch<DownloadsProvider>();
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
                  Center(child: Text('الشيخ معاذ بن ماجد السريحي', style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 14),
                  Text(
                    'هذا التطبيق يقدّم المصحف المرتل للشيخ معاذ بن ماجد السريحي، تسجيلات رمضان 1446هـ.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'التلاوات محفوظة داخل التطبيق وتعمل دون اتصال بالإنترنت. يمكنك حفظ المفضلة والاستماع في الخلفية وشاشة القفل.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(child: Text('${AppStrings.appName} · الإصدار 1.1.0', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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

