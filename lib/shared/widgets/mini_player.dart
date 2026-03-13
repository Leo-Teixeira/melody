import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../features/player/domain/entities/player_state.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../../features/player/presentation/pages/player_page.dart';

/// Persistent mini player widget that appears above the bottom navigation bar.
/// Connected to the player state via Riverpod.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final song = playerState.currentSong;

    // Hide when nothing is playing
    if (song == null || playerState.status == PlayerStatus.idle) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(playerNotifierProvider.notifier);

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlayerPage()));
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini progress bar at the top
            if (playerState.duration.inMilliseconds > 0)
              LinearProgressIndicator(
                value:
                    playerState.position.inMilliseconds /
                    playerState.duration.inMilliseconds,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 2,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 44,
                          height: 44,
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Song info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Loading indicator
                    if (playerState.status == PlayerStatus.loading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else ...[
                      // Play/Pause
                      IconButton(
                        onPressed: () => notifier.togglePlayPause(),
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                      ),
                      // Skip next
                      if (playerState.hasNext)
                        IconButton(
                          onPressed: () => notifier.skipNext(),
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
