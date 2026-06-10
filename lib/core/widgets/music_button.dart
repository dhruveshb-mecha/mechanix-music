import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class MusicButton extends StatelessWidget {
  const MusicButton({
    super.key,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
    this.boxSize = 44,
    this.iconSize = 28,
    this.iconColor,
  });

  final String iconPath;
  final bool isSelected;
  final VoidCallback? onTap;
  final double boxSize;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: boxSize, height: boxSize),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          isSelected ? MusicColors.borderColor : Colors.transparent,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x1AFFFFFF);
          }
          return Colors.transparent;
        }),
      ),
      icon: Image.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
        color: onTap == null
            ? MusicColors.titleColor.withValues(alpha: 0.3)
            : (iconColor ??
                  (isSelected ? Colors.white : MusicColors.titleColor)),
      ),
    );
  }
}
