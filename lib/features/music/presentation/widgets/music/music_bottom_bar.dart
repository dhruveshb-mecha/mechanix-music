import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/music_mini_player.dart';

class MusicBottomBar extends StatelessWidget {
  const MusicBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<String> _tabIcons = [
    MusicIcons.playcircleIcon,
    MusicIcons.searchIcon,
    MusicIcons.tracksIcon,
    MusicIcons.fileIcon,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocSelector<PlaybackBloc, PlaybackState, SongModel?>(
          selector: (state) => state.song,
          builder: (context, currentSong) {
            return currentSong != null
                ? const MusicMiniPlayer()
                : const SizedBox.shrink();
          },
        ),
        SizedBox(
          height: 60,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: MusicColors.bottomBarBg,
              boxShadow: [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _tabIcons.length,
                  (index) => MusicButton(
                    iconPath: _tabIcons[index],
                    isSelected: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
