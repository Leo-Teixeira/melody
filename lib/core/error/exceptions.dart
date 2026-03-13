/// Thrown when there is a server-side (API) error.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred.']);
}

/// Thrown when there is a local cache error.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error occurred.']);
}
