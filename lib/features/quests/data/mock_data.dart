import '../../../shared/models/completion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/quest.dart';
import '../../../shared/models/social.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/scene.dart';

/// Jeu de données du prototype (§125). Tout ce qui est ici sera remplacé par
/// Firestore + Cloud Functions en phase 2.
abstract final class MockData {
  static final DateTime _today = DateTime.now();

  static DateTime _at(int hour, int minute) =>
      DateTime(_today.year, _today.month, _today.day, hour, minute);

  // ---------------------------------------------------------------- Amis

  static const sarah = Friend(
    id: 'u_sarah',
    username: 'sarah',
    displayName: 'Sarah',
    level: 22,
    streak: 18,
    questsToday: 4,
  );
  static const lucas = Friend(
    id: 'u_lucas',
    username: 'lucas',
    displayName: 'Lucas',
    level: 16,
    streak: 5,
    questsToday: 2,
  );
  static const emma = Friend(
    id: 'u_emma',
    username: 'emma',
    displayName: 'Emma',
    level: 20,
    streak: 11,
    questsToday: 3,
  );
  static const thomas = Friend(
    id: 'u_thomas',
    username: 'thomas',
    displayName: 'Thomas',
    level: 12,
    streak: 3,
    questsToday: 1,
  );
  static const lea = Friend(
    id: 'u_lea',
    username: 'lea',
    displayName: 'Léa',
    level: 27,
    streak: 26,
    questsToday: 4,
  );
  static const tom = Friend(
    id: 'u_tom',
    username: 'tom',
    displayName: 'Tom',
    level: 9,
    streak: 1,
  );
  static const dylan = Friend(
    id: 'u_me',
    username: 'dylan_nc',
    displayName: 'Dylan',
    level: 14,
    streak: 12,
    questsToday: 1,
  );

  static const friends = <Friend>[lea, sarah, emma, lucas, thomas, tom];

  // ------------------------------------------------------------ Joueur

  static final me = AppUser(
    id: 'u_me',
    username: 'dylan_nc',
    displayName: 'Dylan',
    level: 14,
    xp: 1840,
    streak: 12,
    questsCompleted: 428,
    interests: const [
      QuestCategory.photography,
      QuestCategory.gaming,
      QuestCategory.travel,
      QuestCategory.nature,
    ],
    categories: const [
      CategoryProgress(category: QuestCategory.exploration, level: 18, ratio: 0.72),
      CategoryProgress(category: QuestCategory.creative, level: 12, ratio: 0.44),
      CategoryProgress(category: QuestCategory.social, level: 16, ratio: 0.6),
      CategoryProgress(category: QuestCategory.adventure, level: 8, ratio: 0.3),
      CategoryProgress(category: QuestCategory.photography, level: 21, ratio: 0.85),
    ],
    badges: const [
      Badge(id: 'fire', emoji: '🔥', title: 'On Fire', description: '7 jours de streak'),
      Badge(id: 'sunset', emoji: '🌅', title: 'Sunset Hunter', description: '10 quêtes coucher de soleil'),
      Badge(id: 'photo', emoji: '📸', title: 'Photographe', description: '100 quêtes photo'),
      Badge(id: 'explorer', emoji: '🌎', title: 'Explorer', description: '50 quêtes exploration'),
      Badge(id: 'challenger', emoji: '⚔️', title: 'Challenger', description: '25 challenges relevés'),
      Badge(
        id: 'unstoppable',
        emoji: '💫',
        title: 'Unstoppable',
        description: '30 jours de streak',
        unlocked: false,
      ),
    ],
  );

  // ------------------------------------------------------------ Quêtes

  static final Quest easy = Quest(
    id: 'q_easy_849',
    title: 'Trouve quelque chose de rouge',
    description:
        "Le truc rouge le plus stylé autour de toi. Un mur, une voiture, un fruit, "
        "à toi de voir.",
    category: QuestCategory.observation,
    difficulty: QuestDifficulty.easy,
    xpReward: 50,
    estimatedMinutes: 5,
    scene: Scene.redCar,
    participantCount: 2841,
    expiresAt: _at(23, 59),
    requirements: const [
      QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
      QuestRequirement(id: 'color_red', label: 'Objet rouge', emoji: '🔴'),
      QuestRequirement(id: 'live', label: 'Capture en direct', emoji: '📱'),
    ],
  );

  static final Quest medium = Quest(
    id: 'q_medium_221',
    title: 'Va quelque part de nouveau',
    description:
        "Une rue, un quartier, un chemin : quelque part où tu n'es jamais allé. "
        "Ramène une photo de ce que tu y as trouvé.",
    category: QuestCategory.exploration,
    difficulty: QuestDifficulty.medium,
    xpReward: 150,
    estimatedMinutes: 25,
    scene: Scene.openRoad,
    participantCount: 1204,
    expiresAt: _at(23, 59),
    requirements: const [
      QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
      QuestRequirement(id: 'outdoor', label: 'Extérieur', emoji: '🌳'),
      QuestRequirement(id: 'live', label: 'Capture en direct', emoji: '📱'),
    ],
  );

