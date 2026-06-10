import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

abstract class BrowseRepository {
  Future<List<BrowseFolderItem>> getMountedDrives();

  Future<({List<FileSystemEntry> entries, bool hasMore})> listDirectory(
    String directoryPath, {
    int offset = 0,
    int limit = Constants.pageSize,
  });
}
