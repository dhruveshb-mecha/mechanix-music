import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class PlayerLeftTimestamp extends StatelessWidget {
  const PlayerLeftTimestamp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PlaybackRepository>();
    return StreamBuilder<Duration>(
      stream: repo.onPositionChanged,
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Text(
          formatDuration(position),
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
