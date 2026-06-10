import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class FolderEmptyState extends StatelessWidget {
  const FolderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: MusicColors.timeLabelColor,
          ),
          const SizedBox(height: 16),
          Text(
            localizations!.noFilesFound,
            style: const TextStyle(
              color: MusicColors.timeLabelColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
