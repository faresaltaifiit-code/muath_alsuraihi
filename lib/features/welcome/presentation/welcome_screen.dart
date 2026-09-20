import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../navigation/presentation/root_navigation_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _pages = <_WelcomePageData>[
    _WelcomePageData(
      icon: Icons.menu_book_rounded,
      line: '\u0628\u0633\u0645 \u0627\u0644\u0644\u0647 \u0627\u0644\u0631\u062d\u0645\u0646 \u0627\u0644\u0631\u062d\u064a\u0645',
      title: '\u0623\u0647\u0644\u064b\u0627 \u0628\u0643',
      body: '\u062a\u0644\u0627\u0648\u0627\u062a \u0627\u0644\u0634\u064a\u062e \u0645\u0639\u0627\u0630 \u0628\u0646 \u0645\u0627\u062c\u062f \u0627\u0644\u0633\u0631\u064a\u062d\u064a \u0628\u062c\u0648\u062f\u062a\u0647\u0627 \u0627\u0644\u0623\u0635\u0644\u064a\u0629\u060c \u0641\u064a \u0645\u0643\u0627\u0646 \u0648\u0627\u062d\u062f.',
    ),
    _WelcomePageData(
      icon: Icons.verified_user_rounded,
      title: '\u0645\u062c\u0627\u0646\u064a \u0628\u0627\u0644\u0643\u0627\u0645\u0644',
      body: '\u0628\u062f\u0648\u0646 \u0625\u0639\u0644\u0627\u0646\u0627\u062a\u060c \u0648\u0628\u062f\u0648\u0646 \u062a\u062a\u0628\u0639\u060c \u0648\u0628\u062f\u0648\u0646 \u0627\u0634\u062a\u0631\u0627\u0643\u0627\u062a.',
    ),
    _WelcomePageData(
      icon: Icons.download_for_offline_rounded,
      title: '\u0627\u0633\u062a\u0645\u0639 \u0641\u064a \u0623\u064a \u0648\u0642\u062a',
      body: '\u062d\u0645\u0651\u0644 \u0627\u0644\u0633\u0648\u0631 \u0648\u0627\u0633\u062a\u0645\u0639 \u0628\u062f\u0648\u0646 \u0625\u0646\u062a\u0631\u0646\u062a\u060c \u0648\u064a\u0643\u0645\u0644 \u0627\u0644\u062a\u0634\u063a\u064a\u0644 \u0645\u0646 \u062d\u064a\u062b \u062a\u0648\u0642\u0641\u062a.',
    ),
  ];

  Future<void> _finish() async {
    await context.read<SettingsProvider>().completeWelcome();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RootNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: isLast
                    ? const SizedBox(height: 48)
                    : TextButton(
                        onPressed: _finish,
                        child: const Text('\u062a\u062e\u0637\u064e\u0651'),
                      ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) => _WelcomePage(
                    data: _pages[index],
                    animate: !reduceMotion && index == _page,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) => AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                  width: index == _page ? 26 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page ? AppColors.goldAccent : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                )),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: isLast
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                  icon: Icon(isLast ? Icons.play_arrow_rounded : Icons.arrow_back_rounded),
                  label: Text(isLast
                      ? '\u0627\u0628\u062f\u0623 \u0627\u0644\u0627\u0633\u062a\u0645\u0627\u0639'
                      : '\u0627\u0644\u062a\u0627\u0644\u064a'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.data, required this.animate});
  final _WelcomePageData data;
  final bool animate;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${data.title}. ${data.body}',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: animate ? 1 : .96,
              duration: const Duration(milliseconds: 450),
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.emerald, AppColors.forestGreen]),
                ),
                child: Icon(data.icon, size: 64, color: AppColors.softGold),
              ),
            ),
            const SizedBox(height: 46),
            if (data.line != null) ...[
              Text(data.line!, style: const TextStyle(color: AppColors.goldAccent, fontSize: 20, fontFamily: 'Amiri')),
              const SizedBox(height: 12),
            ],
            Text(data.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 14),
            Text(data.body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
          ],
        ),
      );
}

class _WelcomePageData {
  const _WelcomePageData({required this.icon, this.line, required this.title, required this.body});
  final IconData icon;
  final String? line;
  final String title;
  final String body;
}
