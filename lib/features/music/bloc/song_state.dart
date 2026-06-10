import 'package:equatable/equatable.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

sealed class SongState extends Equatable {
  const SongState();

  @override
  List<Object?> get props => [];
}

final class SongInitial extends SongState {
  const SongInitial();
}

final class SongLoading extends SongState {
  const SongLoading();
}

final class SongLoaded extends SongState {
  final List<SongModel> songs;
  final bool hasMore;
  final bool isLoadingMore;

  const SongLoaded({
    required this.songs,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [songs, hasMore, isLoadingMore];
}

final class SongError extends SongState {
  final SongErrorType errorType;

  const SongError(this.errorType);

  @override
  List<Object?> get props => [errorType];
}
