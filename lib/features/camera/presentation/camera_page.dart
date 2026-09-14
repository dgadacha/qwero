import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';
import '../../quest_check/presentation/quest_check_page.dart';
import '../../../core/l10n/labels.dart';

/// Écran 06 — capture (§31, §96, §187).
///
/// Le prototype simule le viseur : la vraie caméra arrive avec le backend, et
/// la capture restera obligatoirement prise depuis l'app (§31).
class QuestCameraPage extends StatefulWidget {
  const QuestCameraPage({super.key, required this.quest});

  final Quest quest;

  @override
  State<QuestCameraPage> createState() => _QuestCameraPageState();
}

class _QuestCameraPageState extends State<QuestCameraPage> with SingleTickerProviderStateMixin {
  late final _shutter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Ce que « voit » l'objectif. Chaque quête propose une scène plausible.
  late Scene _framed = _scenesFor(widget.quest).first;

  /// Le contenu du viseur est capturé pixel par pixel : la preuve envoyée au
  /// serveur est une vraie image, pas un identifiant de scène.
  final _viewfinder = GlobalKey();
  int _sceneIndex = 0;
  bool _capturing = false;

  static List<Scene> _scenesFor(Quest quest) => switch (quest.id) {
    'q_hard_922' => [Scene.sunsetOcean, Scene.harbor, Scene.beachPalms, Scene.hikeRidge],
    'q_easy_849' => [Scene.redCar, Scene.streetFood, Scene.sunflower],
    'q_medium_221' => [Scene.openRoad, Scene.metro, Scene.forest, Scene.skatepark],
    'world_184' => [Scene.citySky, Scene.snowPeak, Scene.desertDunes],
    _ => [quest.scene, Scene.windowReflection, Scene.loneTree, Scene.coffee],
  };

  @override
  void dispose() {
    _shutter.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();

    final capturedAt = DateTime.now();
    final bytes = await _grabViewfinder();
    await _shutter.forward(from: 0);
    if (!mounted) return;

    context.pushReplacement(
      '/check',
      extra: QuestCheckArgs(
        quest: widget.quest,
        scene: _framed,
        imageBytes: bytes,
        capturedAt: capturedAt,
      ),
    );
  }

  /// Rend le viseur en image. La scène est dessinée par le code : la capture
  /// produit donc une photo cohérente avec ce que le joueur voyait.
  Future<Uint8List> _grabViewfinder() async {
    try {
      final boundary =
          _viewfinder.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return Uint8List(0);

      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List() ?? Uint8List(0);
    } catch (error) {
      debugPrint('Capture impossible : \$error');
      return Uint8List(0);
    }
  }

  void _cycleScene() {
    final scenes = _scenesFor(widget.quest);
    setState(() {
      _sceneIndex = (_sceneIndex + 1) % scenes.length;
      _framed = scenes[_sceneIndex];
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viseur
          Column(
            children: [
              SafeArea(bottom: false, child: const SizedBox(height: 46)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: ClipRRect(
                    borderRadius: AppRadius.cardR,
                    child: RepaintBoundary(
                      key: _viewfinder,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SceneImage(_framed),
                          const _ViewfinderFrame(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),

          // Rappel du critère de la quête, visible pendant la visée (§30).
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: MediaQuery.paddingOf(context).top + 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: AppRadius.chipR,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuestDifficultyBadge(widget.quest.difficulty, compact: true),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          widget.quest.title,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.metadata.copyWith(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barre supérieure. Le Stack étant en StackFit.expand, il faut aligner
          // explicitement, sinon la rangée se centre verticalement.
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    GlassIconButton(icon: Icons.close_rounded, onPressed: () => context.pop()),
                    const Spacer(),
                    GlassIconButton(
                      icon: Icons.flash_off_rounded,
                      onPressed: () => HapticFeedback.selectionClick(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Commandes
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l.photo,
                          style: AppTypography.label.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Text(
                          context.l.video,
                          style: AppTypography.label.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _GalleryButton(quest: widget.quest),
                        _ShutterButton(onTap: _capture, busy: _capturing),
                        GlassIconButton(
                          icon: Icons.cameraswitch_rounded,
                          size: 46,
                          onPressed: _cycleScene,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Flash de déclenchement
          AnimatedBuilder(
            animation: _shutter,
            builder: (context, _) {
              final t = _shutter.value;
              if (t == 0) return const SizedBox.shrink();
              final opacity = t < 0.3 ? t / 0.3 : 1 - (t - 0.3) / 0.7;
              return IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.85),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Coins de cadrage : l'interface reste minimaliste (§96).
class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _FramePainter(), size: Size.infinite),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const inset = 22.0;
    const len = 26.0;
    final corners = [
      (Offset(inset, inset), const Offset(1, 0), const Offset(0, 1)),
      (Offset(size.width - inset, inset), const Offset(-1, 0), const Offset(0, 1)),
      (Offset(inset, size.height - inset), const Offset(1, 0), const Offset(0, -1)),
      (Offset(size.width - inset, size.height - inset), const Offset(-1, 0), const Offset(0, -1)),
    ];
    for (final (origin, h, v) in corners) {
      canvas.drawLine(origin, origin + h * len, paint);
      canvas.drawLine(origin, origin + v * len, paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: AppMotion.micro,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rappelle que la galerie est fermée sur les quêtes du jour (§31).
class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: quest.galleryAllowed
          ? null
          : () {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l.cameraOnly),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: AppRadius.smallR,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface3,
              Color.lerp(AppColors.surface3, quest.scene.accent, 0.4)!,
            ],
          ),
        ),
        child: Transform.rotate(
          angle: math.pi / 24,
          child: Icon(
            quest.galleryAllowed ? Icons.photo_library_rounded : Icons.lock_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
