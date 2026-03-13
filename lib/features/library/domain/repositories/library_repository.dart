import '../entities/song.dart';
import '../entities/playlist.dart';
import '../entities/recent_play.dart';

/// Abstract repository defining the contract for library data operations.
/// The data layer implements this interface.
abstract class LibraryRepository {
  // --- Songs ---
  Future<void> saveSong(Song song);
  Future<Song?> getSongById(String id);
  Future<List<Song>> getAllSongs();

  // --- Favorites ---
  Future<void> addToFavorites(String songId);
  Future<void> removeFromFavorites(String songId);
  Future<bool> isFavorite(String songId);
  Future<List<Song>> getFavorites();

  // --- Playlists ---
  Future<String> createPlaylist(Playlist playlist);
  Future<void> deletePlaylist(String playlistId);
  Future<void> updatePlaylist(Playlist playlist);
  Future<List<Playlist>> getAllPlaylists();
  Future<Playlist?> getPlaylistById(String id);

  // --- Playlist Songs ---
  Future<void> addSongToPlaylist(
    String playlistId,
    String songId,
    int position,
  );
  Future<void> removeSongFromPlaylist(String playlistId, String songId);
  Future<List<Song>> getPlaylistSongs(String playlistId);

  // --- Recent Plays ---
  Future<void> addToRecentPlays({
    required String type,
    required String referenceId,
  });
  Future<List<RecentPlay>> getRecentPlays();
  Future<void> removeFromRecentPlays(String referenceId);
}
