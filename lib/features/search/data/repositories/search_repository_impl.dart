import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/youtube_datasource.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final YoutubeDataSource _dataSource;

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Track>>> searchTracks(String query,
      {int maxResults = 20}) async {
    try {
      final models =
          await _dataSource.searchTracks(query, maxResults: maxResults);
      final tracks = models
          .map((m) => Track(
                videoId: m.videoId,
                title: m.title,
                artist: m.artist,
                thumbnailUrl: m.thumbnailUrl,
                duration: m.duration,
              ))
          .toList();
      return Right(tracks);
    } on YoutubeException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error during search: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getProxyUrl(String videoId) async {
    try {
      final url = await _dataSource.getProxyUrl(videoId);
      return Right(url);
    } on YoutubeException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error fetching proxy url: $e'));
    }
  }

  @override
  Future<Either<Failure, Track>> getTrackInfo(String videoId) async {
    try {
      final model = await _dataSource.getTrackInfo(videoId);
      return Right(Track(
        videoId: model.videoId,
        title: model.title,
        artist: model.artist,
        thumbnailUrl: model.thumbnailUrl,
        duration: model.duration,
      ));
    } on YoutubeException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error fetching track info: $e'));
    }
  }
}
