import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class FolderErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const FolderErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(
                color: MusicColors.titleColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MusicColors.bottomBarBg,
                foregroundColor: MusicColors.titleColor,
                side: const BorderSide(color: MusicColors.borderColor),
              ),
              onPressed: onRetry,
              child: Text(localizations!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
