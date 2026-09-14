import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/models/enums.dart';

export '../../l10n/app_localizations.dart';

/// Raccourci de lecture des chaînes traduites : `context.l.maClé`.
extension LContext on BuildContext {
  L get l => L.of(this);
}

extension QuestDifficultyLabel on QuestDifficulty {
  String label(L l) => switch (this) {
    QuestDifficulty.easy => l.difficultyEasy,
    QuestDifficulty.medium => l.difficultyMedium,
    QuestDifficulty.hard => l.difficultyHard,
    QuestDifficulty.world => l.difficultyWorld,
  };
}

extension QuestCategoryLabel on QuestCategory {
  String label(L l) => switch (this) {
    QuestCategory.adventure => l.category_adventure,
    QuestCategory.photography => l.category_photography,
    QuestCategory.creative => l.category_creative,
    QuestCategory.food => l.category_food,
    QuestCategory.social => l.category_social,
    QuestCategory.nature => l.category_nature,
    QuestCategory.sport => l.category_sport,
    QuestCategory.music => l.category_music,
    QuestCategory.gaming => l.category_gaming,
    QuestCategory.travel => l.category_travel,
    QuestCategory.funny => l.category_funny,
    QuestCategory.observation => l.category_observation,
    QuestCategory.exploration => l.category_exploration,
  };
}

/// Libellé d'un contrôle QuestCheck. Le domaine ne manipule que des
/// identifiants : la traduction se fait à l'affichage.
String checkLabel(L l, String id, String fallback) => switch (id) {
  'photo' => l.checkPhotoFromApp,
  'live' => l.checkLiveCapture,
  'outdoor' => l.checkOutdoor,
  'sky' => l.checkSky,
  'color_red' => l.checkRed,
  'color_yellow' => l.checkYellow,
  'car' => l.checkVehicle,
  'before_20' || 'sunset' => l.checkSunset,
  'geo' => l.checkGeo,
  _ => fallback,
};

/// Libellé court d'un critère de quête, tel qu'affiché sur les puces.
String requirementLabel(L l, String id, String fallback) => switch (id) {
  'photo' => l.reqPhoto,
  'outdoor' => l.reqOutdoor,
  'live' => l.reqLive,
  'sky' => l.reqSky,
  'car' => l.reqCar,
  'color_red' => l.reqRed,
  'color_yellow' => l.reqYellow,
  'before_20' => l.reqBefore20,
  _ => fallback,
};

String formatAgo(L l, Duration ago) {
  if (ago.inMinutes < 1) return l.justNow;
  if (ago.inMinutes < 60) return l.agoMinutes(ago.inMinutes);
  if (ago.inHours < 24) return l.agoHours(ago.inHours);
  return l.agoDays(ago.inDays);
}
