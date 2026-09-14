import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'logo.dart';
import 'misc.dart';

/// Écran d'attente du premier chargement.
///
/// Un squelette plutôt qu'un sablier (§105) : la page se met en place dans la
/// forme qu'elle aura, ce qui rend l'attente moins longue.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Crown(size: 22),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Qwero',
                    style: AppTypography.label.copyWith(fontSize: 15, letterSpacing: -0.2),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Skeleton(width: 220, height: 30, radius: AppRadius.small),
              const SizedBox(height: AppSpacing.sm),
              const Skeleton(width: 150, height: 14),
              const SizedBox(height: AppSpacing.xs),
              const Skeleton(height: 8, radius: 8),
              const SizedBox(height: AppSpacing.xl),
              const Skeleton(width: 160, height: 20, radius: AppRadius.small),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < 3; i++) ...[
                const Skeleton(height: 142, radius: AppRadius.card),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (message != null) ...[
                const Spacer(),
                Center(child: Text(message!, style: AppTypography.metadata)),
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
