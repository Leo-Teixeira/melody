/// Base class for all failures in the app.
/// Each feature can define its own specific failures extending this.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'An error occurred with the server.']);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'An error occurred with the local cache.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class PlayerFailure extends Failure {
  const PlayerFailure([
    super.message = 'An error occurred with the audio player.',
  ]);
}
