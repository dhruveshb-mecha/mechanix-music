enum SongErrorType { syncFailed, loadFailed, addSongsFailed, unknown }

enum PlaybackStatus { initial, loading, playing, paused, stopped, failure }

enum SongChangeType { upsert, delete }

enum PlaybackErrorType { fileDeleted, unknown }
