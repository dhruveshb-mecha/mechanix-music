import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/exceptions/app_exceptions.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/bloc/song_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackState> {
  final PlaybackRepository _repo;
  Timer? _playDebounce; // Handle rapid song clicks efficiently
  final SongBloc _songBloc;
  late final StreamSubscription<SongState> _songSub;

  PlaybackBloc(this._repo, this._songBloc)
    : super(
        PlaybackState(
          playbackList: _songBloc.state is SongLoaded
              ? (_songBloc.state as SongLoaded).songs
              : [],
        ),
      ) {
    on<PlaybackPlay>(_onPlay);
    on<PlaybackPause>(_onPause);
    on<PlaybackResume>(_onResume);
    on<PlaybackSeek>(_onSeek);
    on<PlaybackStop>(_onStop);
    on<PlaybackPlayNext>(_onPlayNext);
    on<PlaybackPlayPrevious>(_onPlayPrevious);
    on<PlaybackListUpdated>(_onPlaybackListUpdated);
    on<PlaybackDurationUpdated>(_onDurationUpdated);

    _listenToSongBloc();
    _listenToSongComplete();
    _listenToDurationChanged();
  }

  void _listenToDurationChanged() {
    _repo.onDurationChanged.listen((duration) async {
      if (duration.inMilliseconds > 0) {
        AppLogger.i('[PlaybackBloc] Duration ready: $duration');
        add(PlaybackDurationUpdated(duration));
        return;
      }
    });
  }

  void _onDurationUpdated(
    PlaybackDurationUpdated event,
    Emitter<PlaybackState> emit,
  ) {
    emit(state.copyWith(songDuration: event.duration));
  }

  void _listenToSongBloc() {
    _songSub = _songBloc.stream.listen((songState) {
      AppLogger.i('[PlaybackBloc] Song state updated: $songState');
      if (songState is SongLoaded) {
        add(PlaybackListUpdated(songState.songs));
      }
    });
  }

  void _listenToSongComplete() {
    _repo.onSongComplete.listen((_) {
      AppLogger.i('[PlaybackBloc] Song completed, attempting to play next...');
      if (state.hasNext) {
        add(const PlaybackPlayNext());
      } else {
        AppLogger.i('[PlaybackBloc] No next song available — pausing playback');
        add(const PlaybackPause());
      }
    });
  }

  void _onPlaybackListUpdated(
    PlaybackListUpdated event,
    Emitter<PlaybackState> emit,
  ) {
    final updatedList = event.playbackList;

    // No song playing yet — just sync the list
    if (state.song == null) {
      emit(state.copyWith(playbackList: updatedList));
      return;
    }

    // Find current song in the updated list
    final newIndex = updatedList.indexOf(state.song!);

    if (newIndex == -1) {
      // Current song was deleted — stop playback
      _repo.stop();
      emit(const PlaybackState(status: PlaybackStatus.stopped));
      return;
    }

    // Song still exists — update list and correct the index
    emit(state.copyWith(playbackList: updatedList, currentIndex: newIndex));
  }

  Future<void> _onPlay(PlaybackPlay event, Emitter<PlaybackState> emit) async {
    final index = state.playbackList.indexOf(event.song);

    // Cancel pending debounce
    _playDebounce?.cancel();

    // Stop old song immediately — no more audio, no stale duration
    if (_repo.isPlaying) await _repo.stop();

    // UI updates immediately
    emit(
      state.copyWith(
        status: PlaybackStatus.loading,
        song: event.song,
        currentIndex: index,
        songDuration: Duration.zero, // reset stale duration
      ),
    );

    final completer =
        Completer<void>(); // hold the emit state to update on debounce complete

    _playDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        await _repo.play(event.song.path);
        completer.complete();
      } on PlaybackFileNotFoundException catch (e) {
        AppLogger.e('Error during playback (file not found): $e');
        emit(
          state.copyWith(
            status: PlaybackStatus.failure,
            errorType: PlaybackErrorType.fileDeleted,
          ),
        );

        if (state.hasNext) {
          add(const PlaybackPlayNext());
        }
        unawaited(_songBloc.songRepository.deleteSongByPath(event.song.path));

        completer.completeError(e);
      } catch (e) {
        AppLogger.e('Error during playback: $e');
        emit(
          state.copyWith(
            status: PlaybackStatus.failure,
            errorType: PlaybackErrorType.unknown,
          ),
        );
        completer.completeError(e);
      }
    });

    try {
      await completer.future;
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      // Debounce timer catch block already emitted the failure state.
      AppLogger.e('Error during playback: $e');
    }
  }

  Future<void> _onPlayNext(
    PlaybackPlayNext event,
    Emitter<PlaybackState> emit,
  ) async {
    if (!state.hasNext) return;

    final nextIndex = state.currentIndex + 1;
    final nextSong = state.playbackList[nextIndex];

    // Remaining songs after this next play
    final remaining = state.playbackList.length - 1 - nextIndex;
    if (remaining <= Constants.loadMoreSongsThreshold) {
      _songBloc.add(const SongLoadMore());
    }

    add(PlaybackPlay(nextSong));
  }

  Future<void> _onPlayPrevious(
    PlaybackPlayPrevious event,
    Emitter<PlaybackState> emit,
  ) async {
    if (!state.hasPrevious) return;

    final prevSong = state.playbackList[state.currentIndex - 1];
    add(PlaybackPlay(prevSong));
  }

  Future<void> _onPause(
    PlaybackPause event,
    Emitter<PlaybackState> emit,
  ) async {
    if (state.song == null) return;
    if (state.status != PlaybackStatus.playing && !_repo.isPlaying) {
      return;
    }
    try {
      await _repo.pause();
      emit(
        state.copyWith(
          status: _repo.isPlaying
              ? PlaybackStatus.playing
              : PlaybackStatus.paused,
        ),
      );
    } catch (e) {
      AppLogger.e('Error during pause: $e');

      emit(
        state.copyWith(
          status: PlaybackStatus.failure,
          errorType: PlaybackErrorType.unknown,
        ),
      );
    }
  }

  Future<void> _onResume(
    PlaybackResume event,
    Emitter<PlaybackState> emit,
  ) async {
    if (state.song == null) return;
    if (state.status == PlaybackStatus.playing || _repo.isPlaying) {
      return;
    }

    try {
      await _repo.resume();
      emit(
        state.copyWith(
          status: _repo.isPlaying
              ? PlaybackStatus.playing
              : PlaybackStatus.paused,
        ),
      );
    } catch (e) {
      AppLogger.e('Error during resume: $e');

      emit(
        state.copyWith(
          status: PlaybackStatus.failure,
          errorType: PlaybackErrorType.unknown,
        ),
      );
    }
  }

  Future<void> _onSeek(PlaybackSeek event, Emitter<PlaybackState> emit) async {
    try {
      if (state.song == null) return;
      await _repo.seek(event.position);
    } catch (e) {
      AppLogger.e('Error during seek: $e');

      emit(
        state.copyWith(
          status: PlaybackStatus.failure,
          errorType: PlaybackErrorType.unknown,
        ),
      );
    }
  }

  Future<void> _onStop(PlaybackStop event, Emitter<PlaybackState> emit) async {
    try {
      await _repo.stop();
      emit(const PlaybackState(status: PlaybackStatus.stopped));
    } catch (e) {
      AppLogger.e('Error during stop: $e');

      emit(
        state.copyWith(
          status: PlaybackStatus.failure,
          errorType: PlaybackErrorType.unknown,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _playDebounce?.cancel();
    await _songSub.cancel();
    await _repo.dispose();
    return super.close();
  }
}
