import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

List<BrowseFolderItem> buildBrowseFolderOptions(
  AppLocalizations localizations,
) => [
  BrowseFolderItem(
    icon: Icons.home_outlined,
    title: localizations.quickHome,
    path: Platform.environment['HOME'] ?? '/home',
  ),
  BrowseFolderItem(
    icon: Icons.access_time,
    title: localizations.quickRecents,
    path: '${Platform.environment['HOME'] ?? '/home'}/Recent',
  ),
  BrowseFolderItem(
    icon: Icons.download_outlined,
    title: localizations.quickDownloads,
    path: '${Platform.environment['HOME'] ?? '/home'}/Downloads',
  ),
  BrowseFolderItem(
    icon: Icons.description_outlined,
    title: localizations.quickDocuments,
    path: '${Platform.environment['HOME'] ?? '/home'}/Documents',
  ),
];
