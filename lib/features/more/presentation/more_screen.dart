import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/settings_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
}

