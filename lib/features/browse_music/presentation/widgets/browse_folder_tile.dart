import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class BrowseFolderTile extends StatelessWidget {
  const BrowseFolderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1AFFFFFF),
      highlightColor: const Color(0x0DFFFFFF),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 24, color: MusicColors.appTitleColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: MusicColors.titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: MusicColors.appTitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
