import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/app_design_widgets.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.surah});
  final SurahModel surah;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  Duration? _dragPosition;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<PlayerProvider>();
      if (player.currentSurah?.audioPath != widget.surah.audioPath) {
        player.prepareSurah(widget.surah, autoplay: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final downloads = context.watch<DownloadsProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final surah = player.currentSurah ?? widget.surah;
    final duration = player.duration > Duration.zero
        ? player.duration
        : Duration(seconds: surah.durationSeconds);
    final livePosition = player.position > duration ? duration : player.position;
    final position = _dragPosition ?? livePosition;
    final remaining = duration > position ? duration - position : Duration.zero;
    final animationsAllowed = !MediaQuery.disableAnimationsOf(context);
    final shouldPulse = player.isPlaying && animationsAllowed;
    _syncPulse(shouldPulse);
    final isDownloaded = surah.isBundled || downloads.isDownloaded(surah);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artworkSize = math.min(250.0, math.max(190.0, constraints.maxHeight * .31));
            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 32),
              child: Column(
                children: [
                  _TopBar(
                    favorite: favorites.contains(surah),
                    onDismiss: () => Navigator.of(context).maybePop(),
                    onFavorite: () => favorites.toggle(surah),
                  ),
                  const SizedBox(height: 18),
                  _Artwork(
                    number: surah.number,
                    size: artworkSize,
                    pulse: _pulseController,
                    animate: shouldPulse,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    surah.number > 0 ? 'سورة ${surah.name}' : surah.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontFamily: 'Amiri',
                          fontSize: 38,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kReciterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (isDownloaded) ...[
                    const SizedBox(height: 10),
                    const _DownloadedChip(),
                  ],
                  if (player.error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      player.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: player.retryCurrent,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ProgressControl(
                    position: position,
                    duration: duration,
                    remaining: remaining,
                    onStart: duration > Duration.zero
                        ? (value) => setState(
                              () => _dragPosition = Duration(milliseconds: value.round()),
                            )
                        : null,
                    onChanged: duration > Duration.zero
                        ? (value) => setState(
                              () => _dragPosition = Duration(milliseconds: value.round()),
                            )
                        : null,
                    onEnd: duration > Duration.zero
                        ? (value) async {
                            final target = Duration(milliseconds: value.round());
                            setState(() => _dragPosition = null);
                            await player.seek(target);
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _TransportControls(player: player),
                  const SizedBox(height: 22),
                  _OptionsGrid(
                    player: player,
                    onSpeed: () => _chooseSpeed(context, player),
                    onSleep: () => _chooseSleepTimer(context, player),
                    onShare: () => Share.share(
                      'استمع إلى سورة ${surah.name} بصوت $kReciterName عبر تطبيق معاذ السريحي',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncPulse(bool shouldPulse) {
    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  Future<void> _chooseSpeed(BuildContext context, PlayerProvider player) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) => _OptionsSheet(
        title: 'سرعة القراءة',
        options: const [0.75, 1.0, 1.25, 1.5],
        label: (value) => '×$value',
      ),
    );
    if (result != null) await player.changeSpeed(result);
  }

  Future<void> _chooseSleepTimer(BuildContext context, PlayerProvider player) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _OptionsSheet(
        title: 'إيقاف التشغيل بعد',
        options: const [5, 10, 15, 30, 45, 60],
        label: (value) => '$value دقيقة',
      ),
    );
    if (result != null) player.setSleepTimer(Duration(minutes: result));
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.favorite, required this.onDismiss, required this.onFavorite});
  final bool favorite;
  final VoidCallback onDismiss;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              tooltip: 'إغلاق المشغل',
              onPressed: onDismiss,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            ),
            const Expanded(
              child: Center(child: Text('قيد التشغيل', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ),
            IconButton(
              tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              onPressed: onFavorite,
              color: favorite ? AppColors.favoriteRed : null,
              icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 24),
            ),
          ],
        ),
      );
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.number,
    required this.size,
    required this.pulse,
    required this.animate,
  });

  final int number;
  final double size;
  final Animation<double> pulse;
  final bool animate;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size + 52,
        height: size + 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 52,
              height: size + 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.emerald.withValues(alpha: .35), Colors.transparent],
                ),
              ),
            ),
            if (animate) ...[
              _PulseRing(animation: pulse),
              _PulseRing(animation: CurvedAnimation(parent: pulse, curve: const Interval(.5, 1))),
            ],
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.emerald, AppColors.forestGreen],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: .35),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(child: _ArtworkPattern()),
                  StarNumberBadge(
                    number: number,
                    size: math.min(132, size * .53),
                    inverted: true,
                    numberFontFamily: 'Amiri',
                    numberFontSize: math.min(54, size * .22),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ArtworkPattern extends StatelessWidget {
  const _ArtworkPattern();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: .16,
          child: CustomPaint(painter: _ArtworkPatternPainter()),
        ),
      );
}

