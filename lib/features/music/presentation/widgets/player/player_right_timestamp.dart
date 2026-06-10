import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';

class PlayerRightTimestamp extends StatelessWidget {
  const PlayerRightTimestamp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      buildWhen: (previous, current) =>
          previous.songDuration != current.songDuration,
      builder: (context, state) {
        return Text(
          formatDuration(state.songDuration),
          style: const TextStyle(
            color: MusicColors.titleColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}
