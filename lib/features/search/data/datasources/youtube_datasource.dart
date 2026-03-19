import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeException implements Exception {
  final String message;
  YoutubeException(this.message);
  @override
  String toString() => 'YoutubeException: $message';
}

/// Local HTTP proxy that serves YouTube audio streams to ExoPlayer.
///
/// Flow:
///   1. Call [prepareVideo] BEFORE giving the URL to just_audio.
///      This fetches the YouTube manifest (the slow part) and caches the
///      direct stream URL + metadata.
///   2. Pass [urlFor(videoId)] to just_audio / ExoPlayer.
///   3. ExoPlayer hits the proxy on localhost → proxy immediately forwards
///      the request to the pre-resolved YouTube URL with correct headers.
///
/// This way ExoPlayer never waits for manifest resolution → no timeout.
class YoutubeProxyServer {
  static YoutubeProxyServer? _instance;
  static YoutubeProxyServer get instance => _instance ??= YoutubeProxyServer._();

  YoutubeProxyServer._();

  HttpServer? _server;
  final YoutubeExplode _yt = YoutubeExplode();
  int _port = 0;

  // Cache: videoId → resolved stream info
  final Map<String, _ResolvedStream> _cache = {};

  int get port => _port;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    print('[Melody] YoutubeProxyServer started on port $_port');
    _server!.listen(
      _handleRequest,
      onError: (e) {
        print('[Melody] ProxyServer listen error: $e');
      },
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _yt.close();
  }

  /// Step 1: Resolve the YouTube stream BEFORE calling just_audio.
  /// Must be called before [urlFor].
  Future<void> prepareVideo(String videoId) async {
    if (_cache[videoId]?.isExpired == true) {
      _cache.remove(videoId);
    }
    if (_cache.containsKey(videoId)) return;

    print('[Melody] Resolving manifest for $videoId...');
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [YoutubeApiClient.ios, YoutubeApiClient.androidVr],
    );

    // Prefer audio/mp4 (AAC, best ExoPlayer compat), fallback to highest bitrate
    final mp4Streams = manifest.audioOnly.where((s) => s.codec.mimeType == 'audio/mp4').toList();
    final streamInfo = mp4Streams.isNotEmpty
        ? mp4Streams.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b)
        : manifest.audioOnly.withHighestBitrate();

    // Get the direct YouTube stream URL
    final streamUri = streamInfo.url;
    print(
      '[Melody] Resolved stream for $videoId: ${streamInfo.codec.mimeType} '
      '${streamInfo.size.totalBytes} bytes',
    );

    _cache[videoId] = _ResolvedStream(
      url: streamUri,
      mimeType: streamInfo.codec.mimeType,
      totalBytes: streamInfo.size.totalBytes,
      expiresAt: DateTime.now().add(const Duration(hours: 5)),
    );
  }

  /// Step 2: Returns the localhost URL to pass to just_audio.
  /// [prepareVideo] must have been called first.
  String urlFor(String videoId) => 'http://127.0.0.1:$_port/$videoId';

  Future<void> _handleRequest(HttpRequest request) async {
    final videoId = request.uri.path.replaceFirst('/', '');
    if (videoId.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final resolved = _cache[videoId];
    if (resolved == null) {
      print('[Melody] ERROR: No cached stream for $videoId — was prepareVideo called?');
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    print('[Melody] Proxy serving $videoId (${request.headers.value('range') ?? 'full'})');

    final client = http.Client();
    try {
      // Forward the request to the real YouTube URL with correct headers
      final rangeHeader = request.headers.value('range');
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Origin': 'https://www.youtube.com',
        'Referer': 'https://www.youtube.com/',
        if (rangeHeader != null) 'Range': rangeHeader,
      };
      final ytResponse = await client.send(
        http.Request('GET', resolved.url)..headers.addAll(headers),
      );

      request.response.statusCode = ytResponse.statusCode;
      request.response.headers.set('Content-Type', resolved.mimeType);
      request.response.headers.set('Accept-Ranges', 'bytes');

      final contentLength = ytResponse.headers['content-length'];
      if (contentLength != null) {
        request.response.headers.set('Content-Length', contentLength);
      }
      final contentRange = ytResponse.headers['content-range'];
      if (contentRange != null) {
        request.response.headers.set('Content-Range', contentRange);
      }

      await request.response.addStream(ytResponse.stream);
      await request.response.close();
    } catch (e) {
      print('[Melody] ProxyServer error for $videoId: $e');
      if (!request.response.headers.persistentConnection) {
        request.response.statusCode = HttpStatus.internalServerError;
      }
      await request.response.close();
    } finally {
      client.close();
    }
  }
}

class _ResolvedStream {
  final Uri url;
  final String mimeType;
  final int totalBytes;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  const _ResolvedStream({
    required this.url,
    required this.mimeType,
    required this.totalBytes,
    required this.expiresAt,
  });
}

class YoutubeDataSource {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<TrackModel>> searchTracks(String query, {int maxResults = 20}) async {
    try {
      final searchResults = await _yt.search.search(query);
      final List<TrackModel> results = [];

      for (final video in searchResults) {
        results.add(
          TrackModel(
            videoId: video.id.value,
            title: video.title,
            artist: video.author,
            thumbnailUrl: video.thumbnails.mediumResUrl,
            duration: video.duration ?? Duration.zero,
          ),
        );
        if (results.length >= maxResults) break;
      }
      return results;
    } catch (e) {
      throw YoutubeException('Failed to search tracks: $e');
    }
  }

  /// Resolves the YouTube stream and returns the proxy URL.
  /// The manifest is pre-fetched here so ExoPlayer doesn't timeout.
  Future<String> getProxyUrl(String videoId) async {
    if (!YoutubeProxyServer.instance.isRunning) {
      await YoutubeProxyServer.instance.start();
    }
    await YoutubeProxyServer.instance.prepareVideo(videoId);
    return YoutubeProxyServer.instance.urlFor(videoId);
  }

  Future<TrackModel> getTrackInfo(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return TrackModel(
        videoId: videoId,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.mediumResUrl,
        duration: video.duration ?? Duration.zero,
      );
    } catch (e) {
      throw YoutubeException('Failed to get track info: $e');
    }
  }

  void dispose() {
    _yt.close();
  }
}

class TrackModel {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;

  TrackModel({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
  });
}
