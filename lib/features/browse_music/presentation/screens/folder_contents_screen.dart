import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_content_bottom_bar.dart';
import 'package:path/path.dart' as p;
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository_impl.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_content_body.dart';

import '../widgets/folder_contents_screen/breadcrumbs_header.dart';
import '../widgets/folder_contents_screen/selection_bottom_bar.dart';
import '../widgets/folder_contents_screen/selection_header.dart';

class FolderContentsScreen extends StatefulWidget {
  final String initialPath;
  final String folderName;

  const FolderContentsScreen({
    super.key,
    required this.initialPath,
    required this.folderName,
  });

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  late final BrowseFolderBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BrowseFolderBloc(
      repository: BrowseRepositoryImpl(),
      directoryPath: widget.initialPath,
      folderName: widget.folderName,
    )..add(const BrowseFolderLoad());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrowseFolderBloc>.value(
      value: _bloc,
      child: BlocBuilder<BrowseFolderBloc, BrowseFolderState>(
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  state.isSelectionMode
                      ? SelectionHeader(
                          selectedCount: state.selectedPaths.length,
                        )
                      : BreadcrumbsHeader(
                          currentPath: state.directoryPath,
                          initialPath: widget.initialPath,
                          rootTitle: widget.folderName,
                          onNavigate: (newPath) {
                            _bloc.add(BrowseFolderNavigate(newPath));
                          },
                          onPop: () => Navigator.pop(context),
                        ),
                  Expanded(child: FolderContentsBody(state: state)),
                ],
              ),
            ),
            bottomNavigationBar: state.isSelectionMode
                ? const SelectionBottomBar()
                : FolderContentBottomBar(
                    onTap: () {
                      if (state.directoryPath == widget.initialPath) {
                        Navigator.pop(context);
                      } else {
                        final parentPath = p.dirname(state.directoryPath);
                        _bloc.add(BrowseFolderNavigate(parentPath));
                      }
                    },
                  ),
          );
        },
      ),
    );
  }
}
