import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/library_providers.dart';
import 'favorites_page.dart';
import 'playlist_details_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bibliothèque',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                IconButton(
                  onPressed: () {
                    _showCreatePlaylistDialog(context, ref);
                  },
                  icon: const Icon(Icons.add_rounded, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Favorites shortcut
            Consumer(
              builder: (context, ref, _) {
                final favoritesAsync = ref.watch(favoritesProvider);
                final favCount = favoritesAsync.value?.length ?? 0;
                return _buildLibraryItem(
                  context,
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Favoris',
                  subtitle: '${favCount} morceaux',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesPage(),
                      ),
                    );
                  },
                );
              },
            ),
            _buildLibraryItem(
              context,
              icon: Icons.download_rounded,
              iconColor: AppColors.accent,
              title: 'Téléchargements',
              subtitle: '0 morceaux', // For later
              onTap: () {
                // TODO: Navigate to downloads
              },
            ),
            const SizedBox(height: 24),
            Text('Playlists', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.queue_music_rounded,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune playlist',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crée ta première playlist !',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: playlist.thumbnailUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    playlist.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.music_note,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                        title: Text(
                          playlist.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${playlist.songs.length} morceaux',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            ref
                                .read(playlistsProvider.notifier)
                                .deletePlaylist(playlist.id!);
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlaylistDetailsPage(playlist: playlist),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erreur: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Nouvelle Playlist',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Nom de la playlist',
              hintStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(playlistsProvider.notifier).createPlaylist(name);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Créer',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLibraryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
