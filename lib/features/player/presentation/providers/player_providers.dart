import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/providers/library_providers.dart';
import '../../data/datasources/audio_player_service.dart';
import '../../domain/entities/player_state.dart';
import '../../../search/presentation/providers/search_providers.dart';

/// Global provider for the AudioPlayerService singleton.
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the PlayerNotifier — THE SINGLE SOURCE OF TRUTH for player state.
final playerNotifierProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);

/// Notifier that owns all player state. The AudioPlayerService is a dumb player;
/// this notifier listens to its raw streams and builds the PlayerState.
class PlayerNotifier extends Notifier<PlayerState> {
  late final AudioPlayerService _service;
  final List<StreamSubscription> _subscriptions = [];

  List<Song> _originalQueue = [];

  @override
  PlayerState build() {
    _service = ref.read(audioPlayerServiceProvider);
    _service.init();

    _subscriptions.add(
      _service.rawPlayerStateStream.listen(_onPlayerStateChanged),
    );
    _subscriptions.add(
      _service.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );
    _subscriptions.add(
      _service.durationStream.listen((dur) {
        // Ne met à jour la durée via just_audio QUE SI la chanson actuelle n'a pas déjà une durée valide
        // (YouTube fournit la durée exacte pendant la recherche, le stream extrait peut se tromper)
        if (dur != null &&
            (state.currentSong?.duration == Duration.zero ||
                state.currentSong?.duration == null)) {
          state = state.copyWith(duration: dur);
        } else if (state.currentSong != null) {
          // Force la durée à rester celle de la chanson
          state = state.copyWith(duration: state.currentSong!.duration);
        }
      }),
    );
    _subscriptions.add(
      _service.volumeStream.listen((vol) {
        state = state.copyWith(volume: vol);
      }),
    );
    _subscriptions.add(
      _service.playbackEventStream.listen(
        (_) {},
        onError: (Object error) {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: error.toString(),
          );
        },
      ),
    );

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
    });

    return const PlayerState();
  }

  void _onPlayerStateChanged(ja.PlayerState rawState) {
    PlayerStatus status;
    switch (rawState.processingState) {
      case ja.ProcessingState.idle:
        status = PlayerStatus.idle;
      case ja.ProcessingState.loading:
      case ja.ProcessingState.buffering:
        status = PlayerStatus.loading;
      case ja.ProcessingState.ready:
        status = rawState.playing ? PlayerStatus.playing : PlayerStatus.paused;
      case ja.ProcessingState.completed:
        status = PlayerStatus.paused;
        _onSongCompleted();
    }
    state = state.copyWith(status: status);
  }

  void _onSongCompleted() {
    if (state.hasNext) {
      skipNext();
    } else {
      state = state.copyWith(position: Duration.zero);
    }
  }

  // ==================== PUBLIC API ====================

  Future<void> playSong(Song song) async {
    await playQueue([song], startIndex: 0);
  }

  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    _originalQueue = List.from(songs);
    final song = songs[startIndex];

    state = state.copyWith(
      currentSong: song,
      queue: songs,
      currentIndex: startIndex,
      status: PlayerStatus.loading,
      isShuffled: false,
    );

    await _loadAndPlay(song);
  }

  /// Récupère l'URL de stream (YouTube ou fichier local) et lance la lecture.
  Future<void> _loadAndPlay(Song song) async {
    try {
      // ── Fichier local ────────────────────────────────────────────────────
      if (song.isDownloaded && song.localPath != null) {
        _service.updateNotification(
          id: song.id,
          title: song.title,
          artist: song.artist,
          thumbnailUrl: song.thumbnailUrl,
          duration: song.duration,
        );
        await _service.playFile(song.localPath!);
        await _recordRecentPlay(song);
        return;
      }

      // ── Stream YouTube via local proxy ───────────────────────────────────
      final searchRepo = ref.read(searchRepositoryProvider);
      final result = await searchRepo.getProxyUrl(song.id);

      await result.fold(
        (error) async {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: error.message,
          );
        },
        (url) async {
          // ignore: avoid_print
          print('[Melody] Playing via proxy: $url');
          _service.updateNotification(
            id: song.id,
            title: song.title,
            artist: song.artist,
            thumbnailUrl: song.thumbnailUrl,
            duration: song.duration,
          );
          await _service.playUrl(url);
          await _recordRecentPlay(song);
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Impossible de lire ce morceau: $e',
      );
    }
  }

  /// Sauvegarde la chanson et l'ajoute aux écoutes récentes.
  Future<void> _recordRecentPlay(Song song) async {
    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.saveSong(song);
      await repo.addToRecentPlays(type: 'song', referenceId: song.id);
      ref.invalidate(recentPlaysProvider);
    } catch (_) {
      // Non-bloquant : on ignore les erreurs de persistance
    }
  }

  Future<void> togglePlayPause() async => await _service.togglePlayPause();
  Future<void> play() async => await _service.play();
  Future<void> pause() async => await _service.pause();
  Future<void> seekTo(Duration position) async =>
      await _service.seekTo(position);
  Future<void> setVolume(double volume) async =>
      await _service.setVolume(volume);

  Future<void> skipNext() async {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) return;

    final nextSong = state.queue[nextIndex];
    state = state.copyWith(
      currentSong: nextSong,
      currentIndex: nextIndex,
      status: PlayerStatus.loading,
    );

    await _loadAndPlay(nextSong);
  }

  Future<void> skipPrevious() async {
    if (_service.position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    final prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) return;

    final prevSong = state.queue[prevIndex];
    state = state.copyWith(
      currentSong: prevSong,
      currentIndex: prevIndex,
      status: PlayerStatus.loading,
    );

    await _loadAndPlay(prevSong);
  }

  Future<void> toggleShuffle() async {
    final isShuffled = !state.isShuffled;

    List<Song> newQueue;
    if (isShuffled) {
      newQueue = List.from(state.queue)..shuffle();
      final currentSong = state.currentSong;
      if (currentSong != null) {
        newQueue.remove(currentSong);
        newQueue.insert(0, currentSong);
      }
    } else {
      newQueue = List.from(_originalQueue);
    }

    state = state.copyWith(
      isShuffled: isShuffled,
      queue: newQueue,
      currentIndex: 0,
    );
  }

  Future<void> stop() async {
    await _service.stop();
    state = const PlayerState();
  }
}
