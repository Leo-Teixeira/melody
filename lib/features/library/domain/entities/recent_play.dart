import 'song.dart';
import 'playlist.dart';

/// Type of a recent play entry.
enum RecentPlayType { song, playlist }

/// Domain entity representing a recently played item (song or playlist).
class RecentPlay {
  final int? id;
  final RecentPlayType type;
  final String
  referenceId; // YouTube video ID for songs, playlist ID (as string) for playlists
  final DateTime playedAt;

  // Populated after fetching from DB — only one will be non-null
  final Song? song;
  final Playlist? playlist;

  const RecentPlay({
    this.id,
    required this.type,
    required this.referenceId,
    required this.playedAt,
    this.song,
    this.playlist,
  });

  String get title => type == RecentPlayType.song
      ? (song?.title ?? 'Inconnu')
      : (playlist?.name ?? 'Playlist inconnue');

  String get subtitle => type == RecentPlayType.song
      ? (song?.artist ?? '')
      : '${playlist?.songs.length ?? 0} morceaux';

  String get thumbnailUrl => type == RecentPlayType.song
      ? (song?.thumbnailUrl ?? '')
      : (playlist?.thumbnailUrl ?? '');
}
