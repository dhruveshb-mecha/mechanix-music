import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository.dart';
import 'package:path/path.dart' as p;

class BrowseFolderBloc extends Bloc<BrowseFolderEvent, BrowseFolderState> {
  BrowseFolderBloc({
    required BrowseRepository repository,
    required String directoryPath,
    required String folderName,
  }) : _repository = repository,
       super(
         BrowseFolderState(
           directoryPath: directoryPath,
           folderName: folderName,
         ),
       ) {
    on<BrowseFolderLoad>(_onLoad);
    on<BrowseFolderLoadMore>(_onLoadMore);
    on<BrowseFolderNavigate>(_onNavigate);
    on<BrowseFolderSetSelectionMode>(_onSetSelectionMode);
    on<BrowseFolderToggleSelection>(_onToggleSelection);
    on<BrowseFolderSelectAll>(_onSelectAll);
  }

  final BrowseRepository _repository;

  Future<void> _onLoad(
    BrowseFolderLoad event,
    Emitter<BrowseFolderState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await _repository.listDirectory(
        state.directoryPath,
        offset: 0,
        limit: Constants.pageSize,
      );

      emit(
        state.copyWith(
          entries: result.entries,
          isLoading: false,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      AppLogger.e('[BrowseFolderBloc] _onLoad failed: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to load directory'));
    }
  }

  Future<void> _onLoadMore(
    BrowseFolderLoadMore event,
    Emitter<BrowseFolderState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final result = await _repository.listDirectory(
        state.directoryPath,
        offset: state.entries.length,
        limit: Constants.pageSize,
      );

      emit(
        state.copyWith(
          entries: [...state.entries, ...result.entries],
          isLoadingMore: false,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      AppLogger.e('[BrowseFolderBloc] _onLoadMore failed: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onNavigate(
    BrowseFolderNavigate event,
    Emitter<BrowseFolderState> emit,
  ) async {
    final folderName = event.path == '/' ? '/' : p.basename(event.path);
    emit(
      state.copyWith(
        directoryPath: event.path,
        folderName: folderName,
        entries: const [],
        isLoading: true,
        isSelectionMode: false,
        selectedPaths: const {},
        clearError: true,
      ),
    );

    try {
      final result = await _repository.listDirectory(
        event.path,
        offset: 0,
        limit: Constants.pageSize,
      );

      emit(
        state.copyWith(
          entries: result.entries,
          isLoading: false,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      AppLogger.e('[BrowseFolderBloc] _onNavigate failed: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to load directory'));
    }
  }

  void _onSetSelectionMode(
    BrowseFolderSetSelectionMode event,
    Emitter<BrowseFolderState> emit,
  ) {
    if (event.path != null) {
      // Enter selection mode with the given path
      emit(state.copyWith(isSelectionMode: true, selectedPaths: {event.path!}));
    } else {
      // Exit selection mode
      emit(state.copyWith(isSelectionMode: false, selectedPaths: const {}));
    }
  }

  void _onToggleSelection(
    BrowseFolderToggleSelection event,
    Emitter<BrowseFolderState> emit,
  ) {
    final selectedPaths = Set<String>.from(state.selectedPaths);

    if (selectedPaths.contains(event.path)) {
      selectedPaths.remove(event.path);
    } else {
      selectedPaths.add(event.path);
    }

    emit(
      state.copyWith(
        isSelectionMode: selectedPaths.isNotEmpty,
        selectedPaths: selectedPaths,
      ),
    );
  }

  void _onSelectAll(
    BrowseFolderSelectAll event,
    Emitter<BrowseFolderState> emit,
  ) {
    final audioPaths = state.entries
        .where((entry) => !entry.isDirectory)
        .map((entry) => entry.path)
        .toSet();

    if (audioPaths.isEmpty) {
      return;
    }

    final allSelected = audioPaths.every(state.selectedPaths.contains);
    emit(
      state.copyWith(
        isSelectionMode: !allSelected,
        selectedPaths: allSelected ? const {} : audioPaths,
      ),
    );
  }
}
