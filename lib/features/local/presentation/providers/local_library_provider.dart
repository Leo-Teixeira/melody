import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

final onAudioQueryProvider = Provider<OnAudioQuery>((ref) => OnAudioQuery());

final localLibraryProvider = FutureProvider<List<SongModel>>((ref) async {
  final audioQuery = ref.watch(onAudioQueryProvider);

  // Demander la permission à Android
  final status = await Permission.audio.request();
  if (!status.isGranted) {
    // Essayer l'ancienne permission pour Android < 13
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      throw Exception('Permission de lecture audio refusée');
    }
  }

  // Scanner les fichiers avec filtrage MP3/FLAC/AAC/OGG (déjà fait par défaut ou configurables basiquement)
  final songs = await audioQuery.querySongs(
    sortType: null,
    orderType: OrderType.ASC_OR_SMALLER,
    uriType: UriType.EXTERNAL, // Storage externe du tel
    ignoreCase: true,
  );

  return songs;
});
