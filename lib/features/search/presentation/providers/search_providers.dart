import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/youtube_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/search_repository.dart';
import '../../../library/domain/entities/song.dart';

final youtubeDataSourceProvider = Provider<YoutubeDataSource>((ref) {
  final dataSource = YoutubeDataSource();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dataSource = ref.watch(youtubeDataSourceProvider);
  return SearchRepositoryImpl(dataSource);
});

/// Provider for search results using AsyncNotifier.
final searchResultsProvider = AsyncNotifierProvider<SearchNotifier, List<Song>>(SearchNotifier.new);

/// Notifier managing search state.
class SearchNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() async {
    return [];
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    final repository = ref.read(searchRepositoryProvider);
    final result = await repository.searchTracks(query);

    result.fold((error) => state = AsyncValue.error(error.message, StackTrace.current), (tracks) {
      final songs = tracks
          .map(
            (t) => Song(
              id: t.videoId,
              title: t.title,
              artist: t.artist,
              duration: t.duration,
              thumbnailUrl: t.thumbnailUrl,
            ),
          )
          .toList();
      state = AsyncValue.data(songs);

      // Pre-fetch manifests for the first 5 results in the background.
      // If the user taps one, the stream is already cached → instant play.
      final dataSource = ref.read(youtubeDataSourceProvider);
      for (final song in songs.take(5)) {
        dataSource.prefetchManifest(song.id);
      }
    });
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}
