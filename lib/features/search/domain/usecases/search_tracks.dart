import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/track.dart';
import '../repositories/search_repository.dart';

class SearchTracks {
  final SearchRepository repository;

  SearchTracks(this.repository);

  Future<Either<Failure, List<Track>>> call(String query, {int maxResults = 20}) async {
    return await repository.searchTracks(query, maxResults: maxResults);
  }
}
