import 'package:flutter/material.dart';
import 'package:melody/features/player/data/datasources/audio_player_service.dart';
import 'package:melody/features/search/data/datasources/youtube_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioPlayerService.instance.init();
  runApp(const TestAudioApp());
}

class TestAudioApp extends StatelessWidget {
  const TestAudioApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TestHomePage());
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});
  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  String status = 'Idle';
  
  Future<void> playTestAudio() async {
    setState(() => status = 'Searching...');
    try {
      final ds = YoutubeDataSource();
      final results = await ds.searchTracks('Daft Punk', maxResults: 1);
      if (results.isNotEmpty) {
        final track = results.first;
        setState(() => status = 'Fetching stream URL...');
        final url = await ds.getStreamUrl(track.videoId);
        setState(() => status = 'Playing in Background...');
        
        // Update notification
        AudioPlayerService.instance.updateNotification(
          id: track.videoId,
          title: track.title,
          artist: track.artist,
          thumbnailUrl: track.thumbnailUrl,
          duration: track.duration,
        );
        
        await AudioPlayerService.instance.playStreamUrl(url);
      }
    } catch(e) {
      setState(() => status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio BGR Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: playTestAudio,
              child: const Text('Play Daft Punk'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => AudioPlayerService.instance.togglePlayPause(),
              child: const Text('Toggle Play/Pause'),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Once playing, go to the Android home screen or lock the phone to verify background playback and media controls.',
                textAlign: TextAlign.center,
              )
            )
          ],
        )
      )
    );
  }
}
