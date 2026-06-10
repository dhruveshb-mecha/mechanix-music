import 'dart:async';
import 'dart:io';
import 'package:mechanix_music/core/exceptions/app_exceptions.dart';
import 'package:mechanix_music/core/services/file_scanner_service.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/music/data/models/song_change.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';
import 'package:mechanix_music/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:isolate';

class SongRepositoryImpl extends SongRepository {
  SongRepositoryImpl({
    FileScannerService? fileScannerService,
    Store? store,
    String Function()? musicDirectoryProvider,
    FutureOr<String> Function()? artworkCacheDirectoryProvider,
  }) : _fileScannerService = fileScannerService ?? FileScannerService(),
       _musicDirectoryProvider = musicDirectoryProvider ?? getMusicDirectory,
       _artworkCacheDirectoryProvider = artworkCacheDirectoryProvider,
       _store = store {
    if (store != null) {
      _box = store.box<SongModel>();
      try {
        _dbDirectoryPath = store.directoryPath;
      } catch (_) {
        // Fallback if directoryPath is not accessible/supported in this state
      }
    }
  }

  final FileScannerService _fileScannerService;
  final String Function() _musicDirectoryProvider;
  final FutureOr<String> Function()? _artworkCacheDirectoryProvider;

  Store? _store;
  Box<SongModel>? _box;
  String? _dbDirectoryPath;

  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  final Map<String, Timer> _debounceTimers = {};

  // Stream that bloc will listen to for live changes
  final StreamController<SongChange> _onSongChanged =
      StreamController<SongChange>.broadcast();

  @override
  Stream<SongChange> get onSongChanged => _onSongChanged.stream;

  Future<void> ensureStoreConnected() async {
    if (_store != null && _store!.isClosed() == false) return;

    try {
      await _initializeStore();
    } catch (e) {
      AppLogger.e('Failed to open ObjectBox store: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw AppAlreadyRunningException();
      }
      rethrow;
    }
  }

  Future<void> _initializeStore() async {
    try {
      final home = Platform.environment['HOME'];
      final appDir = Directory('$home/${Constants.dbPath}');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      _store = openStore(directory: appDir.path);
      _box = _store!.box<SongModel>();
      _dbDirectoryPath = appDir.path;

      AppLogger.i('[SongRepository] ObjectBox store opened at ${appDir.path}');
    } catch (e) {
      AppLogger.e('Failed to initialize ObjectBox store: $e');
      rethrow;
    }
  }

  void closeStore() {
    _watcherSubscription?.cancel();
    _watcherSubscription = null;

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    _onSongChanged.close();

    _store?.close();
    _store = null;
    _box = null;
  }

  @override
  Future<bool> syncInitialSongLibrary() async {
    try {
      await ensureStoreConnected();
      final musicDir = _musicDirectoryProvider();

      String artworkCacheDirPath;
      final provider = _artworkCacheDirectoryProvider;
      if (provider != null) {
        artworkCacheDirPath = await provider();
      } else {
        final appSupportDir = await getApplicationSupportDirectory();
        artworkCacheDirPath = Directory('${appSupportDir.path}/artworks').path;
      }

      final dbPath = _dbDirectoryPath ?? _store!.directoryPath;
      final args = _SyncIsolateArgs(
        dbDirectoryPath: dbPath,
        musicDir: musicDir,
        artworkCacheDirPath: artworkCacheDirPath,
      );

      final isTest = Platform.environment.containsKey(
        'FLUTTER_TEST',
      ); // for Unit test only.
      final changesDetected = isTest
          ? await _syncInitialSongLibraryIsolate(
              args,
              store: _store,
              box: _box,
              scanner: _fileScannerService,
            )
          : await Isolate.run<bool>(() => _syncInitialSongLibraryIsolate(args));

      AppLogger.i(
        '[SongRepository] Sync initial library completed (changesDetected: $changesDetected) for '
        '$musicDir',
      );

      _startWatcher();
      return changesDetected;
    } on AppAlreadyRunningException catch (_) {
      rethrow;
    } catch (e) {
      AppLogger.e('[SongRepository] syncInitialSongLibrary failed: $e');
      return false;
    }
  }

  @override
  Future<List<SongModel>> getSongs({
    required int offset,
    required int limit,
  }) async {
    await ensureStoreConnected();

    final query = _box!.query().order(SongModel_.title).build()
      ..offset = offset
      ..limit = limit;

    try {
      return query.find().toList();
    } finally {
      query.close();
    }
  }

