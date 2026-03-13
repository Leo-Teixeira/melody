import '../../domain/entities/song.dart';

/// Data model for Song, with JSON/Map serialization for SQLite.
class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.thumbnailUrl,
    required super.duration,
    super.albumName,
    super.isDownloaded,
    super.localPath,
  });

  /// Create a SongModel from a SQLite row (Map).
  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      thumbnailUrl: map['thumbnail_url'] as String,
      duration: Duration(milliseconds: map['duration_ms'] as int),
      albumName: map['album_name'] as String?,
      isDownloaded: (map['is_downloaded'] as int) == 1,
      localPath: map['local_path'] as String?,
    );
  }

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnail_url': thumbnailUrl,
      'duration_ms': duration.inMilliseconds,
      'album_name': albumName,
      'is_downloaded': isDownloaded ? 1 : 0,
      'local_path': localPath,
    };
  }

  /// Create a SongModel from a domain Song entity.
  factory SongModel.fromEntity(Song song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      thumbnailUrl: song.thumbnailUrl,
      duration: song.duration,
      albumName: song.albumName,
      isDownloaded: song.isDownloaded,
      localPath: song.localPath,
    );
  }
}
