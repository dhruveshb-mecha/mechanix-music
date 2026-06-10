import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';
import 'package:mechanix_music/features/browse_music/presentation/screens/browse_music_screen.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/browse_music_top_bar.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/music_bottom_bar.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/play_tab.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/search_tab.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track_tab.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  int _currentIndex = 2; // default to track tab

  final List<Widget> _tabs = const [
    Center(child: PlayTab()),
    Center(child: SearchTab()),
    TrackTab(),
    Center(child: BrowseMusicScreen()),
  ];

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return switch (_currentIndex) {
      0 => AppBar(title: Text(l10n.nowPlaying)),
      1 => AppBar(title: Text(l10n.search)),
      2 => AppBar(title: Text(l10n.tracks)),
      3 => AppBar(title: const BrowseMusicTopBar()),
      _ => AppBar(title: Text(l10n.tracks)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<PlaybackBloc, PlaybackState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PlaybackStatus.failure,
      listener: (context, state) {
        if (state.errorType != null) {
          final l10n = AppLocalizations.of(context)!;
          final message = switch (state.errorType!) {
            PlaybackErrorType.fileDeleted => l10n.errorPlaybackFileDeleted,
            PlaybackErrorType.unknown => l10n.errorPlaybackUnknown,
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade900,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(l10n),
        extendBodyBehindAppBar: false,
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: MusicBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
