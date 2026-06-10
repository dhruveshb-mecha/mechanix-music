import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';

class FolderContentBottomBar extends StatelessWidget {
  final VoidCallback onTap;

  const FolderContentBottomBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MusicColors.bottomBarBg,
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 8,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MusicButton(
                iconPath: MusicIcons.backIcon,
                isSelected: false,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