  @override
  Future<int> getSongCount() async {
    await ensureStoreConnected();
    return _box!.count();
  }

  @override
  Future<void> addSongsByPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    await ensureStoreConnected();

    // Single bulk query — ObjectBox checks all paths in one index scan.
    final existingPaths = _box!
        .query(SongModel_.path.oneOf(paths))
        .build()
        .find()
        .map((s) => s.path)
        .toSet();

    final newPaths = paths.where((p) => !existingPaths.contains(p)).toList();

    AppLogger.i(
      '[SongRepository] ${existingPaths.length} already in library, '
      '${newPaths.length} to import',
    );

    final musicDir = _musicDirectoryProvider();
    for (final path in newPaths) {
      try {
        final song = await _fileScannerService.buildSongModel(path);
        if (song == null) {
          AppLogger.i('[SongRepository] Could not build model for: $path');
          continue;
        }

        song.isExternal = !p.isWithin(musicDir, path);

        _box!.put(song);
        AppLogger.i('[SongRepository] Added to library: ${song.title}');
        _onSongChanged.add(SongChange(type: SongChangeType.upsert, song: song));
      } catch (e) {
        AppLogger.e('[SongRepository] addSongsByPaths failed for $path: $e');
      }
    }
  }

  @override
  Future<void> deleteSongByPath(String path) async {
    await ensureStoreConnected();
    final existing = _box!
        .query(SongModel_.path.equals(path))
        .build()
        .findFirst();

    if (existing != null) {
      _box!.remove(existing.obxId);
      AppLogger.i('[SongRepository] Deleted song by path: $path');
      _onSongChanged.add(
        SongChange(type: SongChangeType.delete, song: existing),
      );
    }
  }

  // ── Watcher ──────────────────────────────────────────────────────────────

  void _startWatcher() {
    _watcherSubscription?.cancel();
    _watcherSubscription = null;

    final musicDir = _musicDirectoryProvider();
    final dir = Directory(musicDir);
    if (!dir.existsSync()) {
      AppLogger.e(
        '[FileWatcher] Music directory does not exist: $musicDir. Skipping watcher.',
      );
      return;
    }

    _watcherSubscription = dir.watch(recursive: false).listen((event) {
      if (!isAudioFile(event.path)) return;

      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
          _debounce(event.path, () => _onUpsert(event.path));

        case FileSystemEvent.delete:
          // Cancel any pending debounce for this path and act immediately
          _debounceTimers[event.path]?.cancel();
          _debounceTimers.remove(event.path);
          deleteSongByPath(event.path);

        case FileSystemEvent.move:
          final moveEvent = event as FileSystemMoveEvent;
          final destination = moveEvent.destination;
          if (destination == null) return;

          // Cancel pending debounce for old path and act immediately
          _debounceTimers[moveEvent.path]?.cancel();
          _debounceTimers.remove(moveEvent.path);
          _onMove(oldPath: moveEvent.path, newPath: destination);
      }
    });

    AppLogger.i('[FileWatcher] Watching $musicDir');
  }

  void _debounce(String path, void Function() action) {
    _debounceTimers[path]?.cancel();
    _debounceTimers[path] = Timer(const Duration(milliseconds: 300), () {
      _debounceTimers.remove(path);
      action();
    });
  }

  Future<void> _onUpsert(String path) async {
    try {
      final song = await _fileScannerService.buildSongModel(path);
      if (song == null) return;

      final existing = _box!
          .query(SongModel_.path.equals(path))
          .build()
          .findFirst();

      if (existing != null) {
        song.obxId = existing.obxId;
        song.isExternal = existing.isExternal;
      } else {
        song.isExternal = false;
      }

      _box!.put(song);
      AppLogger.i('[FileWatcher] Upserted: $path');
      _onSongChanged.add(SongChange(type: SongChangeType.upsert, song: song));
    } catch (e) {
      AppLogger.e('[FileWatcher] Upsert failed for $path: $e');
    }
  }

  Future<void> _onMove({
    required String oldPath,
    required String newPath,
  }) async {
    try {
      final existing = _box!
          .query(SongModel_.path.equals(oldPath))
          .build()
          .findFirst();

      if (existing == null) return;

      final updated = await _fileScannerService.buildSongModel(newPath);
      if (updated == null) return;

      updated.obxId = existing.obxId;
      updated.isExternal = existing.isExternal;
      _box!.put(updated);

      AppLogger.i('[FileWatcher] Moved: $oldPath → $newPath');
      _onSongChanged.add(
        SongChange(type: SongChangeType.upsert, song: updated),
      );
    } catch (e) {
      AppLogger.e('[FileWatcher] Move failed $oldPath → $newPath: $e');
    }
  }

  bool isAudioFile(String path) {
    final lower = path.toLowerCase();
    return Constants.audioExt.any((ext) => lower.endsWith(ext));
  }
}

