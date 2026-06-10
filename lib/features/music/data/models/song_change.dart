import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

class SongChange {
  final SongChangeType type;
  final SongModel song;

  const SongChange({required this.type, required this.song});
}
