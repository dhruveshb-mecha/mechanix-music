import 'package:equatable/equatable.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

class PlaybackState extends Equatable {
  final PlaybackStatus status;
  final SongModel? song;
  final List<SongModel> playbackList;
  final int currentIndex;
  final PlaybackErrorType? errorType;
  final Duration songDuration;

  const PlaybackState({
    this.status = PlaybackStatus.initial,
    this.song,
    this.playbackList = const [],
    this.currentIndex = 0,
    this.errorType,
    this.songDuration = Duration.zero,
  });

  bool get hasNext => currentIndex < playbackList.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlaybackState copyWith({
    PlaybackStatus? status,
    SongModel? song,
    List<SongModel>? playbackList,
    int? currentIndex,
    PlaybackErrorType? errorType,
    Duration? songDuration,
  }) => PlaybackState(
    status: status ?? this.status,
    song: song ?? this.song,
    playbackList: playbackList ?? this.playbackList,
    currentIndex: currentIndex ?? this.currentIndex,
    errorType: errorType ?? this.errorType,
    songDuration: songDuration ?? this.songDuration,
  );

  @override
  List<Object?> get props => [
    status,
    song,
    playbackList,
    currentIndex,
    errorType,
    songDuration,
  ];
}
