import 'package:flutter/material.dart';

import 'scene.dart';

/// Un astre : soleil, lune, ou source lumineuse.
class SunSpec {
  const SunSpec({
    required this.x,
    required this.y,
    required this.radius,
    required this.core,
    required this.halo,
    this.haloScale = 6.0,
  });

  /// Position relative (0..1) dans la scène.
  final double x;
  final double y;
  final double radius;
  final Color core;
  final Color halo;
  final double haloScale;
}

/// Une silhouette de relief (montagne, colline, ligne d'immeubles).
class RidgeSpec {
  const RidgeSpec({
    required this.top,
    required this.baseline,
    required this.color,
    this.peaks = 3,
    this.jitter = 0.35,
    this.seed = 1,
    this.style = RidgeStyle.mountain,
  });

  /// Hauteur du sommet moyen (0 = haut de la scène, 1 = bas).
  final double top;

  /// Ligne sur laquelle repose la silhouette.
  final double baseline;
  final Color color;
  final int peaks;
  final double jitter;
  final int seed;
  final RidgeStyle style;
}

enum RidgeStyle { mountain, hill, skyline, dune, treeline }

/// Nappe d'eau : reflet du ciel + traînée lumineuse.
class WaterSpec {
  const WaterSpec({
    required this.top,
    required this.colors,
    this.sparkle = true,
    this.sunTrail = true,
  });

  final double top;
  final List<Color> colors;
  final bool sparkle;
  final bool sunTrail;
}

