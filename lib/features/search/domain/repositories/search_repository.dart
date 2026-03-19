import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/track.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<Track>>> searchTracks(String query,
      {int maxResults = 20});
  Future<Either<Failure, String>> getProxyUrl(String videoId);
  Future<Either<Failure, Track>> getTrackInfo(String videoId);
}
