import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../providers/local_library_provider.dart';
import '../../../library/domain/entities/song.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../../../core/connectivity/connectivity_service.dart';

class LocalLibraryPage extends ConsumerWidget {
  const LocalLibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localSongsAsync = ref.watch(localLibraryProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque Locale'),
        actions: [
          isOnlineAsync.when(
            data: (isOnline) => isOnline
                ? const Icon(Icons.wifi, color: Colors.green)
                : const Icon(Icons.wifi_off, color: Colors.red),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: localSongsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Text('Aucune musique trouvée sur l\'appareil.'),
            );
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final localSong = songs[index];
              return ListTile(
                leading: oaq.QueryArtworkWidget(
                  id: localSong.id,
                  type: oaq.ArtworkType.AUDIO,
                  nullArtworkWidget: const Icon(Icons.music_note, size: 48),
                ),
                title: Text(
                  localSong.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(localSong.artist ?? 'Artiste inconnu'),
                onTap: () {
                  final song = Song(
                    id: 'local_${localSong.id}',
                    title: localSong.title,
                    artist: localSong.artist ?? 'Artiste inconnu',
                    thumbnailUrl: '',
                    duration: Duration(
                      milliseconds: localSong.duration ?? 0,
                    ),
                    isDownloaded: true,
                    localPath: localSong.data,
                  );
                  ref.read(playerNotifierProvider.notifier).playSong(song);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerPage()),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur: $error\nVeuillez autoriser l\'accès au stockage.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
