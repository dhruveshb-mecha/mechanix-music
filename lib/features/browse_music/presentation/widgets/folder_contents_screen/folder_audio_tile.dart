import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

class FolderAudioTile extends StatelessWidget {
  final FileSystemEntry entry;

  const FolderAudioTile({super.key, required this.entry});

  void _playFile(BuildContext context, BrowseFolderState state) {
    final audioEntries = state.entries.where((e) => !e.isDirectory).toList();

    final songModels = audioEntries.map((e) {
      return SongModel(
        id: e.path,
        path: e.path,
        title: e.name,
        artist: 'Local File',
        album: state.folderName,
      );
    }).toList();

    final selectedSong = songModels.firstWhere(
      (song) => song.path == entry.path,
      orElse: () => SongModel(
        id: entry.path,
        path: entry.path,
        title: entry.name,
        artist: 'Local File',
        album: state.folderName,
      ),
    );

    AppLogger.i('Folder Playback: playing ${selectedSong.title} from folder');

    final playbackBloc = context.read<PlaybackBloc>();
    playbackBloc.add(PlaybackListUpdated(songModels));
    playbackBloc.add(PlaybackPlay(selectedSong));

    Navigator.pushNamed(context, AppRoutes.player);
  }

  void _onTap(
    BuildContext context,
    BrowseFolderState state,
    BrowseFolderBloc bloc,
  ) {
    if (state.isSelectionMode) {
      bloc.add(BrowseFolderToggleSelection(entry.path));
    } else {
      _playFile(context, state);
    }
  }

  void _onLongPress(
    BuildContext context,
    BrowseFolderState state,
    BrowseFolderBloc bloc,
  ) {
    if (!state.isSelectionMode) {
      bloc.add(BrowseFolderSetSelectionMode(path: entry.path));
    } else {
      bloc.add(BrowseFolderToggleSelection(entry.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseFolderBloc, BrowseFolderState>(
      buildWhen: (previous, current) {
        final previousSelected = previous.selectedPaths.contains(entry.path);
        final currentSelected = current.selectedPaths.contains(entry.path);
        return previous.isSelectionMode != current.isSelectionMode ||
            previousSelected != currentSelected;
      },
      builder: (context, state) {
        final isSelectionMode = state.isSelectionMode;
        final isSelected = state.selectedPaths.contains(entry.path);
        final bloc = context.read<BrowseFolderBloc>();

        return InkWell(
          onTap: () => _onTap(context, state, bloc),
          onLongPress: () => _onLongPress(context, state, bloc),
          splashColor: const Color(0x1AFFFFFF),
          highlightColor: const Color(0x0DFFFFFF),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (isSelectionMode)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? MusicColors.appTitleColor
                              : MusicColors.unselectedBorderColor,
                          width: 2,
                        ),
                        color: isSelected
                            ? MusicColors.appTitleColor
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  const Icon(
                    Icons.music_note_outlined,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
