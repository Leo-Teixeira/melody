/// Domain entity representing a song/track.
/// This is the pure business object, independent of any data source.
class Song {
  final String id; // YouTube video ID
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;
  final String? albumName;
  final bool isDownloaded;
  final String? localPath; // Path to downloaded audio file

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.albumName,
    this.isDownloaded = false,
    this.localPath,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    Duration? duration,
    String? albumName,
    bool? isDownloaded,
    String? localPath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      albumName: albumName ?? this.albumName,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
