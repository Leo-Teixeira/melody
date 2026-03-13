import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/player_state.dart';
import '../../../library/domain/entities/song.dart';
import '../providers/player_providers.dart';
import '../../../library/presentation/providers/library_providers.dart';

/// Full-screen player page with album art, controls, and progress bar.
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final notifier = ref.read(playerNotifierProvider.notifier);
    final song = playerState.currentSong;
    print("player state duration page");
    print(song?.duration);
    if (song == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun morceau sélectionné')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Top bar — close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                        size: 32,
                      ),
                    ),
                    Text(
                      'En cours de lecture',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Row(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final favoritesAsync = ref.watch(favoritesProvider);
                            final isFavorite =
                                favoritesAsync.value?.contains(song) ?? false;
                            return IconButton(
                              onPressed: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(song);
                              },
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            _showAddToPlaylistDialog(context, ref, song);
                          },
                          icon: const Icon(
                            Icons.playlist_add_rounded,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Album art
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Song info
                Column(
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Progress bar
                _ProgressBar(playerState: playerState, notifier: notifier),

                const SizedBox(height: 24),

                // Main controls
                _PlaybackControls(playerState: playerState, notifier: notifier),

                const SizedBox(height: 16),

                // Volume slider
                _VolumeSlider(playerState: playerState, notifier: notifier),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Ajouter à une playlist',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, _) {
                final playlistsAsync = ref.watch(playlistsProvider);

                return playlistsAsync.when(
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Aucune playlist disponible. Créez-en une dans la vue Bibliothèque.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          title: Text(
                            playlist.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${playlist.songs.length} morceaux',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            ref
                                .read(libraryRepositoryProvider)
                                .addSongToPlaylist(
                                  playlist.id!,
                                  song.id,
                                  playlist.songs.length,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ajouté à ${playlist.name}'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            ref.invalidate(playlistsProvider);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Erreur: $error',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              },
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
          ],
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final PlayerState playerState;
  final PlayerNotifier notifier;

  const _ProgressBar({required this.playerState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final position = playerState.position;
    final duration = playerState.duration;
    final progressValue = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    print("player state duration progress bar");
    print(playerState.duration);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: progressValue.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).toInt(),
              );
              notifier.seekTo(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              Text(
                playerState.duration.toString(),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlaybackControls extends StatelessWidget {
  final PlayerState playerState;
  final PlayerNotifier notifier;

  const _PlaybackControls({required this.playerState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          onPressed: () => notifier.toggleShuffle(),
          icon: Icon(
            Icons.shuffle_rounded,
            color: playerState.isShuffled
                ? AppColors.primary
                : AppColors.textSecondary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Previous
        IconButton(
          onPressed: playerState.hasPrevious
              ? () => notifier.skipPrevious()
              : null,
          icon: Icon(
            Icons.skip_previous_rounded,
            color: playerState.hasPrevious
                ? AppColors.textPrimary
                : AppColors.textTertiary,
            size: 36,
          ),
        ),
        const SizedBox(width: 16),

        // Play/Pause — big central button
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: IconButton(
            onPressed: () => notifier.togglePlayPause(),
            icon: Icon(
              playerState.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Next
        IconButton(
          onPressed: playerState.hasNext ? () => notifier.skipNext() : null,
          icon: Icon(
            Icons.skip_next_rounded,
            color: playerState.hasNext
                ? AppColors.textPrimary
                : AppColors.textTertiary,
            size: 36,
          ),
        ),
        const SizedBox(width: 16),

        // Repeat (placeholder)
        IconButton(
          onPressed: () {
            // TODO: Implement repeat modes
          },
          icon: const Icon(
            Icons.repeat_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final PlayerState playerState;
  final PlayerNotifier notifier;

  const _VolumeSlider({required this.playerState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.volume_down_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        Expanded(
          child: Slider(
            value: playerState.volume,
            onChanged: (value) => notifier.setVolume(value),
          ),
        ),
        const Icon(
          Icons.volume_up_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ],
    );
  }
}
