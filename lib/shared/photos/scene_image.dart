import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'scene.dart';
import 'scene_painter.dart';
import 'scene_recipe.dart';

/// Affiche une scène. Isolée dans son propre calque de peinture pour ne pas
/// se redessiner à chaque frame des écrans animés.
class SceneImage extends StatelessWidget {
  const SceneImage(
    this.scene, {
    super.key,
    this.parallax = 0,
    this.borderRadius,
    this.scrim = false,
    this.overlay,
  });

  final Scene scene;
  final double parallax;
  final BorderRadius? borderRadius;

  /// Voile sombre pour poser du texte par-dessus (§181).
  final bool scrim;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    Widget child = RepaintBoundary(
      child: CustomPaint(
        painter: ScenePainter(SceneRecipe.of(scene), parallax: parallax),
        size: Size.infinite,
      ),
    );

    if (scrim || overlay != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (scrim)
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.photoScrim),
            ),
          ?overlay,
        ],
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
