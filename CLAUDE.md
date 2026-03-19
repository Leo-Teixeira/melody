# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

- Flutter 3.38.9 / Dart 3.10.8
- Navigation : go_router 17.1.0
- State : Riverpod 3.3.1 sans code génération
- Audio : just_audio + audio_service (background)
- Storage : Hive 1.1.0 (5 boxes : songs, favorites, playlists, playlist_songs, recent_plays)
- Réseau : youtube_explode_dart, dio
- Patterns : dartz Either<Failure, T>, Equatable sur id uniquement
- Cible : Android (+ iOS si applicable)

## Commands

```bash
flutter run
flutter build apk / appbundle
flutter test
flutter analyze
dart fix --apply
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

Clean Architecture par feature, avec Riverpod comme couche de state management.

```
lib/
├── core/           # Transversal: theme, DI, error types, database
├── features/
│   ├── library/    # Favoris, playlists, historique
│   ├── local/      # Musique stockée sur l'appareil
│   ├── player/     # Lecteur audio (queue, shuffle, position…)
│   ├── search/     # Recherche YouTube
│   └── shared/     # Widgets partagés entre features (MiniPlayer)
└── main.dart
```

Chaque feature suit le pattern `data/domain/presentation` :
- **domain** : entités pures, interfaces repository, use cases
- **data** : implémentations datasources/repos, modèles avec sérialisation
- **presentation** : pages, providers Riverpod, widgets

## Initialisation (`main.dart`)

Ordre important :
1. `dotenv.load(".env")` — variables d'environnement
2. `DatabaseService().init()` — Hive
3. `AudioPlayerService.instance.init()` — lecteur audio
4. `ProviderScope` — Riverpod

## À ne pas faire

- Ne pas appeler les datasources en dehors des repositories
- Ne pas modifier `DatabaseService.init()` sans migration des boxes

## Points d'attention

- **Supabase** est importé dans pubspec mais pas encore intégré — préparé pour une v2 backend
- **Navigation** : MaterialApp + `Navigator.push` direct, pas de GoRouter
- Les entités domain utilisent `Equatable` avec comparaison sur `id` uniquement
- L'état `PlayerState` est immutable avec `copyWith`
