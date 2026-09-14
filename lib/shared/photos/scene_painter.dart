import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'scene_recipe.dart';

/// Dessine une scène à partir de sa recette : ciel, astre, nuages, reliefs,
/// eau, sujets, puis grain et vignettage.
class ScenePainter extends CustomPainter {
  const ScenePainter(this.recipe, {this.parallax = 0});

  final SceneRecipe recipe;

  /// Léger décalage horizontal des plans, utilisé par les écrans immersifs.
  final double parallax;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);

    _paintSky(canvas, size);
    if (recipe.stars > 0) _paintStars(canvas, size);
    final sun = recipe.sun;
    if (sun != null) _paintSun(canvas, size, sun);
    for (final cloud in recipe.clouds) {
      _paintCloud(canvas, size, cloud);
    }
    for (var i = 0; i < recipe.ridges.length; i++) {
      _paintRidge(canvas, size, recipe.ridges[i], i);
    }
    final ground = recipe.groundColor;
    final groundTop = recipe.groundTop;
    if (ground != null && groundTop != null) {
      _paintGround(canvas, size, ground, groundTop);
    }
    final water = recipe.water;
    if (water != null) _paintWater(canvas, size, water, sun);
    for (final subject in recipe.subjects) {
      _paintSubject(canvas, size, subject);
    }
    final haze = recipe.haze;
    if (haze != null) _paintHaze(canvas, size, haze);
    if (recipe.vignette > 0) _paintVignette(canvas, size);
    if (recipe.grain > 0) _paintGrain(canvas, size);

    canvas.restore();
  }

  double _dx(Size size, double depth) => parallax * size.width * depth;

  void _paintSky(Canvas canvas, Size size) {
    final colors = [...recipe.sky];
    final stops = recipe.skyStops;
    // Le bas du ciel se referme toujours sur une valeur sombre : la scène doit
    // rester lisible sous le texte blanc posé par-dessus.
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _paintStars(Canvas canvas, Size size) {
    final rnd = math.Random(recipe.stars * 7919);
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < recipe.stars; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.62;
      final r = rnd.nextDouble() * 0.8 + 0.35;
      final fade = 1 - (y / (size.height * 0.62));
      paint.color = Colors.white.withValues(alpha: (0.3 + 0.7 * fade * rnd.nextDouble()).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintSun(Canvas canvas, Size size, SunSpec sun) {
    final center = Offset(sun.x * size.width + _dx(size, 0.1), sun.y * size.height);
    final radius = sun.radius * size.shortestSide;
    final haloRadius = radius * sun.haloScale;

    canvas.drawCircle(
      center,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            sun.halo.withValues(alpha: 0.55),
            sun.halo.withValues(alpha: 0.18),
            sun.halo.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
    );
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()..color = sun.core.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6),
    );
    canvas.drawCircle(center, radius, Paint()..color = sun.core);
    // Cœur surexposé : sans lui, le disque se confond avec le ciel quand la
    // scène est fortement assombrie par l'écran qui l'accueille.
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..color = Color.lerp(sun.core, Colors.white, 0.75)!
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35),
    );
  }

  void _paintCloud(Canvas canvas, Size size, CloudSpec cloud) {
    final w = cloud.width * size.width;
    final h = cloud.height * size.height;
    final center = Offset(cloud.x * size.width + _dx(size, 0.18), cloud.y * size.height);
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawOval(
      rect,
      Paint()
        ..color = cloud.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.75),
    );
    // Une seconde nappe plus fine casse l'aspect « ovale parfait ».
    canvas.drawOval(
      rect.translate(w * 0.12, -h * 0.35).deflate(w * 0.12),
      Paint()
        ..color = cloud.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.6),
    );
  }

  void _paintRidge(Canvas canvas, Size size, RidgeSpec ridge, int index) {
    final path = switch (ridge.style) {
      RidgeStyle.skyline => _skylinePath(size, ridge, index),
      RidgeStyle.treeline => _treelinePath(size, ridge, index),
      RidgeStyle.dune => _dunePath(size, ridge, index),
      RidgeStyle.hill => _hillPath(size, ridge, index),
      RidgeStyle.mountain => _mountainPath(size, ridge, index),
    };

    final top = ridge.top * size.height;
    final bottom = ridge.baseline * size.height;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(ridge.color, Colors.white, 0.1)!,
            ridge.color,
            Color.lerp(ridge.color, Colors.black, 0.35)!,
          ],
        ).createShader(Rect.fromLTRB(0, top, size.width, math.max(bottom, top + 1))),
    );
  }

  Path _mountainPath(Size size, RidgeSpec ridge, int index) {
    final rnd = math.Random(ridge.seed);
    final baseline = ridge.baseline * size.height;
    final top = ridge.top * size.height;
    final span = size.width / ridge.peaks;
    final shift = _dx(size, 0.3 + index * 0.12);

    final path = Path()..moveTo(-span + shift, baseline);
    var x = -span * 0.5 + shift;
    while (x < size.width + span) {
      final peakY = top + (baseline - top) * ridge.jitter * rnd.nextDouble();
      final valleyY = baseline - (baseline - top) * 0.12 * rnd.nextDouble();
      path.lineTo(x, peakY);
      path.lineTo(x + span * (0.45 + rnd.nextDouble() * 0.3), valleyY);
      x += span * (0.85 + rnd.nextDouble() * 0.3);
    }
    path
      ..lineTo(size.width + span, baseline)
      ..lineTo(size.width + span, size.height)
      ..lineTo(-span, size.height)
      ..close();
    return path;
  }

  Path _hillPath(Size size, RidgeSpec ridge, int index) {
    final rnd = math.Random(ridge.seed);
    final baseline = ridge.baseline * size.height;
    final top = ridge.top * size.height;
    final shift = _dx(size, 0.25 + index * 0.1);
    final path = Path()..moveTo(-size.width * 0.1 + shift, baseline);
    final steps = ridge.peaks * 2;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = -size.width * 0.1 + shift + t * size.width * 1.2;
      final wave = math.sin(t * math.pi * ridge.peaks + rnd.nextDouble());
      final y = top + (baseline - top) * (0.5 - 0.5 * wave) * ridge.jitter * 2;
      path.lineTo(x, y.clamp(top, baseline));
    }
    path
      ..lineTo(size.width * 1.2, size.height)
      ..lineTo(-size.width * 0.1, size.height)
      ..close();
    return path;
  }

  Path _dunePath(Size size, RidgeSpec ridge, int index) {
    final baseline = ridge.baseline * size.height;
    final top = ridge.top * size.height;
    final shift = _dx(size, 0.2 + index * 0.15);
    final path = Path()..moveTo(-size.width * 0.2 + shift, baseline);
    path.cubicTo(
      size.width * 0.2 + shift, top,
      size.width * 0.55 + shift, top + (baseline - top) * 0.2,
      size.width * 1.2 + shift, baseline * 0.96,
    );
    path
      ..lineTo(size.width * 1.2, size.height)
      ..lineTo(-size.width * 0.2, size.height)
      ..close();
    return path;
  }

  Path _skylinePath(Size size, RidgeSpec ridge, int index) {
    final rnd = math.Random(ridge.seed);
    final baseline = ridge.baseline * size.height;
    final top = ridge.top * size.height;
    final shift = _dx(size, 0.22 + index * 0.1);
    final path = Path()..moveTo(-size.width * 0.1 + shift, baseline);
    var x = -size.width * 0.1 + shift;
    while (x < size.width * 1.15) {
      final w = size.width * (0.05 + rnd.nextDouble() * 0.09);
      final h = (baseline - top) * (0.35 + rnd.nextDouble() * 0.65);
      final y = baseline - h;
      path
        ..lineTo(x, y)
        ..lineTo(x + w, y);
      // Antenne ou toit en pointe de temps en temps.
      if (rnd.nextDouble() > 0.75) {
        path
          ..lineTo(x + w, y - h * 0.22)
          ..lineTo(x + w + 1.5, y - h * 0.22)
          ..lineTo(x + w + 1.5, y);
      }
      x += w;
    }
    path
      ..lineTo(size.width * 1.15, baseline)
      ..lineTo(size.width * 1.15, size.height)
      ..lineTo(-size.width * 0.1, size.height)
      ..close();
    return path;
  }

  Path _treelinePath(Size size, RidgeSpec ridge, int index) {
    final rnd = math.Random(ridge.seed);
    final baseline = ridge.baseline * size.height;
    final top = ridge.top * size.height;
    final shift = _dx(size, 0.3 + index * 0.14);
    final path = Path()..moveTo(-size.width * 0.1 + shift, baseline);
    var x = -size.width * 0.1 + shift;
    final step = size.width / (ridge.peaks * 2.2);
    while (x < size.width * 1.15) {
      final h = (baseline - top) * (0.55 + rnd.nextDouble() * 0.45);
      // Un sapin : deux épaulements avant la pointe, sinon la ligne d'arbres
      // ressemble à des brins d'herbe.
      path
        ..lineTo(x + step * 0.18, baseline - h * 0.34)
        ..lineTo(x + step * 0.34, baseline - h * 0.4)
        ..lineTo(x + step * 0.5, baseline - h)
        ..lineTo(x + step * 0.66, baseline - h * 0.4)
        ..lineTo(x + step * 0.82, baseline - h * 0.34)
        ..lineTo(x + step, baseline - h * 0.12);
      x += step;
    }
    path
      ..lineTo(size.width * 1.15, baseline)
      ..lineTo(size.width * 1.15, size.height)
      ..lineTo(-size.width * 0.1, size.height)
      ..close();
    return path;
  }

  void _paintGround(Canvas canvas, Size size, Color color, double topRatio) {
    final top = topRatio * size.height;
    final rect = Rect.fromLTRB(0, top, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.12)!, color, Color.lerp(color, Colors.black, 0.4)!],
        ).createShader(rect),
    );
  }

  void _paintWater(Canvas canvas, Size size, WaterSpec water, SunSpec? sun) {
    final top = water.top * size.height;
    final rect = Rect.fromLTRB(0, top, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: water.colors,
        ).createShader(rect),
    );

    if (water.sunTrail && sun != null) {
      // Traînée lumineuse : une ellipse très étirée, dont l'intensité décroît
      // dans les deux axes — un rectangle dégradé laisserait des bords nets.
      final x = sun.x * size.width + _dx(size, 0.1);
      final trail = Rect.fromLTRB(
        x - size.width * 0.2,
        top - (size.height - top) * 0.1,
        x + size.width * 0.2,
        size.height + (size.height - top) * 0.5,
      );
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawOval(
        trail,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sun.core.withValues(alpha: 0.42),
              sun.halo.withValues(alpha: 0.16),
              sun.halo.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(trail)
          ..blendMode = BlendMode.plus,
      );
      canvas.restore();
    }

    if (water.sparkle) {
      final rnd = math.Random(water.colors.length * 104729);
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.16);
      for (var i = 0; i < 60; i++) {
        final t = rnd.nextDouble();
        final y = top + t * (size.height - top);
        final w = size.width * (0.02 + rnd.nextDouble() * 0.16) * (0.4 + t);
        final x = rnd.nextDouble() * size.width;
        paint.color = Colors.white.withValues(alpha: 0.04 + 0.14 * rnd.nextDouble() * (1 - t));
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 1.2 + t * 1.6), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  void _paintSubject(Canvas canvas, Size size, SubjectSpec spec) {
    final path = subjectPath(spec.subject, size, spec);
    if (path == null) return;
    final color = spec.color ?? const Color(0xFF0B0F18);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintHaze(Canvas canvas, Size size, Color haze) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [haze, haze.withValues(alpha: 0)],
        ).createShader(Offset.zero & size)
        ..blendMode = BlendMode.plus,
    );
  }

  void _paintVignette(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            const Color(0x00000000),
            Colors.black.withValues(alpha: recipe.vignette * 0.5),
            Colors.black.withValues(alpha: recipe.vignette),
          ],
          stops: const [0.45, 0.8, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintGrain(Canvas canvas, Size size) {
    final rnd = math.Random(1337);
    final paint = Paint();
    final count = (size.width * size.height / 420).clamp(60, 900).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final bright = rnd.nextBool();
      paint.color = (bright ? Colors.white : Colors.black)
          .withValues(alpha: recipe.grain * rnd.nextDouble());
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.recipe != recipe || old.parallax != parallax;
}

/// Silhouettes d'avant-plan. Volontairement simples : lues en contre-jour,
/// elles se reconnaissent à leur contour.
Path? subjectPath(Subject subject, Size size, SubjectSpec spec) {
  final s = size.shortestSide * 0.28 * spec.scale;
  final cx = spec.x * size.width;
  final by = spec.baseline * size.height;
  final path = Path();

  switch (subject) {
    case Subject.none:
      return null;

    case Subject.hiker:
      final h = s * 0.9;
      final w = h * 0.28;
      // Jambes
      path
        ..moveTo(cx - w * 0.5, by)
        ..lineTo(cx - w * 0.1, by - h * 0.45)
        ..lineTo(cx + w * 0.25, by)
        ..lineTo(cx + w * 0.55, by)
        ..lineTo(cx + w * 0.2, by - h * 0.5)
        ..lineTo(cx + w * 0.2, by - h * 0.72)
        ..close();
      // Buste + sac
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.55, by - h * 0.78, w * 1.0, h * 0.36),
          Radius.circular(w * 0.28),
        ),
      );
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.95, by - h * 0.74, w * 0.55, h * 0.3),
          Radius.circular(w * 0.22),
        ),
      );
      // Tête
      path.addOval(Rect.fromCircle(center: Offset(cx, by - h * 0.88), radius: w * 0.32));
      return path;

    case Subject.person:
      final h = s * 0.8;
      final w = h * 0.24;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.5, by - h * 0.62, w, h * 0.62),
          Radius.circular(w * 0.4),
        ),
      );
      path.addOval(Rect.fromCircle(center: Offset(cx, by - h * 0.74), radius: w * 0.34));
      return path;

    case Subject.car:
      final w = s * 1.5;
      final h = w * 0.36;
      final body = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - w / 2, by - h * 0.62, w, h * 0.62),
        topLeft: Radius.circular(h * 0.22),
        topRight: Radius.circular(h * 0.22),
        bottomLeft: Radius.circular(h * 0.3),
        bottomRight: Radius.circular(h * 0.3),
      );
      path.addRRect(body);
      // Pavillon
      final roof = Path()
        ..moveTo(cx - w * 0.26, by - h * 0.6)
        ..quadraticBezierTo(cx - w * 0.16, by - h * 1.02, cx + w * 0.04, by - h * 1.02)
        ..quadraticBezierTo(cx + w * 0.22, by - h * 1.0, cx + w * 0.3, by - h * 0.6)
        ..close();
      path.addPath(roof, Offset.zero);
      // Roues
      path.addOval(Rect.fromCircle(center: Offset(cx - w * 0.28, by - h * 0.05), radius: h * 0.26));
      path.addOval(Rect.fromCircle(center: Offset(cx + w * 0.28, by - h * 0.05), radius: h * 0.26));
      return path;

    case Subject.tree:
      final h = s * 1.3;
      final trunkW = h * 0.08;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - trunkW / 2, by - h * 0.55, trunkW, h * 0.55),
          Radius.circular(trunkW * 0.3),
        ),
      );
      final crown = Rect.fromCenter(center: Offset(cx, by - h * 0.72), width: h * 0.78, height: h * 0.6);
      path.addOval(crown);
      path.addOval(crown.translate(-h * 0.2, h * 0.1).deflate(h * 0.1));
      path.addOval(crown.translate(h * 0.22, h * 0.06).deflate(h * 0.12));
      return path;

    case Subject.palms:
      final h = s * 1.5;
      for (final side in [-1.0, 1.0]) {
        final tx = cx + side * s * 0.32;
        final th = h * (side < 0 ? 1.0 : 0.78);
        final trunk = Path()
          ..moveTo(tx - th * 0.035, by)
          ..quadraticBezierTo(tx + side * th * 0.08, by - th * 0.5, tx + side * th * 0.16, by - th)
          ..lineTo(tx + side * th * 0.22, by - th)
          ..quadraticBezierTo(tx + side * th * 0.14, by - th * 0.5, tx + th * 0.035, by)
          ..close();
        path.addPath(trunk, Offset.zero);
        final crownCenter = Offset(tx + side * th * 0.19, by - th);
        for (var i = 0; i < 7; i++) {
          final a = math.pi + (i / 6) * math.pi;
          final frond = Path()
            ..moveTo(crownCenter.dx, crownCenter.dy)
            ..quadraticBezierTo(
              crownCenter.dx + math.cos(a) * th * 0.3,
              crownCenter.dy + math.sin(a) * th * 0.22,
              crownCenter.dx + math.cos(a) * th * 0.42,
              crownCenter.dy + math.sin(a) * th * 0.34 + th * 0.06,
            )
            ..quadraticBezierTo(
              crownCenter.dx + math.cos(a) * th * 0.28,
              crownCenter.dy + math.sin(a) * th * 0.18 + th * 0.03,
              crownCenter.dx,
              crownCenter.dy,
            );
          path.addPath(frond, Offset.zero);
        }
      }
      return path;

    case Subject.cup:
      final w = s * 0.86;
      final h = w * 0.8;
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - w / 2, by - h, w, h),
          bottomLeft: Radius.circular(w * 0.3),
          bottomRight: Radius.circular(w * 0.3),
          topLeft: Radius.circular(w * 0.08),
          topRight: Radius.circular(w * 0.08),
        ),
      );
      // Anse : anneau obtenu en évidant un ovale intérieur.
      final handle = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCenter(
          center: Offset(cx + w * 0.5, by - h * 0.55),
          width: w * 0.46,
          height: h * 0.5,
        ))
        ..addOval(Rect.fromCenter(
          center: Offset(cx + w * 0.46, by - h * 0.55),
          width: w * 0.24,
          height: h * 0.28,
        ));
      path.addPath(handle, Offset.zero);
      // Soucoupe
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.62, by - h * 0.06, w * 1.24, h * 0.1),
          Radius.circular(h * 0.06),
        ),
      );
      return path;

    case Subject.boat:
      final w = s * 1.1;
      final h = w * 0.5;
      path
        ..moveTo(cx - w / 2, by - h * 0.1)
        ..quadraticBezierTo(cx, by + h * 0.22, cx + w / 2, by - h * 0.1)
        ..close();
      path
        ..moveTo(cx - w * 0.04, by - h * 0.12)
        ..lineTo(cx - w * 0.04, by - h * 1.1)
        ..lineTo(cx + w * 0.34, by - h * 0.2)
        ..close();
      return path;

    case Subject.bike:
      final w = s * 1.1;
      final r = w * 0.22;
      path.addOval(Rect.fromCircle(center: Offset(cx - w * 0.3, by - r), radius: r));
      path.addOval(Rect.fromCircle(center: Offset(cx + w * 0.3, by - r), radius: r));
      path.addRect(Rect.fromLTWH(cx - w * 0.3, by - r * 1.9, w * 0.6, r * 0.16));
      return path;

    case Subject.sunflower:
      final h = s * 1.5;
      final stemW = h * 0.035;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - stemW / 2, by - h * 0.72, stemW, h * 0.72),
          Radius.circular(stemW),
        ),
      );
      final head = Offset(cx, by - h * 0.78);
      final petal = h * 0.22;
      // Les pétales et le disque sont unis explicitement : additionnés dans un
      // même Path, leurs sens de tracé opposés creuseraient un anneau au centre.
      final petals = Path();
      for (var i = 0; i < 14; i++) {
        final a = i / 14 * math.pi * 2;
        final tip = head + Offset(math.cos(a), math.sin(a)) * petal * 1.5;
        final side = Offset(-math.sin(a), math.cos(a)) * petal * 0.3;
        final base = head + Offset(math.cos(a), math.sin(a)) * petal * 0.45;
        petals
          ..moveTo(base.dx + side.dx, base.dy + side.dy)
          ..quadraticBezierTo(
            base.dx + side.dx * 1.6 + (tip.dx - base.dx) * 0.5,
            base.dy + side.dy * 1.6 + (tip.dy - base.dy) * 0.5,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            base.dx - side.dx * 1.6 + (tip.dx - base.dx) * 0.5,
            base.dy - side.dy * 1.6 + (tip.dy - base.dy) * 0.5,
            base.dx - side.dx,
            base.dy - side.dy,
          )
          ..close();
      }
      final disc = Path()
        ..addOval(Rect.fromCircle(center: head, radius: petal * 0.62));
      path.addPath(Path.combine(PathOperation.union, petals, disc), Offset.zero);
      return path;

    case Subject.skater:
      final h = s * 0.8;
      final w = h * 0.24;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.5, by - h * 0.7, w, h * 0.55),
          Radius.circular(w * 0.4),
        ),
      );
      path.addOval(Rect.fromCircle(center: Offset(cx, by - h * 0.82), radius: w * 0.32));
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 1.1, by - h * 0.1, w * 2.2, h * 0.06),
          Radius.circular(h * 0.04),
        ),
      );
      return path;

    case Subject.kayak:
      final w = s * 1.3;
      final h = w * 0.24;
      path
        ..moveTo(cx - w / 2, by)
        ..quadraticBezierTo(cx, by + h * 0.9, cx + w / 2, by)
        ..quadraticBezierTo(cx, by - h * 0.5, cx - w / 2, by)
        ..close();
      final ph = w * 0.36;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - ph * 0.14, by - ph, ph * 0.28, ph * 0.75),
          Radius.circular(ph * 0.14),
        ),
      );
      path.addOval(Rect.fromCircle(center: Offset(cx, by - ph * 1.1), radius: ph * 0.16));
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.42, by - ph * 0.82, w * 0.84, ph * 0.07),
          Radius.circular(ph * 0.05),
        ),
      );
      return path;
  }
}
