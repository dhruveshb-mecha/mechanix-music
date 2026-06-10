import 'package:flutter/material.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(child: Text(localizations!.play));
  }
}
