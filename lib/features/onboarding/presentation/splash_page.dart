import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/logo.dart';
import '../../../core/l10n/labels.dart';

/// Écran 01 (§66, §181) : photographie immersive, voile sombre, logo.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
  );
  late final _actions = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Un lent zoom avant donne vie à la scène sans la dénaturer.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: 1.08 - 0.06 * _controller.value,
              child: child,
            ),
            child: const SceneImage(Scene.sunsetOcean),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99080C14), Color(0x1A080C14), Color(0xCC080C14), Color(0xFF080C14)],
                stops: [0.0, 0.34, 0.74, 0.96],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _logo,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(_logo),
                      child: Column(
                        children: [
                          const QuestLogo(size: 52),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l.tagline,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary.withValues(alpha: 0.85),
                              fontSize: 15.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _actions,
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: context.l.splashStart,
                          onPressed: () => context.go('/onboarding'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SecondaryButton(
                          label: context.l.splashHasAccount,
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
