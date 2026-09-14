import 'package:flutter/material.dart';

/// Les visuels de l'application sont dessinés par le code plutôt que chargés
/// depuis le réseau : le prototype reste identique hors-ligne et garde une
/// direction artistique homogène (§180).
enum Scene {
  sunsetOcean,
  mountainLake,
  kayak,
  fishing,
  hikeRidge,
  citySky,
  nightCity,
  openRoad,
  redCar,
  yellowCar,
  forest,
  loneTree,
  puddleReflection,
  windowReflection,
  coffee,
  streetFood,
  skatepark,
  desertDunes,
  snowPeak,
  beachPalms,
  sunflower,
  balcony,
  metro,
  harbor;

  /// Couleur dominante, utilisée pour les halos et les fonds de secours.
  Color get accent => switch (this) {
    Scene.sunsetOcean => const Color(0xFFFF8A4C),
    Scene.mountainLake => const Color(0xFF6C8FD6),
    Scene.kayak => const Color(0xFF3FA9C9),
    Scene.fishing => const Color(0xFF7FA86B),
    Scene.hikeRidge => const Color(0xFFB07CD8),
    Scene.citySky => const Color(0xFF6FB7F0),
    Scene.nightCity => const Color(0xFF7357FF),
    Scene.openRoad => const Color(0xFFE8934C),
    Scene.redCar => const Color(0xFFE8434F),
    Scene.yellowCar => const Color(0xFFF5C84C),
    Scene.forest => const Color(0xFF4E8A5E),
    Scene.loneTree => const Color(0xFF8FB36A),
    Scene.puddleReflection => const Color(0xFF5E7FC0),
    Scene.windowReflection => const Color(0xFF9FB6D8),
    Scene.coffee => const Color(0xFFC98A55),
    Scene.streetFood => const Color(0xFFE07C3C),
    Scene.skatepark => const Color(0xFF7E8FA6),
    Scene.desertDunes => const Color(0xFFE0A45C),
    Scene.snowPeak => const Color(0xFF9FC4E8),
    Scene.beachPalms => const Color(0xFF3FC2A8),
    Scene.sunflower => const Color(0xFFF2C037),
    Scene.balcony => const Color(0xFFD98A7A),
    Scene.metro => const Color(0xFF6E7CA8),
    Scene.harbor => const Color(0xFF4D8FB8),
  };
}
