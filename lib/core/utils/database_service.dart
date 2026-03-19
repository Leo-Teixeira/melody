import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton service managing the local Hive database (NoSQL).
/// Replaces SQLite to ensure full Web compatibility.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Box references (equivalent to tables)
  late final Box<Map<dynamic, dynamic>> _songsBox;
  late final Box<Map<dynamic, dynamic>> _favoritesBox;
  late final Box<Map<dynamic, dynamic>> _playlistsBox;
  late final Box<Map<dynamic, dynamic>>
  _playlistSongsBox; // Junction-like logic
  late final Box<Map<dynamic, dynamic>> _recentPlaysBox;
  late final Box<Map<dynamic, dynamic>> _streamCacheBox;

  // Accessors
  Box<Map<dynamic, dynamic>> get songsBox => _songsBox;
  Box<Map<dynamic, dynamic>> get favoritesBox => _favoritesBox;
  Box<Map<dynamic, dynamic>> get playlistsBox => _playlistsBox;
  Box<Map<dynamic, dynamic>> get playlistSongsBox => _playlistSongsBox;
  Box<Map<dynamic, dynamic>> get recentPlaysBox => _recentPlaysBox;
  Box<Map<dynamic, dynamic>> get streamCacheBox => _streamCacheBox;

  Future<void> init() async {
    if (_isInitialized) return;

    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
    }

    _songsBox = await Hive.openBox<Map<dynamic, dynamic>>('songs');
    _favoritesBox = await Hive.openBox<Map<dynamic, dynamic>>('favorites');
    _playlistsBox = await Hive.openBox<Map<dynamic, dynamic>>('playlists');
    _playlistSongsBox = await Hive.openBox<Map<dynamic, dynamic>>(
      'playlist_songs',
    );
    _recentPlaysBox = await Hive.openBox<Map<dynamic, dynamic>>('recent_plays');
    _streamCacheBox = await Hive.openBox<Map<dynamic, dynamic>>('stream_cache');

    _isInitialized = true;
  }

  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
