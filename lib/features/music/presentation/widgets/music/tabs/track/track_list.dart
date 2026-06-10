import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_tile.dart';

class TrackList extends StatefulWidget {
  final List<SongModel> songs;

  const TrackList({super.key, required this.songs});

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
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

    final state = context.read<SongBloc>().state;
    if (state is SongLoaded && state.hasMore && !state.isLoadingMore) {
      context.read<SongBloc>().add(const SongLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.builder(
        controller: _scrollController,
        prototypeItem: const SizedBox(height: 93),
        itemCount: widget.songs.length,
        itemBuilder: (context, index) {
          if (index == widget.songs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return TrackTile(song: widget.songs[index]);
        },
      ),
    );
  }
}
