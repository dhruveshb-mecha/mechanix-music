// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'music_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get search => 'Search';

  @override
  String get tracks => 'Tracks';

  @override
  String get browseMusicFolders => 'Browse music folders';

  @override
  String get play => 'Play';

  @override
  String get more => 'More';

  @override
  String get quickHome => 'Home';

  @override
  String get quickRecents => 'Recents';

  @override
  String get quickDownloads => 'Downloads';

  @override
  String get quickDocuments => 'Documents';

  @override
  String get hardDrive => 'Hard Drive';

  @override
  String get root => 'Root';

  @override
  String get browseMusicBreadcrumb => 'Browse music';

  @override
  String get localFile => 'Local File';

  @override
  String get unknown => 'Unknown';

  @override
  String get noSelection => 'No selection';

  @override
  String get noTracksAvailable => 'No music tracks available';

  @override
  String get noFilesFound => 'No audio files or folders found';

  @override
  String get retry => 'Retry';

  @override
  String get tooltipCancel => 'Cancel selection';

  @override
  String get tooltipSelectAll => 'Select all';

  @override
  String get tooltipSave => 'Save to library';

  @override
  String selectedCount(num count) {
    return '$count selected';
  }

  @override
  String savingSongs(num count) {
    return 'Saving $count song(s) to library...';
  }

  @override
  String queuedSongs(num count) {
    return 'Queued $count song(s) for library import';
  }

  @override
  String get errorSyncFailed => 'Failed to sync the music library.';

  @override
  String get errorLoadFailed => 'Failed to load tracks.';

  @override
  String get errorAddSongsFailed => 'Failed to add selected songs.';

  @override
  String get errorUnknown => 'Something went wrong';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get errorPlaybackFileDeleted => 'File is deleted';

  @override
  String get errorPlaybackUnknown => 'Something went wrong';
}
