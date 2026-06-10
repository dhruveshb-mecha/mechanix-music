import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(),

        // previous icon
        BlocSelector<PlaybackBloc, PlaybackState, bool>(
          selector: (state) => state.hasPrevious,
          builder: (context, hasPrevious) {
            return MusicButton(
              boxSize: 48,
              iconPath: MusicIcons.previousIcon,
              isSelected: false,
              onTap: hasPrevious
                  ? () => context.read<PlaybackBloc>().add(
                      const PlaybackPlayPrevious(),
                    )
                  : null,
            );
          },
        ),

        // pause/resume icon
        BlocSelector<PlaybackBloc, PlaybackState, bool>(
          selector: (state) =>
              state.status == PlaybackStatus.playing ||
              state.status == PlaybackStatus.loading,
          builder: (context, isPlaying) {
            return MusicButton(
              boxSize: 48,
              iconPath: isPlaying
                  ? MusicIcons.pauseIcon
                  : MusicIcons.resumeIcon,
              isSelected: false,
              onTap: () {
                if (isPlaying) {
                  context.read<PlaybackBloc>().add(const PlaybackPause());
                } else {
                  context.read<PlaybackBloc>().add(const PlaybackResume());
                }
              },
            );
          },
        ),

        // next icon
        BlocSelector<PlaybackBloc, PlaybackState, bool>(
          selector: (state) => state.hasNext,
          builder: (context, hasNext) {
            return MusicButton(
              boxSize: 48,
              iconPath: MusicIcons.nextIcon,
              isSelected: false,
              onTap: hasNext
                  ? () => context.read<PlaybackBloc>().add(
                      const PlaybackPlayNext(),
                    )
                  : null,
            );
          },
        ),
        const SizedBox(),
      ],
    );
  }
}
