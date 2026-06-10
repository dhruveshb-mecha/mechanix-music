import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';

class PlayerArtwork extends StatelessWidget {
  final double size;
  const PlayerArtwork({super.key, this.size = Constants.artworkSize});

  static const _fallback = AssetImage(MusicIcons.playerDisc);

  ImageProvider _resolveProvider(String? path) {
    if (path == null || path.isEmpty) return _fallback;

    return ResizeImage(
      FileImage(File(path)),
      width: size.toInt(),
      height: size.toInt(),
      policy: ResizeImagePolicy.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<PlaybackBloc, PlaybackState>(
        buildWhen: (prev, curr) =>
            prev.song?.artworkPath != curr.song?.artworkPath,
        builder: (context, state) {
          return ClipOval(
            child: Image(
              image: _resolveProvider(state.song?.artworkPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => Image(
                image: _fallback,
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            ),
          );
        },
      ),
    );
  }
}