class CloudSpec {
  const CloudSpec({
    required this.x,
    required this.y,
    required this.width,
    required this.color,
    this.height = 0.05,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
}

/// Silhouette posée au premier plan.
enum Subject { none, hiker, car, tree, palms, cup, person, boat, bike, sunflower, skater, kayak }

class SubjectSpec {
  const SubjectSpec({
    required this.subject,
    this.x = 0.5,
    this.baseline = 0.82,
    this.scale = 1.0,
    this.color,
    this.flip = false,
  });

  final Subject subject;
  final double x;
  final double baseline;
  final double scale;
  final Color? color;
  final bool flip;
}

/// Description complète d'une scène. Le painter n'a qu'à empiler les couches.
class SceneRecipe {
  const SceneRecipe({
    required this.sky,
    this.skyStops,
    this.sun,
    this.clouds = const [],
    this.ridges = const [],
    this.water,
    this.subjects = const [],
    this.stars = 0,
    this.groundColor,
    this.groundTop,
    this.haze,
    this.vignette = 0.55,
    this.grain = 0.035,
  });

  final List<Color> sky;
  final List<double>? skyStops;
  final SunSpec? sun;
  final List<CloudSpec> clouds;
  final List<RidgeSpec> ridges;
  final WaterSpec? water;
  final List<SubjectSpec> subjects;
  final int stars;
  final Color? groundColor;
  final double? groundTop;
  final Color? haze;
  final double vignette;
  final double grain;

  static SceneRecipe of(Scene scene) => _recipes[scene]!;
}

const _night = Color(0xFF0B1020);

final Map<Scene, SceneRecipe> _recipes = {
  Scene.sunsetOcean: const SceneRecipe(
    sky: [Color(0xFF2A1B4E), Color(0xFF6B3A6E), Color(0xFFD46A55), Color(0xFFF5A65B)],
    skyStops: [0.0, 0.36, 0.58, 0.74],
    sun: SunSpec(
      x: 0.52,
      y: 0.68,
      radius: 0.085,
      core: Color(0xFFFFE0A8),
      halo: Color(0xFFFF9147),
    ),
    clouds: [
      CloudSpec(x: 0.22, y: 0.3, width: 0.5, color: Color(0x66714A7E)),
      CloudSpec(x: 0.75, y: 0.45, width: 0.42, color: Color(0x59A05F73)),
      CloudSpec(x: 0.45, y: 0.2, width: 0.34, color: Color(0x40593F73)),
    ],
    ridges: [
      RidgeSpec(top: 0.63, baseline: 0.8, color: Color(0xFF5B3A62), peaks: 4, seed: 3),
      RidgeSpec(top: 0.7, baseline: 0.82, color: Color(0xFF34203F), peaks: 3, seed: 7),
    ],
    water: WaterSpec(
      top: 0.79,
      colors: [Color(0xFFB4603F), Color(0xFF4A2749), Color(0xFF1A1330)],
    ),
    haze: Color(0x33FF9147),
  ),
  Scene.mountainLake: const SceneRecipe(
    sky: [Color(0xFF1A2A5E), Color(0xFF4A5FA0), Color(0xFFA97FA8), Color(0xFFE8A88C)],
    skyStops: [0.0, 0.34, 0.58, 0.74],
    sun: SunSpec(x: 0.72, y: 0.68, radius: 0.06, core: Color(0xFFFFEFCB), halo: Color(0xFFFFAE7A)),
    clouds: [
      CloudSpec(x: 0.3, y: 0.22, width: 0.46, color: Color(0x4D6C7FC4)),
      CloudSpec(x: 0.7, y: 0.34, width: 0.4, color: Color(0x40946FA8)),
    ],
    ridges: [
      RidgeSpec(top: 0.42, baseline: 0.76, color: Color(0xFF3E4E82), peaks: 3, seed: 11, jitter: 0.5),
      RidgeSpec(top: 0.55, baseline: 0.78, color: Color(0xFF27325C), peaks: 4, seed: 5),
      RidgeSpec(top: 0.66, baseline: 0.8, color: Color(0xFF161E3C), peaks: 5, seed: 17, jitter: 0.28),
    ],
    water: WaterSpec(top: 0.78, colors: [Color(0xFF52598F), Color(0xFF232B52), Color(0xFF10152C)]),
  ),
  Scene.kayak: const SceneRecipe(
    sky: [Color(0xFF15305C), Color(0xFF2E6C93), Color(0xFF6FB3C4), Color(0xFFC9DCC9)],
    skyStops: [0.0, 0.3, 0.55, 0.72],
    sun: SunSpec(x: 0.3, y: 0.62, radius: 0.05, core: Color(0xFFFFF6D6), halo: Color(0xFFFFD48A)),
    ridges: [
      RidgeSpec(top: 0.52, baseline: 0.74, color: Color(0xFF2D5A55), peaks: 3, seed: 9),
      RidgeSpec(top: 0.63, baseline: 0.76, color: Color(0xFF18353A), peaks: 4, seed: 23, style: RidgeStyle.treeline),
    ],
    water: WaterSpec(top: 0.75, colors: [Color(0xFF3E8497), Color(0xFF1E4A5E), Color(0xFF0E2333)]),
    subjects: [SubjectSpec(subject: Subject.kayak, x: 0.55, baseline: 0.86, scale: 1.1)],
  ),
  Scene.fishing: const SceneRecipe(
    sky: [Color(0xFF1E2A4A), Color(0xFF4E5F7C), Color(0xFF9AA88C), Color(0xFFD9C58F)],
    skyStops: [0.0, 0.32, 0.56, 0.72],
    sun: SunSpec(x: 0.68, y: 0.6, radius: 0.045, core: Color(0xFFFFF3CC), halo: Color(0xFFE8C27A)),
    ridges: [
      RidgeSpec(top: 0.56, baseline: 0.75, color: Color(0xFF3C5140), peaks: 3, seed: 31),
      RidgeSpec(top: 0.66, baseline: 0.78, color: Color(0xFF1F2E23), peaks: 6, seed: 13, style: RidgeStyle.treeline),
    ],
    water: WaterSpec(top: 0.77, colors: [Color(0xFF6C7A63), Color(0xFF2E3A33), Color(0xFF141C1A)]),
    subjects: [SubjectSpec(subject: Subject.person, x: 0.38, baseline: 0.79, scale: 0.9)],
  ),
  Scene.hikeRidge: const SceneRecipe(
    sky: [Color(0xFF241B4E), Color(0xFF5B3E86), Color(0xFFB06E9C), Color(0xFFE9A98F)],
    skyStops: [0.0, 0.32, 0.56, 0.74],
    sun: SunSpec(x: 0.24, y: 0.66, radius: 0.055, core: Color(0xFFFFE9BE), halo: Color(0xFFFF9D6B)),
    clouds: [CloudSpec(x: 0.62, y: 0.28, width: 0.5, color: Color(0x4D7B5794))],
    ridges: [
      RidgeSpec(top: 0.5, baseline: 0.8, color: Color(0xFF553B72), peaks: 3, seed: 4, jitter: 0.55),
      RidgeSpec(top: 0.62, baseline: 0.86, color: Color(0xFF33254D), peaks: 4, seed: 19),
      RidgeSpec(top: 0.74, baseline: 1.0, color: Color(0xFF171129), peaks: 2, seed: 2, jitter: 0.2),
    ],
    subjects: [SubjectSpec(subject: Subject.hiker, x: 0.62, baseline: 0.79, scale: 1.0)],
  ),
  Scene.citySky: const SceneRecipe(
    sky: [Color(0xFF2B4E86), Color(0xFF5B8FC4), Color(0xFF9EC8E0), Color(0xFFD9E6EC)],
    skyStops: [0.0, 0.36, 0.64, 0.86],
    sun: SunSpec(x: 0.78, y: 0.24, radius: 0.05, core: Color(0xFFFFFBE8), halo: Color(0xFFFFE9A8), haloScale: 8),
    clouds: [
      CloudSpec(x: 0.28, y: 0.34, width: 0.52, color: Color(0x73FFFFFF), height: 0.06),
      CloudSpec(x: 0.66, y: 0.5, width: 0.44, color: Color(0x59FFFFFF)),
      CloudSpec(x: 0.44, y: 0.18, width: 0.36, color: Color(0x4DFFFFFF)),
    ],
    ridges: [
      RidgeSpec(top: 0.82, baseline: 1.0, color: Color(0xFF1B2438), peaks: 7, seed: 21, style: RidgeStyle.skyline),
    ],
  ),
  Scene.nightCity: const SceneRecipe(
    sky: [_night, Color(0xFF1B2450), Color(0xFF3A2C6B), Color(0xFF6B3F7A)],
    skyStops: [0.0, 0.34, 0.6, 0.8],
    stars: 60,
    clouds: [CloudSpec(x: 0.7, y: 0.3, width: 0.5, color: Color(0x33574A8C))],
    ridges: [
      RidgeSpec(top: 0.66, baseline: 1.0, color: Color(0xFF1A1F3C), peaks: 6, seed: 33, style: RidgeStyle.skyline),
      RidgeSpec(top: 0.78, baseline: 1.0, color: Color(0xFF0D1126), peaks: 9, seed: 8, style: RidgeStyle.skyline),
    ],
    haze: Color(0x337357FF),
  ),
  Scene.openRoad: const SceneRecipe(
    sky: [Color(0xFF33285C), Color(0xFF7A4A72), Color(0xFFD07F5E), Color(0xFFF0B173)],
    skyStops: [0.0, 0.36, 0.6, 0.76],
    sun: SunSpec(x: 0.5, y: 0.72, radius: 0.07, core: Color(0xFFFFEBBE), halo: Color(0xFFFF9B52)),
    ridges: [
      RidgeSpec(top: 0.64, baseline: 0.78, color: Color(0xFF5A3E60), peaks: 4, seed: 29, jitter: 0.3),
      RidgeSpec(top: 0.72, baseline: 0.8, color: Color(0xFF32243F), peaks: 3, seed: 15),
    ],
    groundColor: Color(0xFF221A2E),
    groundTop: 0.79,
  ),
  Scene.redCar: const SceneRecipe(
    sky: [Color(0xFF1F2A44), Color(0xFF3E5273), Color(0xFF7E8CA6), Color(0xFFB9BCC4)],
    skyStops: [0.0, 0.3, 0.54, 0.7],
    ridges: [
      RidgeSpec(top: 0.56, baseline: 0.74, color: Color(0xFF2C3A54), peaks: 5, seed: 41, style: RidgeStyle.skyline),
    ],
    groundColor: Color(0xFF1A2130),
    groundTop: 0.74,
    subjects: [SubjectSpec(subject: Subject.car, x: 0.5, baseline: 0.86, scale: 1.25, color: Color(0xFFE8434F))],
  ),
  Scene.yellowCar: const SceneRecipe(
    sky: [Color(0xFF243050), Color(0xFF4A5C7E), Color(0xFF8C93A8), Color(0xFFC2C0BC)],
    skyStops: [0.0, 0.3, 0.54, 0.7],
    ridges: [
      RidgeSpec(top: 0.58, baseline: 0.74, color: Color(0xFF2E3B55), peaks: 6, seed: 12, style: RidgeStyle.skyline),
    ],
    groundColor: Color(0xFF1C2331),
    groundTop: 0.74,
    subjects: [SubjectSpec(subject: Subject.car, x: 0.48, baseline: 0.86, scale: 1.25, color: Color(0xFFF5C84C))],
  ),
  Scene.forest: const SceneRecipe(
    sky: [Color(0xFF16301F), Color(0xFF2E5638), Color(0xFF6E8C4E), Color(0xFFC5C978)],
    skyStops: [0.0, 0.32, 0.58, 0.8],
    sun: SunSpec(x: 0.6, y: 0.4, radius: 0.045, core: Color(0xFFFFF6C9), halo: Color(0xFFD8E08A), haloScale: 7),
    ridges: [
      RidgeSpec(top: 0.3, baseline: 1.0, color: Color(0xFF1E4029), peaks: 7, seed: 44, style: RidgeStyle.treeline),
      RidgeSpec(top: 0.12, baseline: 1.0, color: Color(0xFF0E2116), peaks: 4, seed: 6, style: RidgeStyle.treeline),
    ],
  ),
  Scene.loneTree: const SceneRecipe(
    sky: [Color(0xFF2B3560), Color(0xFF5E6E96), Color(0xFFA8A7A0), Color(0xFFE3C89A)],
    skyStops: [0.0, 0.32, 0.58, 0.78],
    sun: SunSpec(x: 0.74, y: 0.62, radius: 0.05, core: Color(0xFFFFF2D0), halo: Color(0xFFF0C083)),
    ridges: [RidgeSpec(top: 0.7, baseline: 0.8, color: Color(0xFF3B4436), peaks: 4, seed: 27, style: RidgeStyle.hill)],
    groundColor: Color(0xFF232A22),
    groundTop: 0.79,
    subjects: [SubjectSpec(subject: Subject.tree, x: 0.36, baseline: 0.82, scale: 1.2)],
  ),
  Scene.puddleReflection: const SceneRecipe(
    sky: [Color(0xFF16203A), Color(0xFF2E3F63), Color(0xFF5C6E96), Color(0xFF8E9AB4)],
    skyStops: [0.0, 0.3, 0.5, 0.62],
    ridges: [
      RidgeSpec(top: 0.36, baseline: 0.62, color: Color(0xFF212C48), peaks: 5, seed: 36, style: RidgeStyle.skyline),
    ],
    water: WaterSpec(top: 0.62, colors: [Color(0xFF44567F), Color(0xFF202B45), Color(0xFF0F1523)], sunTrail: false),
    vignette: 0.68,
  ),
  Scene.windowReflection: const SceneRecipe(
    sky: [Color(0xFF23304C), Color(0xFF465C82), Color(0xFF7E90AE), Color(0xFFB6BFCB)],
    skyStops: [0.0, 0.3, 0.56, 0.78],
    clouds: [
      CloudSpec(x: 0.34, y: 0.36, width: 0.5, color: Color(0x59FFFFFF)),
      CloudSpec(x: 0.7, y: 0.52, width: 0.4, color: Color(0x40FFFFFF)),
    ],
    ridges: [
      RidgeSpec(top: 0.7, baseline: 1.0, color: Color(0xFF1D2537), peaks: 5, seed: 52, style: RidgeStyle.skyline),
    ],
    vignette: 0.62,
  ),
  Scene.coffee: const SceneRecipe(
    sky: [Color(0xFF2A1E18), Color(0xFF4A332A), Color(0xFF7A5540), Color(0xFFB98A5E)],
    skyStops: [0.0, 0.34, 0.62, 0.86],
    sun: SunSpec(x: 0.76, y: 0.2, radius: 0.04, core: Color(0xFFFFE9C4), halo: Color(0xFFD6A46A), haloScale: 9),
    groundColor: Color(0xFF20160F),
    groundTop: 0.78,
    subjects: [SubjectSpec(subject: Subject.cup, x: 0.5, baseline: 0.84, scale: 1.15)],
    vignette: 0.7,
  ),
  Scene.streetFood: const SceneRecipe(
    sky: [Color(0xFF24182A), Color(0xFF4A2A38), Color(0xFF8A4638), Color(0xFFD98A4C)],
    skyStops: [0.0, 0.34, 0.6, 0.82],
    stars: 24,
    ridges: [
      RidgeSpec(top: 0.5, baseline: 1.0, color: Color(0xFF241826), peaks: 6, seed: 61, style: RidgeStyle.skyline),
    ],
    haze: Color(0x40E07C3C),
    vignette: 0.66,
  ),
  Scene.skatepark: const SceneRecipe(
    sky: [Color(0xFF2C3450), Color(0xFF556078), Color(0xFF8B93A2), Color(0xFFC8C6BE)],
    skyStops: [0.0, 0.3, 0.56, 0.74],
    ridges: [RidgeSpec(top: 0.62, baseline: 0.76, color: Color(0xFF39415A), peaks: 4, seed: 55, style: RidgeStyle.skyline)],
    groundColor: Color(0xFF262C3C),
    groundTop: 0.76,
    subjects: [SubjectSpec(subject: Subject.skater, x: 0.56, baseline: 0.8, scale: 1.0)],
  ),
  Scene.desertDunes: const SceneRecipe(
    sky: [Color(0xFF3A2A54), Color(0xFF7E4F62), Color(0xFFD08A5E), Color(0xFFF3C489)],
    skyStops: [0.0, 0.34, 0.58, 0.74],
    sun: SunSpec(x: 0.3, y: 0.66, radius: 0.06, core: Color(0xFFFFF0C8), halo: Color(0xFFFFAE6B)),
    ridges: [
      RidgeSpec(top: 0.7, baseline: 0.86, color: Color(0xFFB97C4E), peaks: 2, seed: 71, style: RidgeStyle.dune),
      RidgeSpec(top: 0.78, baseline: 1.0, color: Color(0xFF6E4530), peaks: 2, seed: 72, style: RidgeStyle.dune),
    ],
  ),
  Scene.snowPeak: const SceneRecipe(
    sky: [Color(0xFF16294E), Color(0xFF3B5B8E), Color(0xFF8FB0CE), Color(0xFFE6EEF4)],
    skyStops: [0.0, 0.32, 0.6, 0.8],
    ridges: [
      RidgeSpec(top: 0.38, baseline: 0.86, color: Color(0xFF8FA8C6), peaks: 3, seed: 81, jitter: 0.6),
      RidgeSpec(top: 0.54, baseline: 0.9, color: Color(0xFF41577C), peaks: 4, seed: 82),
      RidgeSpec(top: 0.68, baseline: 1.0, color: Color(0xFF1E2C46), peaks: 5, seed: 83, jitter: 0.3),
    ],
  ),
  Scene.beachPalms: const SceneRecipe(
    sky: [Color(0xFF1B3A5E), Color(0xFF3E7E96), Color(0xFF7FC0B4), Color(0xFFE8D9A8)],
    skyStops: [0.0, 0.3, 0.54, 0.72],
    sun: SunSpec(x: 0.68, y: 0.62, radius: 0.055, core: Color(0xFFFFF6D6), halo: Color(0xFFFFD08A)),
    water: WaterSpec(top: 0.74, colors: [Color(0xFF48A8A0), Color(0xFF1F6274), Color(0xFF123244)]),
    subjects: [SubjectSpec(subject: Subject.palms, x: 0.2, baseline: 0.92, scale: 1.3)],
  ),
  Scene.sunflower: const SceneRecipe(
    sky: [Color(0xFF2A3A60), Color(0xFF52719E), Color(0xFF96A87E), Color(0xFFE0C468)],
    skyStops: [0.0, 0.3, 0.52, 0.7],
    sun: SunSpec(x: 0.8, y: 0.3, radius: 0.045, core: Color(0xFFFFF7D0), halo: Color(0xFFF0CE7E), haloScale: 8),
    groundColor: Color(0xFF3E4A28),
    groundTop: 0.7,
    subjects: [SubjectSpec(subject: Subject.sunflower, x: 0.44, baseline: 0.78, scale: 1.3)],
  ),
  Scene.balcony: const SceneRecipe(
    sky: [Color(0xFF2E2044), Color(0xFF6B3E63), Color(0xFFBC6E62), Color(0xFFEFA97C)],
    skyStops: [0.0, 0.34, 0.6, 0.8],
    sun: SunSpec(x: 0.62, y: 0.68, radius: 0.05, core: Color(0xFFFFE8BC), halo: Color(0xFFFF9F6E)),
    ridges: [
      RidgeSpec(top: 0.6, baseline: 1.0, color: Color(0xFF2B1F38), peaks: 5, seed: 91, style: RidgeStyle.skyline),
    ],
  ),
  Scene.metro: const SceneRecipe(
    sky: [Color(0xFF141A2E), Color(0xFF283350), Color(0xFF44527A), Color(0xFF7C88AC)],
    skyStops: [0.0, 0.36, 0.62, 0.8],
    sun: SunSpec(
      x: 0.5,
      y: 0.52,
      radius: 0.03,
      core: Color(0xFFE8EEFF),
      halo: Color(0xFF8FA4D8),
      haloScale: 10,
    ),
    ridges: [
      RidgeSpec(top: 0.3, baseline: 0.78, color: Color(0xFF1B2440), peaks: 5, seed: 101, style: RidgeStyle.skyline),
    ],
    groundColor: Color(0xFF10152A),
    groundTop: 0.78,
    subjects: [SubjectSpec(subject: Subject.person, x: 0.38, baseline: 0.8, scale: 0.85)],
    haze: Color(0x336E7CA8),
    vignette: 0.74,
  ),
  Scene.harbor: const SceneRecipe(
    sky: [Color(0xFF16294A), Color(0xFF33587E), Color(0xFF6E92AE), Color(0xFFC6C2B4)],
    skyStops: [0.0, 0.32, 0.56, 0.74],
    sun: SunSpec(x: 0.26, y: 0.58, radius: 0.045, core: Color(0xFFFFF4D8), halo: Color(0xFFEFC38E)),
    ridges: [
      RidgeSpec(top: 0.58, baseline: 0.74, color: Color(0xFF23375A), peaks: 6, seed: 95, style: RidgeStyle.skyline),
    ],
    water: WaterSpec(top: 0.74, colors: [Color(0xFF3E6C8E), Color(0xFF1D3550), Color(0xFF0D1A2A)]),
    subjects: [SubjectSpec(subject: Subject.boat, x: 0.66, baseline: 0.8, scale: 0.9)],
  ),
};
