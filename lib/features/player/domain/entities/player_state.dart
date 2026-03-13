import '../../../library/domain/entities/song.dart';

/// Represents the current state of the audio player.
enum PlayerStatus { idle, loading, playing, paused, error }

/// Domain entity representing the player's current state.
class PlayerState {
  final Song? currentSong;
  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isShuffled;
  final List<Song> queue;
  final int currentIndex;
  final String? errorMessage;

  const PlayerState({
    this.currentSong,
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isShuffled = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.errorMessage,
  });

  PlayerState copyWith({
    Song? currentSong,
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isShuffled,
    List<Song>? queue,
    int? currentIndex,
    String? errorMessage,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isShuffled: isShuffled ?? this.isShuffled,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isPlaying => status == PlayerStatus.playing;
  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;
}
