import '../../../../core/utils/database_service.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'package:uuid/uuid.dart';

/// Local datasource that interacts directly with Hive NoSQL database.
class LibraryLocalDatasource {
  final DatabaseService _databaseService;

  LibraryLocalDatasource(this._databaseService);

  // ==================== SONGS ====================

  Future<void> insertSong(SongModel song) async {
    await _databaseService.songsBox.put(song.id, song.toMap());
  }

  Future<SongModel?> getSongById(String id) async {
    final map = _databaseService.songsBox.get(id);
    if (map == null) return null;
    return SongModel.fromMap(map.cast<String, dynamic>());
  }

  Future<List<SongModel>> getAllSongs() async {
    final songs = _databaseService.songsBox.values
        .map((e) => SongModel.fromMap(e.cast<String, dynamic>()))
        .toList();
    songs.sort((a, b) => a.title.compareTo(b.title));
    return songs;
  }

  // ==================== FAVORITES ====================

  Future<void> addToFavorites(String songId) async {
    if (!_databaseService.favoritesBox.containsKey(songId)) {
      await _databaseService.favoritesBox.put(songId, {
        'song_id': songId,
        'added_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeFromFavorites(String songId) async {
    await _databaseService.favoritesBox.delete(songId);
  }

  Future<bool> isFavorite(String songId) async {
    return _databaseService.favoritesBox.containsKey(songId);
  }

  Future<List<SongModel>> getFavorites() async {
    final favorites = _databaseService.favoritesBox.values.toList();
    favorites.sort(
      (a, b) => (b['added_at'] as String).compareTo(a['added_at'] as String),
    );

    final List<SongModel> songs = [];
    for (var fav in favorites) {
      final song = await getSongById(fav['song_id'] as String);
      if (song != null) songs.add(song);
    }
    return songs;
  }

  // ==================== PLAYLISTS ====================

  Future<String> insertPlaylist(PlaylistModel playlist) async {
    final id = playlist.id ?? const Uuid().v4();
    final map = playlist.toMap();
    map['id'] = id;
    await _databaseService.playlistsBox.put(id, map);
    return id;
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _databaseService.playlistsBox.delete(playlistId);

    // Clean up junction entries
    final keysToDelete = [];
    for (var key in _databaseService.playlistSongsBox.keys) {
      if (key.toString().startsWith(playlistId + '_')) {
        keysToDelete.add(key);
      }
    }
    await _databaseService.playlistSongsBox.deleteAll(keysToDelete);
  }

  Future<void> updatePlaylist(PlaylistModel playlist) async {
    if (playlist.id != null) {
      await _databaseService.playlistsBox.put(playlist.id, playlist.toMap());
    }
  }

  Future<List<PlaylistModel>> getAllPlaylists() async {
    final playlists = _databaseService.playlistsBox.values
        .map((e) => PlaylistModel.fromMap(e.cast<String, dynamic>()))
        .toList();

    // Reverse created_at
    playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return playlists;
  }

  Future<PlaylistModel?> getPlaylistById(String id) async {
    final map = _databaseService.playlistsBox.get(id);
    if (map == null) return null;

    final songs = await getPlaylistSongs(id);
    return PlaylistModel.fromMap(map.cast<String, dynamic>(), songs: songs);
  }

  // ==================== PLAYLIST SONGS ====================

  Future<void> addSongToPlaylist(
    String playlistId,
    String songId,
    int position,
  ) async {
    final key = '\${playlistId}_\${songId}';
    await _databaseService.playlistSongsBox.put(key, {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': position,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final key = '\${playlistId}_\${songId}';
    await _databaseService.playlistSongsBox.delete(key);
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    final entries = _databaseService.playlistSongsBox.values
        .where((e) => e['playlist_id'] == playlistId)
        .toList();

    // Sort by position
    entries.sort(
      (a, b) => (a['position'] as int).compareTo(b['position'] as int),
    );

    final List<SongModel> songs = [];
    for (var entry in entries) {
      final song = await getSongById(entry['song_id'] as String);
      if (song != null) songs.add(song);
    }
    return songs;
  }

  // ==================== RECENT PLAYS ====================

  static const int _maxRecentPlays = 10;

  /// Add a song or playlist to recent plays.
  Future<void> addToRecentPlays({
    required String type, // 'song' or 'playlist'
    required String referenceId,
  }) async {
    final entries = _databaseService.recentPlaysBox.values.toList();

    // Find if exists
    final existingKey = _databaseService.recentPlaysBox.keys.firstWhere(
      (k) =>
          _databaseService.recentPlaysBox.get(k)?['reference_id'] ==
          referenceId,
      orElse: () => null,
    );

    if (existingKey != null) {
      // Update
      final data = _databaseService.recentPlaysBox.get(existingKey)!;
      data['played_at'] = DateTime.now().toIso8601String();
      await _databaseService.recentPlaysBox.put(existingKey, data);
      return;
    }

    // Checking length
    if (_databaseService.recentPlaysBox.length >= _maxRecentPlays) {
      // Find oldest
      entries.sort(
        (a, b) =>
            (a['played_at'] as String).compareTo(b['played_at'] as String),
      );
      final oldestRef = entries.first['reference_id'];
      final oldestKey = _databaseService.recentPlaysBox.keys.firstWhere(
        (k) =>
            _databaseService.recentPlaysBox.get(k)?['reference_id'] ==
            oldestRef,
      );
      await _databaseService.recentPlaysBox.delete(oldestKey);
    }

    // Insert new
    final newId = const Uuid().v4();
    await _databaseService.recentPlaysBox.put(newId, {
      'type': type,
      'reference_id': referenceId,
      'played_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get recent plays (songs and playlists), most recent first.
  Future<List<Map<String, dynamic>>> getRecentPlays() async {
    final entries = _databaseService.recentPlaysBox.values
        .map((e) => e.cast<String, dynamic>())
        .toList();
    entries.sort(
      (a, b) => (b['played_at'] as String).compareTo(a['played_at'] as String),
    );
    return entries.take(_maxRecentPlays).toList();
  }

  /// Remove a specific entry from recent plays.
  Future<void> removeFromRecentPlays(String referenceId) async {
    final key = _databaseService.recentPlaysBox.keys.firstWhere(
      (k) =>
          _databaseService.recentPlaysBox.get(k)?['reference_id'] ==
          referenceId,
      orElse: () => null,
    );
    if (key != null) {
      await _databaseService.recentPlaysBox.delete(key);
    }
  }
}
