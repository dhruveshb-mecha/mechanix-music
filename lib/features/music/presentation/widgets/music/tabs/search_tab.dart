import 'package:flutter/material.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(child: Text(localizations!.search));
  }
}
