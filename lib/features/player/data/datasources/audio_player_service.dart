import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Thin wrapper around just_audio + audio_service.
/// This service is a "dumb" player: it plays audio and exposes raw streams.
/// It does NOT manage any PlayerState — that's the Notifier's job.
class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._internal();
  factory AudioPlayerService() => instance;
  AudioPlayerService._internal();

  late final AudioPlayer _player;
  late final _MelodyAudioHandler _melodyHandler;
  bool _isInitialized = false;

  // ==================== RAW STREAMS (for the Notifier to listen to) ====================

  Stream<PlayerState> get rawPlayerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;

  // ==================== INIT ====================

  Future<void> init() async {
    if (_isInitialized) return;

    // Default constructor — proxy must stay active for StreamAudioSource to work.
    _player = AudioPlayer();

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _melodyHandler = _MelodyAudioHandler(_player);
    await AudioService.init(
      builder: () => _melodyHandler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.leoteixeira.melody.audio',
        androidNotificationChannelName: 'Melody',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    _isInitialized = true;
  }

  // ==================== PLAYBACK ACTIONS ====================

  /// Play from a URL (can be localhost proxy or local file URI).
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.setUrl(url);
    await _player.play();
  }

  /// Play from a local file path.
  Future<void> playFile(String filePath) async {
    await _player.stop();
    await _player.setFilePath(filePath);
    await _player.play();
  }

  /// Update the OS media notification.
  void updateNotification({
    required String id,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required Duration duration,
  }) {
    _melodyHandler.setCurrentMediaItem(
      MediaItem(
        id: id,
        title: title,
        artist: artist,
        artUri: Uri.parse(thumbnailUrl),
        duration: duration,
      ),
    );
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

// ==================== AUDIO HANDLER ====================

class _MelodyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  _MelodyAudioHandler(this._player) {
    _player.playbackEventStream.listen(_broadcastState);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  void setCurrentMediaItem(MediaItem item) {
    mediaItem.add(item);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