  static final Quest hard = Quest(
    id: 'q_hard_922',
    title: 'Chase le coucher de soleil',
    description:
        "Capture le coucher de soleil depuis un endroit sympa autour de toi. "
        "Sors, marche un peu, trouve ton spot.",
    category: QuestCategory.photography,
    difficulty: QuestDifficulty.hard,
    xpReward: 400,
    estimatedMinutes: 60,
    scene: Scene.sunsetOcean,
    participantCount: 18421,
    expiresAt: _at(20, 0),
    requirements: const [
      QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
      QuestRequirement(id: 'outdoor', label: 'Extérieur', emoji: '🌳'),
      QuestRequirement(id: 'before_20', label: 'Avant 20h', emoji: '🕗'),
    ],
  );

  static final Quest world = Quest(
    id: 'world_184',
    title: 'Montre-nous ton ciel',
    description:
        "Lève la tête et prends en photo le ciel au-dessus de toi, là, maintenant. "
        "Le monde entier fait la même chose aujourd'hui.",
    category: QuestCategory.photography,
    difficulty: QuestDifficulty.world,
    xpReward: 250,
    estimatedMinutes: 3,
    scene: Scene.citySky,
    participantCount: 184291,
    expiresAt: _at(23, 59),
    worldNumber: '#184',
    requirements: const [
      QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
      QuestRequirement(id: 'sky', label: 'Ciel visible', emoji: '☁️'),
      QuestRequirement(id: 'live', label: 'Capture en direct', emoji: '📱'),
    ],
  );

  static final DailyQuestSet todaySet = DailyQuestSet(
    id: 'set-pacific',
    date: _today,
    easy: easy,
    medium: medium,
    hard: hard,
    world: world,
  );

  /// Première quête proposée à la fin de l'onboarding (§70).
  static final Quest firstQuest = easy;

  // -------------------------------------------------- Quêtes tendances

  static final trending = <Quest>[
    Quest(
      id: 'q_trend_1',
      title: 'Ton café du jour',
      description: 'Montre ta boisson du moment, là où tu la bois.',
      category: QuestCategory.food,
      difficulty: QuestDifficulty.easy,
      xpReward: 50,
      estimatedMinutes: 3,
      scene: Scene.coffee,
      participantCount: 12400,
    ),
    Quest(
      id: 'q_trend_2',
      title: 'Un arbre insolite',
      description: "L'arbre le plus bizarre que tu croises aujourd'hui.",
      category: QuestCategory.nature,
      difficulty: QuestDifficulty.easy,
      xpReward: 50,
      estimatedMinutes: 8,
      scene: Scene.loneTree,
      participantCount: 8700,
    ),
    Quest(
      id: 'q_trend_3',
      title: 'Selfie avec un ami',
      description: 'Une photo avec quelqu\'un que tu croises pour de vrai.',
      category: QuestCategory.social,
      difficulty: QuestDifficulty.medium,
      xpReward: 150,
      estimatedMinutes: 20,
      scene: Scene.balcony,
      participantCount: 6100,
    ),
    Quest(
      id: 'q_trend_4',
      title: 'Un reflet intéressant',
      description: 'Flaque, vitrine, rétroviseur : trouve un beau reflet.',
      category: QuestCategory.creative,
      difficulty: QuestDifficulty.medium,
      xpReward: 150,
      estimatedMinutes: 15,
      scene: Scene.puddleReflection,
      participantCount: 5400,
    ),
  ];

  static final community = <Quest>[
    Quest(
      id: 'q_com_1',
      title: 'La pire déco de la ville',
      description: 'On veut voir ce que tu as trouvé de plus discutable.',
      category: QuestCategory.funny,
      difficulty: QuestDifficulty.easy,
      xpReward: 50,
      estimatedMinutes: 10,
      scene: Scene.streetFood,
      participantCount: 940,
    ),
    Quest(
      id: 'q_com_2',
      title: 'Ton spot secret',
      description: "L'endroit où tu vas quand tu veux être tranquille.",
      category: QuestCategory.adventure,
      difficulty: QuestDifficulty.medium,
      xpReward: 150,
      estimatedMinutes: 30,
      scene: Scene.harbor,
      participantCount: 620,
    ),
    Quest(
      id: 'q_com_3',
      title: 'Skate ou rien',
      description: 'Un spot de skate, occupé ou désert.',
      category: QuestCategory.sport,
      difficulty: QuestDifficulty.easy,
      xpReward: 50,
      estimatedMinutes: 12,
      scene: Scene.skatepark,
      participantCount: 410,
    ),
  ];

