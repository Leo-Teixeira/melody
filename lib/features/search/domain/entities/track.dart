import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;

  const Track({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
  });

  @override
  List<Object?> get props => [videoId, title, artist, thumbnailUrl, duration];
}
