import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/music/bloc/song_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_empty_screen.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_list.dart';

class Track extends StatelessWidget {
  const Track({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongBloc, SongState>(
      builder: (context, state) {
        if (state is SongLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SongError) {
          final message = songErrorMessage(
            AppLocalizations.of(context)!,
            state.errorType,
          );
          return Center(child: Text(message));
        }

        if (state is SongLoaded) {
          if (state.songs.isEmpty) {
            return const TrackEmptyScreen();
          }

          return TrackList(songs: state.songs);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