  // ------------------------------------------------------ Participations

  static List<QuestCompletion> completionsFor(String questId) => switch (questId) {
    'q_hard_922' => _sunsetCompletions,
    'q_easy_849' => _redCompletions,
    'world_184' => _skyCompletions,
    _ => _genericCompletions,
  };

  static final _sunsetCompletions = <QuestCompletion>[
    QuestCompletion(
      id: 'c_1',
      questId: 'q_hard_922',
      author: lea,
      scene: Scene.sunsetOcean,
      status: CompletionStatus.validated,
      xpAwarded: 400,
      validationScore: 0.97,
      caption: 'Quel spot incroyable ce soir 🌅',
      ago: const Duration(hours: 2),
      isFavorite: true,
      reactions: const [
        Reaction(emoji: '❤️', count: 12, mine: true),
        Reaction(emoji: '🔥', count: 8),
        Reaction(emoji: '🤯', count: 2),
      ],
      comments: [
        QuestComment(
          id: 'cm_1',
          author: thomas,
          text: "Ok là tu as gagné la journée",
          ago: const Duration(hours: 1),
        ),
        QuestComment(
          id: 'cm_2',
          author: emma,
          text: 'On y va ensemble demain ?',
          ago: const Duration(minutes: 40),
        ),
      ],
    ),
    QuestCompletion(
      id: 'c_2',
      questId: 'q_hard_922',
      author: thomas,
      scene: Scene.harbor,
      status: CompletionStatus.validated,
      xpAwarded: 400,
      validationScore: 0.92,
      caption: 'Depuis le port, pas mal non ?',
      ago: const Duration(hours: 3),
      reactions: const [Reaction(emoji: '🔥', count: 6), Reaction(emoji: '👏', count: 3)],
    ),
    QuestCompletion(
      id: 'c_3',
      questId: 'q_hard_922',
      author: sarah,
      scene: Scene.beachPalms,
      status: CompletionStatus.validated,
      xpAwarded: 400,
      validationScore: 0.95,
      caption: 'Les pieds dans l\'eau ☀️',
      ago: const Duration(hours: 4),
      reactions: const [Reaction(emoji: '❤️', count: 9), Reaction(emoji: '😂', count: 1)],
    ),
    QuestCompletion(
      id: 'c_4',
      questId: 'q_hard_922',
      author: lucas,
      scene: Scene.hikeRidge,
      status: CompletionStatus.validated,
      xpAwarded: 400,
      validationScore: 0.9,
      caption: "Monté en haut juste pour ça",
      ago: const Duration(hours: 5),
      reactions: const [Reaction(emoji: '🤯', count: 14), Reaction(emoji: '🔥', count: 4)],
    ),
  ];

  static final _redCompletions = <QuestCompletion>[
    QuestCompletion(
      id: 'c_r1',
      questId: 'q_easy_849',
      author: sarah,
      scene: Scene.redCar,
      status: CompletionStatus.validated,
      xpAwarded: 50,
      caption: 'Garée pile devant moi',
      ago: const Duration(hours: 1),
      reactions: const [Reaction(emoji: '🔥', count: 5)],
    ),
    QuestCompletion(
      id: 'c_r2',
      questId: 'q_easy_849',
      author: emma,
      scene: Scene.sunflower,
      status: CompletionStatus.validated,
      xpAwarded: 50,
      caption: 'Bon, c\'est presque rouge',
      ago: const Duration(hours: 2),
      reactions: const [Reaction(emoji: '😂', count: 11, mine: true)],
      isFavorite: true,
    ),
    QuestCompletion(
      id: 'c_r3',
      questId: 'q_easy_849',
      author: lucas,
      scene: Scene.streetFood,
      status: CompletionStatus.validated,
      xpAwarded: 50,
      caption: 'Enseigne du resto du coin',
      ago: const Duration(hours: 3),
      reactions: const [Reaction(emoji: '👏', count: 2)],
    ),
  ];

  static final _skyCompletions = <QuestCompletion>[
    QuestCompletion(
      id: 'c_s1',
      questId: 'world_184',
      author: lea,
      scene: Scene.citySky,
      status: CompletionStatus.validated,
      xpAwarded: 250,
      caption: 'Midi pile',
      ago: const Duration(hours: 4),
      reactions: const [Reaction(emoji: '❤️', count: 24)],
    ),
    QuestCompletion(
      id: 'c_s2',
      questId: 'world_184',
      author: tom,
      scene: Scene.snowPeak,
      status: CompletionStatus.validated,
      xpAwarded: 250,
      caption: 'Il fait -4 ici',
      ago: const Duration(hours: 6),
      reactions: const [Reaction(emoji: '🤯', count: 31)],
    ),
    QuestCompletion(
      id: 'c_s3',
      questId: 'world_184',
      author: emma,
      scene: Scene.desertDunes,
      status: CompletionStatus.validated,
      xpAwarded: 250,
      ago: const Duration(hours: 7),
      reactions: const [Reaction(emoji: '🔥', count: 18)],
    ),
  ];