class _SyncIsolateArgs {
  final String dbDirectoryPath;
  final String musicDir;
  final String artworkCacheDirPath;

  _SyncIsolateArgs({
    required this.dbDirectoryPath,
    required this.musicDir,
    required this.artworkCacheDirPath,
  });
}

Future<bool> _syncInitialSongLibraryIsolate(
  _SyncIsolateArgs args, {
  Store? store,
  Box<SongModel>? box,
  FileScannerService? scanner,
}) async {
  // 1. Attach to store if store is not provided
  final storeToUse =
      store ?? Store.attach(getObjectBoxModel(), args.dbDirectoryPath);
  final boxToUse = box ?? storeToUse.box<SongModel>();

  try {
    // 2. Fetch cached songs from DB using separate queries based on isExternal
    final internalStoredSongs = boxToUse
        .query(SongModel_.isExternal.equals(false))
        .build()
        .find();
    final externalStoredSongs = boxToUse
        .query(SongModel_.isExternal.equals(true))
        .build()
        .find();

    final storedSongsByPath = <String, SongModel>{};
    for (final s in internalStoredSongs) {
      storedSongsByPath[s.path] = s;
    }
    for (final s in externalStoredSongs) {
      storedSongsByPath[s.path] = s;
    }

    final internalStoredPaths = internalStoredSongs.map((s) => s.path).toSet();

    // 3. Scan directory and identify updates/new files in O(1)
    final dir = Directory(args.musicDir);
    final diskPaths = <String>{};
    final newOrModifiedFiles = <File>[];

    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (Constants.audioExt.contains(ext)) {
            final path = entity.path;
            diskPaths.add(path);

            final stored = storedSongsByPath[path];
            if (stored == null) {
              newOrModifiedFiles.add(entity);
            } else {
              // Check modification time
              final stat = await entity.stat();
              if (stat.modified.isAfter(stored.lastScannedAt)) {
                newOrModifiedFiles.add(entity);
              }
            }
          }
        }
      }
    }

    // 4. Compute changes for internal and external songs
    // Deleted internal songs: present in DB under musicDir, but not on disk
    final toRemovePaths = internalStoredPaths.difference(diskPaths);
    final toRemoveIds = toRemovePaths
        .map((path) => storedSongsByPath[path]?.obxId)
        .whereType<int>()
        .toList();

    // Deleted external/custom songs: check direct existence on disk
    for (final song in externalStoredSongs) {
      try {
        if (!await File(song.path).exists()) {
          toRemoveIds.add(song.obxId);
        }
      } catch (e) {
        AppLogger.e('Error checking existence of custom song ${song.path}: $e');
        toRemoveIds.add(song.obxId);
      }
    }

    final hasChanges = toRemoveIds.isNotEmpty || newOrModifiedFiles.isNotEmpty;
    if (!hasChanges) {
      return false;
    }

    // 5. Scan metadata for new/modified files in the isolate
    final scannerToUse =
        scanner ??
        FileScannerService(
          artworkCacheDir: Directory(args.artworkCacheDirPath),
        );

    final updatedSongs = <SongModel>[];
    for (final file in newOrModifiedFiles) {
      final song = await scannerToUse.buildSongModel(file.path);
      if (song == null) continue;

      final stored = storedSongsByPath[file.path];
      if (stored != null) {
        song.obxId = stored.obxId;
        song.id = stored.id;
        song.isExternal = stored.isExternal;
      } else {
        song.isExternal = false;
      }
      song.lastScannedAt = DateTime.now().toUtc();
      updatedSongs.add(song);
    }

    // 6. Update DB inside a transaction
    storeToUse.runInTransaction(TxMode.write, () {
      if (toRemoveIds.isNotEmpty) {
        boxToUse.removeMany(toRemoveIds);
      }
      if (updatedSongs.isNotEmpty) {
        boxToUse.putMany(updatedSongs);
      }
    });

    return true;
  } finally {
    if (store == null) {
      storeToUse.close();
    }
  }
}
