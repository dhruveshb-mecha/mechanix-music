import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository.dart';
import 'package:path/path.dart' as p;

class BrowseRepositoryImpl implements BrowseRepository {
  BrowseRepositoryImpl({FileSystem? fileSystem})
    : _fs = fileSystem ?? const LocalFileSystem();
  List<FileSystemEntry>? _cachedEntries; // Store current directory
  String? _cachedDirectoryPath; // path of current directory
  final FileSystem _fs;

  @override
  Future<List<BrowseFolderItem>> getMountedDrives() async {
    final drives = <BrowseFolderItem>[];

    // Always include root
    drives.add(
      const BrowseFolderItem(icon: Icons.storage, title: 'Root (/)', path: '/'),
    );

    // Parse /proc/mounts to find real block-device partitions.
    try {
      final mounts = await _fs.file('/proc/mounts').readAsString();
      for (final line in mounts.split('\n')) {
        if (line.isEmpty) continue;
        final parts = line.split(' ');
        if (parts.length < 2) continue;

        final device = parts[0];
        final mountPoint = parts[1];

        // Only include real block devices mounted under /media or /mnt
        if (!device.startsWith('/dev/')) continue;
        if (!mountPoint.startsWith('/media') &&
            !mountPoint.startsWith('/mnt')) {
          continue;
        }

        // Derive a human-readable label from the mount path
        final label = mountPoint.split('/').last;
        drives.add(
          BrowseFolderItem(icon: Icons.usb, title: label, path: mountPoint),
        );
      }
    } catch (e) {
      // If /proc/mounts is unavailable, return just root
      AppLogger.e('Failed to read /proc/mounts ', error: e);
    }

    return drives;
  }

  Future<List<FileSystemEntry>> _loadDirectoryEntries(
    String directoryPath,
  ) async {
    if (_cachedDirectoryPath == directoryPath && _cachedEntries != null) {
      return _cachedEntries!;
    }

    final dir = _fs.directory(directoryPath);

    if (!await dir.exists()) {
      return [];
    }

    final entries = <FileSystemEntry>[];

    try {
      await for (final entity in dir.list(
        recursive: false,
        followLinks: false,
      )) {
        final name = p.basename(entity.path);

        if (name.startsWith('.')) {
          continue; // skip hidden files
        }

        final isDirectory = entity is Directory;

        if (!isDirectory) {
          final extension = p.extension(entity.path).toLowerCase();

          if (!Constants.audioExt.contains(extension)) {
            continue;
          }
        }

        try {
          final stat = await entity.stat();

          entries.add(
            FileSystemEntry(
              name: name,
              path: entity.path,
              isDirectory: isDirectory,
              modifiedDate: stat.modified,
            ),
          );
        } catch (_) {
          AppLogger.e("Failed to get stats for $entity");
        }
      }
      // directories first
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _cachedDirectoryPath = directoryPath;
      _cachedEntries = entries;

      return entries;
    } catch (_) {
      AppLogger.e("Failed to list directory $directoryPath");
      return [];
    }
  }

  @override
  Future<({List<FileSystemEntry> entries, bool hasMore})> listDirectory(
    String directoryPath, {
    int offset = 0,
    int limit = Constants.pageSize,
  }) async {
    try {
      final allEntries = await _loadDirectoryEntries(directoryPath);

      if (offset >= allEntries.length) {
        return (entries: const <FileSystemEntry>[], hasMore: false);
      }

      final end = (offset + limit).clamp(0, allEntries.length);

      return (
        entries: allEntries.sublist(offset, end),
        hasMore: end < allEntries.length,
      );
    } catch (e) {
      AppLogger.e('[BrowseRepositoryImpl] listDirectory failed: $e');
      return (entries: const <FileSystemEntry>[], hasMore: false);
    }
  }
}
