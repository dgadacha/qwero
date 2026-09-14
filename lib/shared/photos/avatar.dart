import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Avatar généré à partir de l'identifiant : dégradé stable et initiales.
/// Évite d'embarquer des portraits dans un prototype.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.seed,
    required this.name,
    this.size = 40,
    this.ring = false,
    this.ringColor,
    this.ringWidth = 2,
  });

  final String seed;
  final String name;
  final double size;
  final bool ring;
  final Color? ringColor;
  final double ringWidth;

  static const _palettes = <List<Color>>[
    [Color(0xFF7357FF), Color(0xFF4B2FC9)],
    [Color(0xFF2DD4A8), Color(0xFF128E77)],
    [Color(0xFFF5C84C), Color(0xFFD08A1E)],
    [Color(0xFFFF5368), Color(0xFFB82A48)],
    [Color(0xFF4CA8F5), Color(0xFF1F63B8)],
    [Color(0xFFFF8A3D), Color(0xFFC1471C)],
    [Color(0xFFB07CD8), Color(0xFF6A3D9C)],
    [Color(0xFF5DE2B3), Color(0xFF1E8F79)],
  ];

  List<Color> get _palette {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palettes[hash % _palettes.length];
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palette;
    final avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: CustomPaint(
        painter: _AvatarTexture(seed.hashCode),
        child: Center(
          child: Text(
            _initials,
            style: TextStyle(
              fontFamily: AppTypography.family,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ),
      ),
    );

    if (!ring) return avatar;

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor ?? AppColors.primary,
          width: ringWidth,
        ),
        boxShadow: AppShadows.glow(ringColor ?? AppColors.primary, opacity: 0.35, blur: 18),
      ),
      child: avatar,
    );
  }
}

/// Reflets discrets, pour que l'avatar ne soit pas un aplat.
class _AvatarTexture extends CustomPainter {
  const _AvatarTexture(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.26),
      size.width * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    for (var i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(size.width * rnd.nextDouble(), size.height * (0.55 + rnd.nextDouble() * 0.5)),
        size.width * (0.18 + rnd.nextDouble() * 0.2),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(_AvatarTexture old) => old.seed != seed;
}
