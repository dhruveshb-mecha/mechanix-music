import 'dart:io';

import 'package:intl/intl.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

String getMusicDirectory() {
  final home = Platform.environment['HOME'] ?? '/home';
  return '$home${Constants.musicDirPath}';
}

String songErrorMessage(AppLocalizations l10n, SongErrorType errorType) {
  return switch (errorType) {
    SongErrorType.syncFailed => l10n.errorSyncFailed,
    SongErrorType.loadFailed => l10n.errorLoadFailed,
    SongErrorType.addSongsFailed => l10n.errorAddSongsFailed,
    SongErrorType.unknown => l10n.errorUnknown,
  };
}

String formatDuration(Duration duration) {
  if (duration == Duration.zero) return '00:00';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  final secondsStr = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final minutesStr = minutes.toString().padLeft(2, '0');
    return '$hours:$minutesStr:$secondsStr';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:$secondsStr';
  }
}

String formatDate(DateTime date, {String? locale}) {
  final formatter = DateFormat('d MMM y', locale ?? Intl.defaultLocale);
  return formatter.format(date);
}
