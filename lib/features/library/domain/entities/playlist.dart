import 'song.dart';

/// Domain entity representing a playlist.
class Playlist {
  final String? id;
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final List<Song> songs;

  const Playlist({
    this.id,
    required this.name,
    this.description,
    this.thumbnailUrl,
    required this.createdAt,
    this.songs = const [],
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? thumbnailUrl,
    DateTime? createdAt,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      songs: songs ?? this.songs,
    );
  }
}
