import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class BrowseMusicTopBar extends StatelessWidget {
  const BrowseMusicTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.browseMusicFolders,
      style: const TextStyle(
        color: MusicColors.appTitleColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
