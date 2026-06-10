import 'package:equatable/equatable.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

/// State for the folder contents browser.
class BrowseFolderState extends Equatable {
  const BrowseFolderState({
    required this.directoryPath,
    required this.folderName,
    this.entries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.isSelectionMode = false,
    this.selectedPaths = const {},
    this.error,
  });

  final String directoryPath;
  final String folderName;
  final List<FileSystemEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isSelectionMode;
  final Set<String> selectedPaths;
  final String? error;

  @override
  List<Object?> get props => [
    directoryPath,
    folderName,
    entries,
    isLoading,
    isLoadingMore,
    hasMore,
    isSelectionMode,
    selectedPaths,
    error,
  ];

  BrowseFolderState copyWith({
    String? directoryPath,
    String? folderName,
    List<FileSystemEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isSelectionMode,
    Set<String>? selectedPaths,
    String? error,
    bool clearError = false,
  }) {
    return BrowseFolderState(
      directoryPath: directoryPath ?? this.directoryPath,
      folderName: folderName ?? this.folderName,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      error: clearError ? null : error ?? this.error,
    );
  }
}
