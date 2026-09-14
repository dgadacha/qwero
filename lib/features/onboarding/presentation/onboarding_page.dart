import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../core/l10n/labels.dart';

/// Écran 02 (§67, §182) : trois pages qui expliquent le produit.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _scenes = [
    [Scene.hikeRidge, Scene.kayak, Scene.fishing],
    [Scene.sunsetOcean, Scene.coffee, Scene.loneTree],
    [Scene.citySky, Scene.puddleReflection, Scene.beachPalms],
  ];

  List<({String title, String body, List<Scene> scenes})> _pagesOf(L l) => [
    (title: l.onboarding1Title, body: l.onboarding1Body, scenes: _scenes[0]),
    (title: l.onboarding2Title, body: l.onboarding2Body, scenes: _scenes[1]),
    (title: l.onboarding3Title, body: l.onboarding3Body, scenes: _scenes[2]),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _scenes.length - 1) {
      context.go('/interests');
    } else {
      _controller.nextPage(duration: AppMotion.screen, curve: AppMotion.standard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pagesOf(context.l);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: TextButton(
                  onPressed: () => context.go('/interests'),
                  child: Text(
                    context.l.skip,
                    style: AppTypography.bodyStrong.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Column(
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: 300,
                          child: _PhotoStack(scenes: page.scenes),
                        ),
                        const Spacer(),
                        Text(
                          page.title,
                          style: AppTypography.hero.copyWith(fontSize: 29),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(page.body, style: AppTypography.body, textAlign: TextAlign.center),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: AppMotion.micro,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.surface3,
                      borderRadius: AppRadius.chipR,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                0,
                AppSpacing.screenH,
                AppSpacing.xl,
              ),
              child: PrimaryButton(
                label: _index == pages.length - 1
                    ? context.l.onboardingPickInterests
                    : context.l.next,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Polaroids inclinés, comme des souvenirs posés en tas (§182).
class _PhotoStack extends StatelessWidget {
  const _PhotoStack({required this.scenes});

  final List<Scene> scenes;

  static const _layout = [
    (dx: -0.42, dy: 0.12, angle: -0.16, scale: 0.82),
    (dx: 0.44, dy: 0.2, angle: 0.14, scale: 0.8),
    (dx: 0.02, dy: -0.06, angle: 0.03, scale: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cardW = w * 0.52;
        final cardH = h * 0.66;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: w * 0.8,
              height: h * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.22, blur: 70),
              ),
            ),
            for (var i = 0; i < math.min(scenes.length, _layout.length); i++)
              Transform.translate(
                offset: Offset(_layout[i].dx * w * 0.5, _layout[i].dy * h * 0.4),
                child: Transform.rotate(
                  angle: _layout[i].angle,
                  child: Container(
                    width: cardW * _layout[i].scale,
                    height: cardH * _layout[i].scale,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.cardR,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                      boxShadow: AppShadows.card,
                    ),
                    child: SceneImage(scenes[i], borderRadius: AppRadius.cardR),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
