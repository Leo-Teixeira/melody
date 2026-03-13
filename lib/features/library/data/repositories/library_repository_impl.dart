import '../../domain/entities/song.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/recent_play.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_local_datasource.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

/// Concrete implementation of [LibraryRepository].
/// Bridges the domain layer with the local SQLite datasource.
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryLocalDatasource _localDatasource;

  LibraryRepositoryImpl(this._localDatasource);

  // --- Songs ---
  @override
  Future<void> saveSong(Song song) async {
    await _localDatasource.insertSong(SongModel.fromEntity(song));
  }

  @override
  Future<Song?> getSongById(String id) async {
    return await _localDatasource.getSongById(id);
  }

  @override
  Future<List<Song>> getAllSongs() async {
    return await _localDatasource.getAllSongs();
  }

  // --- Favorites ---
  @override
  Future<void> addToFavorites(String songId) async {
    await _localDatasource.addToFavorites(songId);
  }

  @override
  Future<void> removeFromFavorites(String songId) async {
    await _localDatasource.removeFromFavorites(songId);
  }

  @override
  Future<bool> isFavorite(String songId) async {
    return await _localDatasource.isFavorite(songId);
  }

  @override
  Future<List<Song>> getFavorites() async {
    return await _localDatasource.getFavorites();
  }

  // --- Playlists ---
  @override
  Future<String> createPlaylist(Playlist playlist) async {
    return await _localDatasource.insertPlaylist(
      PlaylistModel.fromEntity(playlist),
    );
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _localDatasource.deletePlaylist(playlistId);
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    await _localDatasource.updatePlaylist(PlaylistModel.fromEntity(playlist));
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    return await _localDatasource.getAllPlaylists();
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    return await _localDatasource.getPlaylistById(id);
  }

  // --- Playlist Songs ---
  @override
  Future<void> addSongToPlaylist(
    String playlistId,
    String songId,
    int position,
  ) async {
    await _localDatasource.addSongToPlaylist(playlistId, songId, position);
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _localDatasource.removeSongFromPlaylist(playlistId, songId);
  }

  @override
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    return await _localDatasource.getPlaylistSongs(playlistId);
  }

  // --- Recent Plays ---
  @override
  Future<void> addToRecentPlays({
    required String type,
    required String referenceId,
  }) async {
    await _localDatasource.addToRecentPlays(
      type: type,
      referenceId: referenceId,
    );
  }

  @override
  Future<List<RecentPlay>> getRecentPlays() async {
    final rawRows = await _localDatasource.getRecentPlays();

    final List<RecentPlay> results = [];
    for (final row in rawRows) {
      final type = row['type'] as String;
      final refId = row['reference_id'] as String;

      Song? song;
      Playlist? playlist;

      if (type == 'song') {
        song = await _localDatasource.getSongById(refId);
      } else if (type == 'playlist') {
        playlist = await _localDatasource.getPlaylistById(refId);
      }

      results.add(
        RecentPlay(
          id: row['id'] as int?,
          type: type == 'song' ? RecentPlayType.song : RecentPlayType.playlist,
          referenceId: refId,
          playedAt: DateTime.parse(row['played_at'] as String),
          song: song,
          playlist: playlist,
        ),
      );
    }

    return results;
  }

  @override
  Future<void> removeFromRecentPlays(String referenceId) async {
    await _localDatasource.removeFromRecentPlays(referenceId);
  }
}
