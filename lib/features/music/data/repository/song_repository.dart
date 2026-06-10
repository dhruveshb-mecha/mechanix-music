import 'package:mechanix_music/features/music/data/models/song_change.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

abstract class SongRepository {
  Future<bool> syncInitialSongLibrary();
  Future<List<SongModel>> getSongs({required int offset, required int limit});
  Future<int> getSongCount();
  Stream<SongChange> get onSongChanged;
  Future<void> addSongsByPaths(List<String> paths);
  Future<void> deleteSongByPath(String path);
}
