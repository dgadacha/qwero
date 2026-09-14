import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Logo : couronne violette + mot-marque (§93).
class QuestLogo extends StatelessWidget {
  const QuestLogo({super.key, this.size = 44, this.showCrown = true, this.color});

  final double size;
  final bool showCrown;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCrown) ...[
          Crown(size: size * 0.62),
          SizedBox(height: size * 0.16),
        ],
        Text(
          'QUEST',
          style: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: size,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -size * 0.02,
            color: color ?? AppColors.textPrimary,
            shadows: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: size * 0.6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La couronne, qui sert aussi d'icône d'application (§117).
class Crown extends StatelessWidget {
  const Crown({super.key, this.size = 28, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.78,
      child: CustomPaint(painter: _CrownPainter(color)),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.22)
      ..lineTo(w * 0.26, h * 0.6)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.74, h * 0.6)
      ..lineTo(w, h * 0.22)
      ..lineTo(w * 0.87, h)
      ..lineTo(w * 0.13, h)
      ..close();

    final paint = Paint()
      ..shader = (color == null
          ? AppColors.primaryGradient.createShader(Offset.zero & size)
          : null)
      ..color = color ?? AppColors.primary;

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.22),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}
