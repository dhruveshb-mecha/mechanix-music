import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';

import 'folder_audio_tile.dart';
import 'folder_directory_tile.dart';
import 'folder_empty_state.dart';
import 'folder_error_state.dart';
import 'folder_load_more_indicator.dart';

class FolderContentsBody extends StatefulWidget {
  final BrowseFolderState state;

  const FolderContentsBody({super.key, required this.state});

  @override
  State<FolderContentsBody> createState() => _FolderContentsBodyState();
}

class _FolderContentsBodyState extends State<FolderContentsBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 200;

    if (!isNearBottom) return;

    final bloc = context.read<BrowseFolderBloc>();
    if (bloc.state.hasMore && !bloc.state.isLoadingMore) {
      bloc.add(const BrowseFolderLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(MusicColors.titleColor),
        ),
      );
    }

    if (state.error != null) {
      final bloc = context.read<BrowseFolderBloc>();
      return FolderErrorState(
        error: state.error!,
        onRetry: () => bloc.add(const BrowseFolderLoad()),
      );
    }

    if (state.entries.isEmpty) {
      return const FolderEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.entries.length + (state.hasMore ? 1 : 0),
      itemExtent: 72,
      itemBuilder: (context, index) {
        if (index == state.entries.length) {
          return const FolderLoadMoreIndicator();
        }

        final entry = state.entries[index];

        if (entry.isDirectory) {
          return FolderDirectoryTile(key: ValueKey(entry.path), entry: entry);
        } else {
          return FolderAudioTile(key: ValueKey(entry.path), entry: entry);
        }
      },
    );
  }
}
