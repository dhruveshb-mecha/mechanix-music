import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class MusicMiniPlayer extends StatelessWidget {
  const MusicMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.player),
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 72,
        color: MusicColors.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            BlocSelector<PlaybackBloc, PlaybackState, String?>(
              selector: (state) => state.song?.artworkPath,
              builder: (context, artworkPath) =>
                  _ProgressArtwork(artworkPath: artworkPath),
            ),
            const SizedBox(width: 12),

            // Song title / artist
            Expanded(
              child:
                  BlocSelector<PlaybackBloc, PlaybackState, (String?, String?)>(
                    selector: (state) =>
                        (state.song?.title, state.song?.artist),
                    builder: (context, songInfo) {
                      final localizations = AppLocalizations.of(context);
                      final title = songInfo.$1 ?? localizations!.nowPlaying;
                      final artist = songInfo.$2 ?? localizations!.unknown;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            artist,
                            style: const TextStyle(
                              color: MusicColors.timeLabelColor,
                              fontSize: 12,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
            ),

            // Play/Pause
            BlocSelector<PlaybackBloc, PlaybackState, bool>(
              selector: (state) =>
                  state.status == PlaybackStatus.playing ||
                  state.status == PlaybackStatus.loading,
              builder: (context, isPlaying) => MusicButton(
                boxSize: 44,
                iconSize: 24,
                iconPath: isPlaying
                    ? MusicIcons.pauseIcon
                    : MusicIcons.resumeIcon,
                isSelected: false,
                onTap: () => context.read<PlaybackBloc>().add(
                  isPlaying ? const PlaybackPause() : const PlaybackResume(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressArtwork extends StatefulWidget {
  const _ProgressArtwork({required this.artworkPath});

  final String? artworkPath;

  @override
  State<_ProgressArtwork> createState() => _ProgressArtworkState();
}

class _ProgressArtworkState extends State<_ProgressArtwork> {
  double _progress = 0.0;
  bool _isTransitioning = false;
  int _durationMs = 0;

  Timer? _debounceTimer;
  StreamSubscription<Duration>? _positionSub;

  @override
  void initState() {
    super.initState();
    final repo = context.read<PlaybackRepository>();

    // Seed duration immediately
    _durationMs = context
        .read<PlaybackBloc>()
        .state
        .songDuration
        .inMilliseconds;

    // Position stream
    _positionSub = repo.onPositionChanged.listen((pos) {
      if (!_isTransitioning && _durationMs > 0 && mounted) {
        setState(() {
          _progress = (pos.inMilliseconds / _durationMs).clamp(0.0, 1.0);
        });
      }
    });
  }

  //  Duration stream listener with debounce to avoid flickering on next song
  void _onDurationChanged(int durationMs) {
    _durationMs = durationMs;
    _debounceTimer?.cancel();
    setState(() {
      _isTransitioning = true;
      _progress = 0.0;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isTransitioning = false);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaybackBloc, PlaybackState>(
      listenWhen: (prev, curr) => prev.songDuration != curr.songDuration,
      listener: (_, state) =>
          _onDurationChanged(state.songDuration.inMilliseconds),
      child: RepaintBoundary(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: _isTransitioning ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Transform.scale(
                    scaleX: -1, //anticlockwise rotation
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        MusicColors.titleColor,
                      ),
                    ),
                  ),
                ),
              ),
              ClipOval(
                child: _ArtworkWidget(path: widget.artworkPath, size: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  final String? path;
  final double size;

  const _ArtworkWidget({required this.path, required this.size});

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      final file = File(path!);

      if (file.existsSync()) {
        return Image.file(file, width: size, height: size, fit: BoxFit.cover);
      }
    }

    return Image.asset(
      MusicIcons.artworkIcon,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
