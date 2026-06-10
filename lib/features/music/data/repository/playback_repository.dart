abstract class PlaybackRepository {
  Future<void> play(String url);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
  bool get isPlaying;
  Stream<Duration> get onPositionChanged;
  Stream<Duration> get onDurationChanged;
  Stream<void> get onSongComplete;
  Future<Duration?> getDuration();
  Future<Duration?> getCurrentPosition();
}
