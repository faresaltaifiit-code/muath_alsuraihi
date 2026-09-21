import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/app_design_widgets.dart';
import '../../../widgets/mini_player.dart';
import '../../surahs/presentation/surahs_screen.dart';

class JuzScreen extends StatelessWidget {
  const JuzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final currentNumber = player.currentSurah?.number;
    final showMiniPlayer =
        player.currentSurah != null && player.hasPlaybackInSession;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    tooltip: '\u0631\u062c\u0648\u0639',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(height: 8),
                  Text('\u0627\u0644\u0623\u062c\u0632\u0627\u0621', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 2),
                  Text('30 \u062c\u0632\u0621\u064b\u0627 \u00b7 \u0628\u0623\u0633\u0645\u0627\u0626\u0647\u0627 \u0627\u0644\u0645\u0639\u0631\u0648\u0641\u0629', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
                  const SizedBox(height: 14),
                  _Shortcuts(onSelected: (number) => _openJuz(context, number)),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _juzNames.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final number = index + 1;
                        return _JuzRow(
                          number: number,
                          name: _juzNames[index],
                          range: _juzRanges[index],
                          nowPlaying: currentNumber != null && _contains(_juzRanges[index], currentNumber),
                          onTap: () => _openJuz(context, number),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (showMiniPlayer)
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
                child: MiniPlayer(),
              ),
          ],
        ),
      ),
    );
  }

  void _openJuz(BuildContext context, int number) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurahsScreen(juzNumber: number)));
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.onSelected});
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _shortcutNumbers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final number = _shortcutNumbers[index];
            return ActionChip(
              label: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  children: [
                    TextSpan(text: _juzNames[number - 1], style: const TextStyle(fontFamily: 'Amiri', fontSize: 19, fontWeight: FontWeight.w700)),
                    TextSpan(text: '  \u0627\u0644\u062c\u0632\u0621 $number', style: const TextStyle(fontSize: 11.5)),
                  ],
                ),
              ),
              onPressed: () => onSelected(number),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: const StadiumBorder(),
            );
          },
        ),
      );
}

class _JuzRow extends StatelessWidget {
  const _JuzRow({required this.number, required this.name, required this.range, required this.nowPlaying, required this.onTap});
  final int number;
  final String name;
  final (int, int) range;
  final bool nowPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = nowPlaying ? AppColors.darkText : theme.colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: nowPlaying ? null : theme.colorScheme.surface,
          gradient: nowPlaying ? const LinearGradient(colors: [AppColors.emerald, AppColors.forestGreen]) : null,
          border: nowPlaying ? null : Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
            child: Row(
              children: [
                StarNumberBadge(number: number, inverted: nowPlaying),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\u062c\u0632\u0621 $name', style: theme.textTheme.titleMedium?.copyWith(fontSize: 23, color: foreground)),
                      const SizedBox(height: 2),
                      Text(
                        nowPlaying ? '\u062a\u0633\u062a\u0645\u0639 \u0627\u0644\u0622\u0646 \u00b7 \u0627\u0644\u062c\u0632\u0621 $number' : '\u0627\u0644\u062c\u0632\u0621 $number \u00b7 \u0645\u0646 \u0627\u0644\u0633\u0648\u0631\u0629 ${range.$1} \u0625\u0644\u0649 ${range.$2}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: nowPlaying ? AppColors.darkText.withValues(alpha: .85) : null, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                if (nowPlaying) const _Equalizer() else Icon(Icons.chevron_left_rounded, color: theme.textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Equalizer extends StatefulWidget {
  const _Equalizer();
  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => SizedBox(
          width: 16,
          height: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [8.0, 16.0, 11.0].asMap().entries.map((entry) {
              final scale = .4 + ((entry.key + 1) * .16 + _controller.value).remainder(.6);
              return Container(width: 3, height: entry.value * scale, decoration: BoxDecoration(color: AppColors.softGold, borderRadius: BorderRadius.circular(2)));
            }).toList(),
          ),
        ),
      );
}

bool _contains((int, int) range, int surahNumber) => surahNumber >= range.$1 && surahNumber <= range.$2;
const _shortcutNumbers = [30, 29, 28, 1];
const _juzNames = [
  '\u0627\u0644\u0645', '\u0633\u064a\u0642\u0648\u0644', '\u062a\u0644\u0643 \u0627\u0644\u0631\u0633\u0644', '\u0644\u0646 \u062a\u0646\u0627\u0644\u0648\u0627', '\u0648\u0627\u0644\u0645\u062d\u0635\u0646\u0627\u062a',
  '\u0644\u0627 \u064a\u062d\u0628 \u0627\u0644\u0644\u0647', '\u0648\u0625\u0630\u0627 \u0633\u0645\u0639\u0648\u0627', '\u0648\u0644\u0648 \u0623\u0646\u0646\u0627', '\u0642\u0627\u0644 \u0627\u0644\u0645\u0644\u0623', '\u0648\u0627\u0639\u0644\u0645\u0648\u0627',
  '\u064a\u0639\u062a\u0630\u0631\u0648\u0646', '\u0648\u0645\u0627 \u0645\u0646 \u062f\u0627\u0628\u0629', '\u0648\u0645\u0627 \u0623\u0628\u0631\u0626', '\u0631\u0628\u0645\u0627', '\u0633\u0628\u062d\u0627\u0646 \u0627\u0644\u0630\u064a',
  '\u0642\u0627\u0644 \u0623\u0644\u0645', '\u0627\u0642\u062a\u0631\u0628', '\u0642\u062f \u0623\u0641\u0644\u062d', '\u0648\u0642\u0627\u0644 \u0627\u0644\u0630\u064a\u0646', '\u0623\u0645\u0646 \u062e\u0644\u0642',
  '\u0627\u062a\u0644 \u0645\u0627 \u0623\u0648\u062d\u064a', '\u0648\u0645\u0646 \u064a\u0642\u0646\u062a', '\u0648\u0645\u0627 \u0644\u064a', '\u0641\u0645\u0646 \u0623\u0638\u0644\u0645', '\u0625\u0644\u064a\u0647 \u064a\u0631\u062f',
  '\u062d\u0645', '\u0642\u0627\u0644 \u0641\u0645\u0627 \u062e\u0637\u0628\u0643\u0645', '\u0642\u062f \u0633\u0645\u0639', '\u062a\u0628\u0627\u0631\u0643', '\u0639\u0645\u0651',
];
const _juzRanges = <(int, int)>[
  (1, 2), (2, 3), (3, 4), (4, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 9),
  (9, 11), (11, 12), (12, 15), (15, 16), (17, 18), (18, 20), (21, 22), (23, 25), (25, 27), (27, 29),
  (29, 33), (33, 36), (36, 39), (39, 41), (41, 45), (46, 51), (51, 57), (58, 66), (67, 77), (78, 114),
];