  static final _genericCompletions = <QuestCompletion>[
    QuestCompletion(
      id: 'c_g1',
      questId: 'generic',
      author: emma,
      scene: Scene.windowReflection,
      status: CompletionStatus.validated,
      xpAwarded: 150,
      ago: const Duration(hours: 2),
      reactions: const [Reaction(emoji: '🔥', count: 4)],
    ),
    QuestCompletion(
      id: 'c_g2',
      questId: 'generic',
      author: lucas,
      scene: Scene.metro,
      status: CompletionStatus.validated,
      xpAwarded: 150,
      ago: const Duration(hours: 5),
      reactions: const [Reaction(emoji: '👏', count: 2)],
    ),
  ];

  // ------------------------------------------------------------- Social

  static final activity = <FriendActivity>[
    FriendActivity(
      id: 'a1',
      friend: sarah,
      kind: FriendActivityKind.completed,
      text: 'a complété 4 quêtes aujourd\'hui',
      ago: const Duration(hours: 2),
    ),
    FriendActivity(
      id: 'a2',
      friend: lucas,
      kind: FriendActivityKind.challenged,
      text: 't\'a lancé un défi',
      highlight: 'Trouve la voiture la plus chelou !',
      ago: const Duration(hours: 3),
    ),
    FriendActivity(
      id: 'a3',
      friend: emma,
      kind: FriendActivityKind.invited,
      text: 't\'a invité à une quête en duo',
      ago: const Duration(hours: 5),
    ),
    FriendActivity(
      id: 'a4',
      friend: tom,
      kind: FriendActivityKind.levelUp,
      text: 'a atteint le niveau 20',
      ago: const Duration(days: 1),
    ),
    FriendActivity(
      id: 'a5',
      friend: lea,
      kind: FriendActivityKind.reacted,
      text: 'a aimé ta photo',
      ago: const Duration(days: 1),
    ),
  ];

  static final challenges = <FriendChallenge>[
    FriendChallenge(
      id: 'ch1',
      from: lucas,
      quest: Quest(
        id: 'q_ch1',
        title: 'Trouve la voiture la plus chelou',
        description: 'La plus bizarre que tu croises. Tuning, couleur, état : tout compte.',
        category: QuestCategory.funny,
        difficulty: QuestDifficulty.medium,
        xpReward: 150,
        estimatedMinutes: 20,
        scene: Scene.yellowCar,
        requirements: const [
          QuestRequirement(id: 'photo', label: 'Photo', emoji: '📷'),
          QuestRequirement(id: 'car', label: 'Une voiture', emoji: '🚗'),
        ],
      ),
      state: ChallengeState.pending,
      timeLeft: const Duration(hours: 21),
    ),
    FriendChallenge(
      id: 'ch2',
      from: sarah,
      quest: Quest(
        id: 'q_ch2',
        title: 'Ton petit-déj, maintenant',
        description: 'Prouve que tu manges autre chose que des chips.',
        category: QuestCategory.food,
        difficulty: QuestDifficulty.easy,
        xpReward: 50,
        estimatedMinutes: 5,
        scene: Scene.coffee,
      ),
      state: ChallengeState.completed,
      timeLeft: Duration.zero,
    ),
    FriendChallenge(
      id: 'ch3',
      from: emma,
      quest: Quest(
        id: 'q_ch3',
        title: 'Le plus vieux truc que tu trouves',
        description: 'Objet, bâtiment, panneau : le plus ancien possible.',
        category: QuestCategory.observation,
        difficulty: QuestDifficulty.medium,
        xpReward: 150,
        estimatedMinutes: 25,
        scene: Scene.loneTree,
      ),
      state: ChallengeState.accepted,
      timeLeft: const Duration(hours: 9),
      outgoing: true,
    ),
  ];

  static final invitations = <FriendInvitation>[
    FriendInvitation(id: 'i1', friend: tom, mutualFriends: 4),
    FriendInvitation(
      id: 'i2',
      friend: const Friend(
        id: 'u_yuki',
        username: 'yuki',
        displayName: 'Yuki',
        level: 31,
        streak: 40,
      ),
      mutualFriends: 2,
    ),
  ];

  /// Amis suggérés pendant l'onboarding (§69).
  static final suggestions = <Friend>[sarah, lucas, emma, lea, thomas, tom];
}
