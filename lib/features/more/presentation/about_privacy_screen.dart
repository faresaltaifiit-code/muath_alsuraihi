import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

const kRecitationsRightsText =
    'التلاوات للقارئ معاذ بن ماجد السريحي، وتُقدَّم كما هي بجودتها الأصلية دون تعديل أو ضغط.';

class AboutPrivacyScreen extends StatelessWidget {
  const AboutPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('عن التطبيق والخصوصية')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.emerald,
                child: Icon(Icons.menu_book_rounded, size: 40, color: AppColors.softGold),
              ),
            ),
            const SizedBox(height: 14),
            Text('قرآن وتلاوات', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('تلاوات $kReciterName · الإصدار 1.1.1', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'خصوصيتك',
              child: const Column(
                children: [
                  _CheckRow('بدون إعلانات'),
                  _CheckRow('بدون تتبع أو تحليلات'),
                  _CheckRow('بدون حسابات أو اشتراكات'),
                  _CheckRow('لا نجمع أي بيانات عنك'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'حقوق التلاوات',
              child: const Text(kRecitationsRightsText, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ]),
      );
}
