import 'package:flutter_new_pipe_extractor/flutter_new_pipe_extractor.dart';

class YoutubeException implements Exception {
  final String message;
  YoutubeException(this.message);
  @override
  String toString() => 'YoutubeException: $message';
}

class _CachedStreamUrl {
  final String url;
  final DateTime expiresAt;

  _CachedStreamUrl({required this.url, required this.expiresAt});
}

class YoutubeDataSource {
  // Stream URL cache (videoId -> {url, expiresAt})
  final Map<String, _CachedStreamUrl> _streamCache = {};

  Future<List<TrackModel>> searchTracks(
    String query, {
    int maxResults = 20,
  }) async {
    try {
      final searchInfo = await NewPipeExtractor.search(
        query,
        contentFilters: [SearchContentFilters.videos],
      );
      final List<TrackModel> results = [];

      for (final item in searchInfo) {
        if (item is VideoSearchResultItem) {
          results.add(
            TrackModel(
              videoId: item.url.split('v=').last,
              title: item.name,
              artist: item.uploaderName,
              thumbnailUrl: item.thumbnails.isNotEmpty
                  ? item.thumbnails.first.url
                  : '',
              duration: Duration(seconds: item.duration),
            ),
          );
        }
        if (results.length >= maxResults) break;
      }
      return results;
    } catch (e) {
      throw YoutubeException("Failed to search tracks: $e");
    }
  }

  Future<String> getStreamUrl(String videoId) async {
    // Check cache
    if (_streamCache.containsKey(videoId)) {
      final cached = _streamCache[videoId]!;
      if (DateTime.now().isBefore(cached.expiresAt)) {
        return cached.url;
      } else {
        _streamCache.remove(videoId);
      }
    }

    try {
      // Must use https://www.youtube.com/watch?v= format or just the videoId depending on the plugin wrapper.
      // Usually the video extractor takes the full URL in this package wrapper.
      final streamInfo = await NewPipeExtractor.getVideoInfo(
        'https://www.youtube.com/watch?v=$videoId',
      );
      final audioStreams = streamInfo.audioStreams;

      if (audioStreams.isEmpty) {
        throw YoutubeException("No audio streams found for video $videoId");
      }

      final url = _selectBestAudioFormat(audioStreams);

      // Cache URL with a 5-hour TTL
      _streamCache[videoId] = _CachedStreamUrl(
        url: url,
        expiresAt: DateTime.now().add(const Duration(hours: 5)),
      );

      return url;
    } catch (e) {
      throw YoutubeException("Failed to get stream url: $e");
    }
  }

  Future<TrackModel> getTrackInfo(String videoId) async {
    try {
      final streamInfo = await NewPipeExtractor.getVideoInfo(
        'https://www.youtube.com/watch?v=$videoId',
      );
      return TrackModel(
        videoId: videoId,
        title: streamInfo.name,
        artist: streamInfo.uploaderName,
        thumbnailUrl: streamInfo.thumbnails.isNotEmpty
            ? streamInfo.thumbnails.first.url
            : '',
        duration: Duration(seconds: streamInfo.duration),
      );
    } catch (e) {
      throw YoutubeException("Failed to get track info: $e");
    }
  }

  void clearCache() {
    _streamCache.clear();
  }

  // Select best audio format (priority: opus > m4a > webm)
  String _selectBestAudioFormat(List<AudioStream> formats) {
    if (formats.isNotEmpty) {
      // url is stored in 'content' inside YoutubeStream abstract class
      return formats.first.content;
    }
    throw YoutubeException("No suitable audio format found");
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
