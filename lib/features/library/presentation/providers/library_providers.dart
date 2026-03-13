import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/database_service.dart';
import '../../data/datasources/library_local_datasource.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/recent_play.dart';
import '../../domain/entities/song.dart';

/// Provider for the DatabaseService singleton.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for the LibraryLocalDatasource.
final libraryLocalDatasourceProvider = Provider<LibraryLocalDatasource>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return LibraryLocalDatasource(dbService);
});

/// Provider for the LibraryRepository.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final datasource = ref.watch(libraryLocalDatasourceProvider);
  return LibraryRepositoryImpl(datasource);
});

final playlistsProvider =
    AsyncNotifierProvider<PlaylistsNotifier, List<Playlist>>(
      PlaylistsNotifier.new,
    );

class PlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  late LibraryRepository _repository;

  @override
  Future<List<Playlist>> build() async {
    _repository = ref.watch(libraryRepositoryProvider);
    return await _repository.getAllPlaylists();
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    final newPlaylist = Playlist(
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    await _repository.createPlaylist(newPlaylist);
    ref.invalidateSelf();
  }

  Future<void> deletePlaylist(String id) async {
    await _repository.deletePlaylist(id);
    ref.invalidateSelf();
  }

  Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    await _repository.saveSong(song);
    await _repository.addSongToPlaylist(
      playlist.id!,
      song.id,
      playlist.songs.length,
    );
    ref.invalidateSelf();
  }
}

final recentPlaysProvider =
    AsyncNotifierProvider<RecentPlaysNotifier, List<RecentPlay>>(
      RecentPlaysNotifier.new,
    );

class RecentPlaysNotifier extends AsyncNotifier<List<RecentPlay>> {
  late LibraryRepository _repository;

  @override
  Future<List<RecentPlay>> build() async {
    _repository = ref.watch(libraryRepositoryProvider);
    return await _repository.getRecentPlays();
  }

  Future<void> addRecent(String type, String referenceId) async {
    await _repository.addToRecentPlays(type: type, referenceId: referenceId);
    ref.invalidateSelf();
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<Song>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<List<Song>> {
  late LibraryRepository _repository;

  @override
  Future<List<Song>> build() async {
    _repository = ref.watch(libraryRepositoryProvider);
    return await _repository.getFavorites();
  }

  Future<void> toggleFavorite(Song song) async {
    final isFav = await _repository.isFavorite(song.id);
    if (isFav) {
      await _repository.removeFromFavorites(song.id);
    } else {
      await _repository.saveSong(song);
      await _repository.addToFavorites(song.id);
    }
    ref.invalidateSelf();
  }
}
