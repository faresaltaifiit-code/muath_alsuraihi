import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class StarNumberBadge extends StatelessWidget {
  const StarNumberBadge({super.key, required this.number, this.size = 46, this.inverted = false});

  final int number;
  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _EightPointStarPainter(
          color: inverted
              ? Colors.white.withValues(alpha: .18)
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSecondarySurface
                  : AppColors.lightSecondarySurface,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: inverted ? AppColors.softGold : AppColors.goldAccent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      );
}

class TintedIconTile extends StatelessWidget {
  const TintedIconTile({super.key, required this.icon, required this.color, this.size = 46});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: .22), borderRadius: BorderRadius.circular(size * .33)),
        child: Icon(icon, color: color, size: size * .56),
      );
}

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({super.key, required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.forestGreen : Theme.of(context).colorScheme.surface,
              border: Border.all(color: selected ? AppColors.forestGreen : Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.darkText : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
          ),
        ),
      );
}

class _EightPointStarPainter extends CustomPainter {
  const _EightPointStarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer * .7;
    final path = Path();
    for (var index = 0; index < 16; index++) {
      final radius = index.isEven ? outer : inner;
      final angle = -math.pi / 2 + index * math.pi / 8;
      final point = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      index == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EightPointStarPainter oldDelegate) => oldDelegate.color != color;
}
