import 'package:equatable/equatable.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

abstract class PlaybackEvent extends Equatable {
  const PlaybackEvent();

  @override
  List<Object?> get props => [];
}

class PlaybackPlay extends PlaybackEvent {
  final SongModel song;
  const PlaybackPlay(this.song);

  @override
  List<Object?> get props => [song];
}

class PlaybackPause extends PlaybackEvent {
  const PlaybackPause();
}

class PlaybackResume extends PlaybackEvent {
  const PlaybackResume();
}

class PlaybackSeek extends PlaybackEvent {
  final Duration position;
  const PlaybackSeek(this.position);

  @override
  List<Object?> get props => [position];
}

class PlaybackStop extends PlaybackEvent {
  const PlaybackStop();
}

class PlaybackPlayNext extends PlaybackEvent {
  const PlaybackPlayNext();
}

class PlaybackPlayPrevious extends PlaybackEvent {
  const PlaybackPlayPrevious();
}

class PlaybackListUpdated extends PlaybackEvent {
  final List<SongModel> playbackList;
  const PlaybackListUpdated(this.playbackList);

  @override
  List<Object?> get props => [playbackList];
}

class PlaybackDurationUpdated extends PlaybackEvent {
  final Duration duration;
  const PlaybackDurationUpdated(this.duration);

  @override
  List<Object?> get props => [duration];
}
