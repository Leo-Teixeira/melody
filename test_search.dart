import 'package:flutter/material.dart';
import 'package:melody/features/search/data/datasources/youtube_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting NewPipeExtractor search test...');
  try {
    final ds = YoutubeDataSource();
    final results = await ds.searchTracks('Daft Punk', maxResults: 3);
    
    print('=== RESULTS ===');
    for (var track in results) {
      print('- \${track.title} by \${track.artist} (\${track.videoId}) - \${track.duration.inSeconds}s');
    }
    print('===============');
    
    if (results.isNotEmpty) {
      print('Fetching stream URL for the first track...');
      final streamUrl = await ds.getStreamUrl(results.first.videoId);
      print('Stream URL: \$streamUrl');
    }
  } catch (e) {
    print('Test Failed with Error: \$e');
  }
}
