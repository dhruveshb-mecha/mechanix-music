import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_equalizer_animation.dart';

class TrackTile extends StatelessWidget {
  final SongModel song;

  const TrackTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 20,
      dense: false,
      onTap: () {
        AppLogger.i('Song tapped: ${song.title} by ${song.artist}');
        final currentSong = context.read<PlaybackBloc>().state.song;
        context.read<PlaybackBloc>().add(PlaybackPlay(song));
        if (currentSong == null) {
          Navigator.pushNamed(context, AppRoutes.player);
        }
      },
      leading: _ArtworkWidget(artworkPath: song.artworkPath),
      title: Text(
        song.title,
        style: const TextStyle(fontSize: 20, color: MusicColors.titleColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(fontSize: 16, color: MusicColors.timeLabelColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: BlocBuilder<PlaybackBloc, PlaybackState>(
        buildWhen: (previous, current) {
          final isNow = current.song?.id == song.id;
          final wasPrev = previous.song?.id == song.id;
          if (isNow != wasPrev) return true;
          if (isNow && previous.status != current.status) return true;
          return false;
        },
        builder: (context, state) {
          if (state.song?.id != song.id) return const SizedBox.shrink();

          return RepaintBoundary(
            child: EqualizerIcon(
              isPlaying: state.status == PlaybackStatus.playing,
            ),
          );
        },
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  final String? artworkPath;
  const _ArtworkWidget({this.artworkPath});

  @override
  Widget build(BuildContext context) {
    const double size = 52.0;

    if (artworkPath != null && artworkPath!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: ResizeImage(
              FileImage(File(artworkPath!)),
              width: 104,
              height: 104,
            ),
            fit: BoxFit.cover,
            // Fallback if image data is corrupted
            onError: (_, _) {
              _buildFallback();
            },
          ),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: ResizeImage(
            AssetImage(MusicIcons.artworkIcon),
            width: 104,
            height: 104,
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
