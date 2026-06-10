import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';
import 'package:path/path.dart' as p;

class BreadcrumbsHeader extends StatelessWidget {
  final String currentPath;
  final String initialPath;
  final String rootTitle;
  final ValueChanged<String> onNavigate;
  final VoidCallback onPop;

  const BreadcrumbsHeader({
    super.key,
    required this.currentPath,
    required this.initialPath,
    required this.rootTitle,
    required this.onNavigate,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final browseMusicText = localizations!.browseMusicBreadcrumb;
    final rootText = localizations.root;

    final segments = <({String name, String path})>[];
    segments.add((name: browseMusicText, path: 'pop'));

    if (currentPath.startsWith(initialPath)) {
      final relative = currentPath.substring(initialPath.length);
      final parts = relative.split('/').where((s) => s.isNotEmpty).toList();

      segments.add((name: rootTitle, path: initialPath));

      String current = initialPath;
      for (final part in parts) {
        current = p.join(current, part);
        segments.add((name: part, path: current));
      }
    } else {
      segments.add((name: rootText, path: '/'));
      if (currentPath != '/') {
        final parts = currentPath
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList();
        String current = '';
        for (final part in parts) {
          current += '/$part';
          segments.add((name: part, path: current));
        }
      }
    }

    return Container(
      height: 64,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: MusicColors.dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(segments.length, (index) {
            final segment = segments[index];
            final isLast = index == segments.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isLast
                      ? null
                      : () {
                          if (segment.path == 'pop') {
                            onPop();
                          } else {
                            onNavigate(segment.path);
                          }
                        },
                  child: Text(
                    segment.name,
                    style: TextStyle(
                      color: isLast
                          ? MusicColors.white
                          : MusicColors.timeLabelColor,
                      fontSize: 18,
                      fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '/',
                      style: TextStyle(
                        color: MusicColors.timeLabelColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
