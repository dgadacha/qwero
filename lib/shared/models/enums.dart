import 'package:flutter/widgets.dart';

import '../../core/theme/app_theme.dart';

/// Difficultés (§16) et World Quest (§17).
enum QuestDifficulty {
  easy(color: AppColors.easy, dot: '🟢'),
  medium(color: AppColors.medium, dot: '🟡'),
  hard(color: AppColors.hard, dot: '🔴'),
  world(color: AppColors.world, dot: '🌎');

  const QuestDifficulty({required this.color, required this.dot});

  final Color color;
  final String dot;

  bool get isWorld => this == QuestDifficulty.world;
}

/// Catégories (§15).
enum QuestCategory {
  adventure('🏔'),
  photography('📷'),
  creative('🎨'),
  food('🍔'),
  social('👥'),
  nature('🌿'),
  sport('🏋'),
  music('🎵'),
  gaming('🎮'),
  travel('✈'),
  funny('😂'),
  observation('👀'),
  exploration('🌎');

  const QuestCategory(this.emoji);

  final String emoji;
}

/// Types de preuve (§32). Le MVP n'utilise que [photo].
enum ProofType { photo, video, location, activity, multi }

/// Résultat du Score Engine (§36).
enum QuestCheckVerdict { pass, uncertain, fail }

/// Statut d'une participation (§75).
enum CompletionStatus { pendingUpload, analyzing, validated, uncertain, rejected }

/// Visibilité (§107).
enum QuestVisibility { private, friends, public }

/// État d'une quête du jour pour l'utilisateur courant.
enum QuestProgress { available, inProgress, completed, expired }