class _ArtworkPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (final factor in [.48, .32, .18]) {
      canvas.drawCircle(center, size.width * factor, paint);
    }
    final path = Path();
    for (var index = 0; index < 16; index++) {
      final angle = -math.pi / 2 + index * math.pi / 8;
      final radius = size.width * (index.isEven ? .49 : .32);
      final point = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final value = animation.value;
          return Transform.scale(
            scale: .94 + (.20 * value),
            child: Opacity(
              opacity: (.5 * (1 - value)).clamp(0.0, .5),
              child: Container(
                width: 264,
                height: 264,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldAccent),
                ),
              ),
            ),
          );
        },
      );
}

class _DownloadedChip extends StatelessWidget {
  const _DownloadedChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: AppColors.emerald),
            SizedBox(width: 6),
            Text('محمّلة · تعمل بدون إنترنت', style: TextStyle(fontSize: 12.5, color: AppColors.emerald)),
          ],
        ),
      );
}

class _ProgressControl extends StatelessWidget {
  const _ProgressControl({
    required this.position,
    required this.duration,
    required this.remaining,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
  });

  final Duration position;
  final Duration duration;
  final Duration remaining;
  final ValueChanged<double>? onStart;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onEnd;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: AppColors.goldAccent,
                inactiveTrackColor: Theme.of(context).dividerColor,
                thumbColor: AppColors.softGold,
                overlayColor: AppColors.goldAccent.withValues(alpha: .12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                onChangeStart: onStart,
                onChanged: onChanged,
                onChangeEnd: onEnd,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TimeText(_format(position)),
                  _TimeText('-${_format(remaining)}'),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TimeText extends StatelessWidget {
  const _TimeText(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      );
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TransportButton(
              label: 'رجوع 10 ثوانٍ',
              icon: Icons.replay_10_rounded,
              onPressed: () => player.skipBy(const Duration(seconds: -10)),
              iconSize: 34,
            ),
            _TransportButton(
              label: 'السورة السابقة',
              icon: Icons.skip_previous_rounded,
              onPressed: player.previous,
              iconSize: 32,
            ),
            _PlayButton(
              playing: player.isPlaying,
              onPressed: player.isReady ? player.togglePlayPause : null,
            ),
            _TransportButton(
              label: 'السورة التالية',
              icon: Icons.skip_next_rounded,
              onPressed: player.next,
              iconSize: 32,
            ),
            _TransportButton(
              label: 'تقديم 10 ثوانٍ',
              icon: Icons.forward_10_rounded,
              onPressed: () => player.skipBy(const Duration(seconds: 10)),
              iconSize: 34,
            ),
          ],
        ),
      );
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.iconSize,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: label,
        onPressed: onPressed,
        iconSize: iconSize,
        constraints: const BoxConstraints.tightFor(width: 52, height: 52),
        icon: Icon(icon),
      );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onPressed});
  final bool playing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: playing ? 'إيقاف مؤقت' : 'تشغيل',
        child: Ink(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.softGold, Color(0xFFD8BE86)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldAccent.withValues(alpha: .35),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            tooltip: playing ? 'إيقاف مؤقت' : 'تشغيل',
            onPressed: onPressed,
            color: const Color(0xFF0F3A2E),
            iconSize: 40,
            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ),
      );
}

class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({
    required this.player,
    required this.onSpeed,
    required this.onSleep,
    required this.onShare,
  });
  final PlayerProvider player;
  final VoidCallback onSpeed;
  final VoidCallback onSleep;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 74,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _OptionTile(
            label: 'عشوائي',
            icon: Icons.shuffle_rounded,
            enabled: player.shuffleEnabled,
            onTap: player.toggleShuffle,
          ),
          _OptionTile(
            label: 'تكرار السورة',
            icon: player.repeatMode == AudioServiceRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            enabled: player.repeatMode != AudioServiceRepeatMode.none,
            onTap: player.cycleRepeatMode,
          ),
          _OptionTile(
            label: 'تشغيل التالي',
            icon: Icons.playlist_play_rounded,
            enabled: player.autoPlayNext,
            onTap: () => player.setAutoPlayNext(!player.autoPlayNext),
          ),
          _OptionTile(
            label: 'السرعة ×${player.speed.toStringAsFixed(player.speed == player.speed.roundToDouble() ? 0 : 2)}',
            icon: Icons.speed_rounded,
            onTap: onSpeed,
          ),
          _OptionTile(
            label: player.hasSleepTimer ? 'مؤقت النوم ✓' : 'مؤقت النوم',
            icon: player.hasSleepTimer ? Icons.bedtime_rounded : Icons.bedtime_outlined,
            enabled: player.hasSleepTimer,
            onTap: onSleep,
          ),
          _OptionTile(
            label: 'مشاركة',
            icon: Icons.share_outlined,
            onTap: onShare,
          ),
        ],
      );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.goldAccent.withValues(alpha: .18)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled ? AppColors.goldAccent : Theme.of(context).dividerColor,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: enabled
                        ? AppColors.goldAccent
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _OptionsSheet<T> extends StatelessWidget {
  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.label,
  });
  final String title;
  final List<T> options;
  final String Function(T value) label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...options.map(
              (value) => ListTile(
                title: Text(label(value)),
                onTap: () => Navigator.pop(context, value),
              ),
            ),
          ],
        ),
      );
}

String _format(Duration duration) {
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return duration.inHours > 0
      ? '${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:$seconds'
      : '${duration.inMinutes}:$seconds';
}
