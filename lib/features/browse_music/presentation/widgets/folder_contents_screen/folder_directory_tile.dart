import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

class FolderDirectoryTile extends StatelessWidget {
  final FileSystemEntry entry;

  const FolderDirectoryTile({super.key, required this.entry});

  void _onTap(BuildContext context) {
    final bloc = context.read<BrowseFolderBloc>();
    if (bloc.state.isSelectionMode) {
      bloc.add(const BrowseFolderSetSelectionMode());
    }
    bloc.add(BrowseFolderNavigate(entry.path));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      splashColor: const Color(0x1AFFFFFF),
      highlightColor: const Color(0x0DFFFFFF),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 24,
                color: MusicColors.appTitleColor,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        color: MusicColors.titleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(
                        entry.modifiedDate,
                        locale: Localizations.localeOf(context).toString(),
                      ),
                      style: const TextStyle(
                        color: MusicColors.timeLabelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: MusicColors.timeLabelColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
