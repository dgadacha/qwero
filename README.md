# QUEST

Turn real life into a game.

Application sociale mobile où des groupes d'amis reçoivent chaque jour les
mêmes défis à accomplir dans la vraie vie. L'utilisateur photographie sa
preuve depuis l'app, QuestCheck la valide, et les réponses de ses amis se
débloquent.

La boucle du produit :

```
NEW QUEST → CURIOSITY → REAL WORLD ACTION → CAPTURE → QUESTCHECK
    → REWARD → FRIEND REVEAL → COMPARE → COME BACK TOMORROW
```

## État actuel

Prototype Flutter à données mockées : le parcours complet est jouable, du
splash jusqu'au feed social, sans backend. C'est l'étape « fake prototype
first » du cahier des charges.

| Phase | Contenu | État |
| --- | --- | --- |
| 1 | Parcours complet mocké, design system, 17 écrans | fait |
| 2 | Firebase (Auth, Firestore, Storage, Functions), QuestCheck via Claude | à faire |
| 3 | Analytics, Remote Config, partage externe | à faire |

## Lancer

```bash
flutter pub get
dart run build_runner build      # modèles Freezed
flutter run
```

Pour régler la direction artistique, la planche-contact des scènes :

```bash
flutter run --dart-define=START=/scenes
```

## Architecture

```
lib/
  app/          coque applicative, routes (GoRouter), navigation
  core/
    theme/      tokens de design : couleurs, espacements, rayons, typo, motion
    l10n/       libellés dérivés des enums, helpers de traduction
    dev/        outils de réglage hors parcours utilisateur
  features/
    onboarding/ splash, présentation, intérêts, amis
    quests/     tableau des quêtes, détail, état de jeu
    camera/     capture
    quest_check/ analyse de la preuve, écran de réussite
    feed/       fil par quête, révélation sociale
    explore/    World Quest, tendances, communauté
    friends/    activité, challenges, invitations, création
    profile/    profil, badges, réglages
  shared/
    models/     modèles Freezed
    photos/     scènes dessinées par le code, avatars
    widgets/    composants du design system
  l10n/         catalogues ARB (fr, en)
```

### Points structurants

- **Le serveur sera autoritaire.** XP, streak, validation et attribution des
  quêtes ne se décident jamais côté client. `GameController` simule ces
  décisions le temps du prototype ; en phase 2 chacune devient un appel de
  Cloud Function.
- **Flutter n'appelle jamais Claude directement.** Le chemin reste
  Flutter → Cloud Function → Claude.
- **Aucune image binaire.** Les visuels sont des scènes dessinées par
  `ScenePainter` à partir de recettes déclaratives (`SceneRecipe`), et les
  avatars sont générés à partir de l'identifiant. Le prototype est donc
  identique hors-ligne, et la direction artistique se règle en un endroit.
- **Le feed est organisé par quête, pas par utilisateur.** C'est le principe
  produit qui distingue QUEST d'un réseau social classique.
- **Les résultats des amis restent masqués** tant que l'utilisateur n'a pas
  participé.

## Données mockées

Tout le contenu (quêtes, amis, participations) vient de
`features/quests/data/mock_data.dart`. Les titres de quêtes n'y sont pas
traduits : en production ils sont générés par Claude dans la langue du
joueur et servis par Firestore.

## Tests

```bash
flutter test
```

Couvre QuestCheck (validation, refus, stabilité du score) et la boucle de
jeu (XP, streak une fois par jour, révélation sociale, réactions, niveaux).
