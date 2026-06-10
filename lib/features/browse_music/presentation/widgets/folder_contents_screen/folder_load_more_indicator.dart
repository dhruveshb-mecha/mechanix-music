import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class FolderLoadMoreIndicator extends StatelessWidget {
  const FolderLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(MusicColors.titleColor),
        ),
      ),
    );
  }
}
