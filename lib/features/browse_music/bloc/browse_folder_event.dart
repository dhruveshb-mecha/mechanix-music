/// Events for the folder contents browser bloc.
sealed class BrowseFolderEvent {
  const BrowseFolderEvent();
}

/// Load the initial page of entries for the directory.
class BrowseFolderLoad extends BrowseFolderEvent {
  const BrowseFolderLoad();
}

/// Load the next page of entries (pagination).
class BrowseFolderLoadMore extends BrowseFolderEvent {
  const BrowseFolderLoadMore();
}

/// Navigate to a different directory path.
class BrowseFolderNavigate extends BrowseFolderEvent {
  final String path;
  const BrowseFolderNavigate(this.path);
}

/// Set selection mode: provide a path to enter mode, or null to exit mode.
class BrowseFolderSetSelectionMode extends BrowseFolderEvent {
  final String? path;
  const BrowseFolderSetSelectionMode({this.path});
}

/// Toggle the selection state for a single file path.
class BrowseFolderToggleSelection extends BrowseFolderEvent {
  final String path;
  const BrowseFolderToggleSelection(this.path);
}

/// Select or deselect all audio files in the current directory.
class BrowseFolderSelectAll extends BrowseFolderEvent {
  const BrowseFolderSelectAll();
}
