import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/playlist.dart';
import '../providers/library_providers.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../player/presentation/pages/player_page.dart';

class PlaylistDetailsPage extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailsPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-fetch playlist to get latest songs
    final playlistsAsync = ref.watch(playlistsProvider);
    final currentPlaylist =
        playlistsAsync.value?.firstWhere(
          (p) => p.id == playlist.id,
          orElse: () => playlist,
        ) ??
        playlist;

    final songs = currentPlaylist.songs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              ref
                  .read(playlistsProvider.notifier)
                  .deletePlaylist(currentPlaylist.id!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La playlist est vide.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      ref
                          .read(libraryRepositoryProvider)
                          .removeSongFromPlaylist(currentPlaylist.id!, song.id);
                      ref.invalidate(playlistsProvider);
                    },
                  ),
                  onTap: () {
                    ref
                        .read(playerNotifierProvider.notifier)
                        .playQueue(songs, startIndex: index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerPage(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
