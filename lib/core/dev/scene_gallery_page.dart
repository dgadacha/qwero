import 'package:flutter/material.dart';

import '../../shared/photos/scene.dart';
import '../../shared/photos/scene_image.dart';
import '../theme/app_theme.dart';

/// Planche-contact des scènes. Sert au réglage de la direction artistique,
/// n'est pas atteignable depuis l'application.
class SceneGalleryPage extends StatelessWidget {
  const SceneGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xs),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.72,
          ),
          itemCount: Scene.values.length,
          itemBuilder: (context, i) {
            final scene = Scene.values[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                SceneImage(scene, borderRadius: AppRadius.smallR),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    child: Text(
                      scene.name,
                      style: AppTypography.metadata.copyWith(
                        fontSize: 8.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
