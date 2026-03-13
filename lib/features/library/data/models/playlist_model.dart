import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';

/// Data model for Playlist, with JSON/Map serialization for SQLite.
class PlaylistModel extends Playlist {
  const PlaylistModel({
    super.id,
    required super.name,
    super.description,
    super.thumbnailUrl,
    required super.createdAt,
    super.songs,
  });

  /// Create a PlaylistModel from a SQLite row (Map).
  factory PlaylistModel.fromMap(Map<String, dynamic> map, {List<Song>? songs}) {
    return PlaylistModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      songs: songs ?? const [],
    );
  }

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a PlaylistModel from a domain Playlist entity.
  factory PlaylistModel.fromEntity(Playlist playlist) {
    return PlaylistModel(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      thumbnailUrl: playlist.thumbnailUrl,
      createdAt: playlist.createdAt,
      songs: playlist.songs,
    );
  }
}
