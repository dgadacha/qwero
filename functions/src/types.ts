/**
 * Modèles de données Firestore (§71 à §75).
 *
 * Ces types décrivent ce qui est écrit en base. Le client Flutter possède ses
 * propres modèles Freezed ; les deux doivent rester alignés sur les noms de
 * champs.
 */

export type QuestDifficulty = 'easy' | 'medium' | 'hard' | 'world';

export type QuestCategory =
  | 'adventure'
  | 'photography'
  | 'creative'
  | 'food'
  | 'social'
  | 'nature'
  | 'sport'
  | 'music'
  | 'gaming'
  | 'travel'
  | 'funny'
  | 'observation'
  | 'exploration';

export type ProofType = 'photo' | 'video' | 'location' | 'activity' | 'multi';

export type Visibility = 'private' | 'friends' | 'public';

export type CompletionStatus =
  | 'pending_validation'
  | 'validated'
  | 'uncertain'
  | 'rejected'
  | 'delayed';

export type QuestCheckVerdict = 'pass' | 'uncertain' | 'fail';

export type RiskLevel = 'low' | 'medium' | 'high';

/** Critère affiché avant participation (§30) et évalué par QuestCheck (§35). */
export interface QuestRequirement {
  /** Identifiant stable, traduit à l'affichage par le client. */
  id: string;
  /** Famille de contrôle : object, object_color, environment, time, activity. */
  type: string;
  value: string;
  target?: string;
  label: string;
  emoji: string;
}

/** Modèle de quête (§73). */
export interface QuestTemplate {
  id: string;
  title: string;
  description: string;
  category: QuestCategory;
  difficulty: QuestDifficulty;
  estimatedMinutes: number;
  proofType: ProofType;
  galleryAllowed: boolean;
  xpReward: number;
  requirements: QuestRequirement[];
  safety: { riskLevel: RiskLevel; notes?: string };
  source: 'ai' | 'editorial' | 'user';
  status: 'draft' | 'approved' | 'rejected' | 'retired';
  /** Fraîcheur (§80). */
  lastUsedAt: FirebaseFirestore.Timestamp | null;
  usageCount: number;
  /** Titre normalisé, pour la détection de doublons (§79). */
  normalizedTitle: string;
  createdAt: FirebaseFirestore.Timestamp;
  rejectionReason?: string;
  authorId?: string;
}

/** Le set du jour d'une cohorte (§11). */
export interface DailyQuestSet {
  id: string;
  date: string;
  cohortId: string;
  timezoneGroup: string;
  easyQuestId: string;
  mediumQuestId: string;
  hardQuestId: string;
  worldQuestId: string;
  status: 'draft' | 'published';
  startsAt: FirebaseFirestore.Timestamp;
  endsAt: FirebaseFirestore.Timestamp;
}

/** Quête assignée à un joueur (§74). */
export interface QuestAssignment {
  questId: string;
  dailySetId: string;
  difficulty: QuestDifficulty;
  status: 'available' | 'in_progress' | 'completed' | 'expired';
  assignedAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
}

/** Un joueur (§72). */
export interface UserDoc {
  username: string;
  usernameLower: string;
  displayName: string;
  avatarUrl: string | null;
  level: number;
  xp: number;
  streak: number;
  questsCompleted: number;
  /** Date locale (YYYY-MM-DD) de la dernière participation validée (§53). */
  lastCompletionDate: string | null;
  timezone: string;
  locale: string;
  interests: QuestCategory[];
  visibility: Visibility;
  worldQuestOptIn: boolean;
  cohortId: string;
  fcmTokens: string[];
  notificationPrefs: {
    dailyQuests: boolean;
    friendActivity: boolean;
    challenges: boolean;
  };
  createdAt: FirebaseFirestore.Timestamp;
}

/** Un contrôle de QuestCheck (§35). */
export interface QuestCheckItem {
  id: string;
  label: string;
  passed: boolean;
  confidence: number;
}

export interface QuestCheckResult {
  verdict: QuestCheckVerdict;
  score: number;
  checks: QuestCheckItem[];
  reason: string;
  /** Renseigné quand un contrôle déterministe a tranché sans appeler Claude. */
  decidedBy: 'deterministic' | 'model' | 'cache';
}

/** Une participation (§75). */
export interface CompletionDoc {
  userId: string;
  questId: string;
  dailySetId: string | null;
  challengeId: string | null;
  proofPath: string;
  proofHash: string | null;
  status: CompletionStatus;
  validationScore: number;
  xpAwarded: number;
  checks: QuestCheckItem[];
  reason: string | null;
  caption: string | null;
  visibility: Visibility;
  reactionCount: number;
  commentCount: number;
  retryCount: number;
  contested: boolean;
  capturedAt: FirebaseFirestore.Timestamp | null;
  createdAt: FirebaseFirestore.Timestamp;
  validatedAt: FirebaseFirestore.Timestamp | null;
}

/** Événement du journal d'XP (§50). */
export interface XpEvent {
  amount: number;
  reason: 'quest_completion' | 'challenge_completion' | 'badge' | 'correction';
  questId: string | null;
  completionId: string | null;
  levelBefore: number;
  levelAfter: number;
  createdAt: FirebaseFirestore.Timestamp;
}

export type ChallengeState = 'pending' | 'accepted' | 'completed' | 'declined' | 'expired';

export interface ChallengeDoc {
  fromId: string;
  toId: string;
  questId: string;
  state: ChallengeState;
  createdAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
  respondedAt: FirebaseFirestore.Timestamp | null;
}

export interface NotificationDoc {
  type:
    | 'daily_quests'
    | 'challenge_received'
    | 'quest_validated'
    | 'quest_uncertain'
    | 'streak_reminder'
    | 'friend_favorite'
    | 'friend_completed';
  title: string;
  body: string;
  questId: string | null;
  actorId: string | null;
  createdAt: FirebaseFirestore.Timestamp;
  readAt: FirebaseFirestore.Timestamp | null;
}
