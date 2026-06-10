import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class BrowseSectionHeader extends StatelessWidget {
  const BrowseSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: MusicColors.timeLabelColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
