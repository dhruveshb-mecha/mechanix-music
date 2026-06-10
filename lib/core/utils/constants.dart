class Constants {
  static const String dbPath = '.config/mechanix_apps/music/objectbox';
  static const String musicDirPath = '/Music';
  static const Duration debounceDuration = Duration(milliseconds: 300);
  static const audioExt = [
    '.mp3',
    '.wav',
    '.flac',
    '.m4a',
    '.aac',
    '.ogg',
    '.opus',
  ];
  static const int pageSize = 20;
  static const loadMoreSongsThreshold =
      5; // to fetch next songs on list when 5 are remain.

  static const double artworkSize = 280.0;
}
