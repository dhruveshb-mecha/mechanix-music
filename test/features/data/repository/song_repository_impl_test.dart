import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_music/core/services/file_scanner_service.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/features/music/data/models/song_change.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository_impl.dart';
import 'package:mechanix_music/objectbox.g.dart';
import 'package:mocktail/mocktail.dart';

class MockFileScannerService extends Mock implements FileScannerService {}

void main() {
  late Store store;
  late Box<SongModel> box;
  late MockFileScannerService scanner;
  late Directory tempDbDir;
  late Directory tempMusicDir;
  late SongRepositoryImpl repository;

  setUpAll(() {
    // Allow mocktail to use SongModel in `any()`/argument matchers if needed.
    registerFallbackValue(
      SongModel(id: 'fallback', path: '/fallback', title: 't', artist: 'a'),
    );
  });

  late Directory tempArtworkDir;

  setUp(() async {
    tempDbDir = await Directory.systemTemp.createTemp('repo_test_db_');
    store = Store(getObjectBoxModel(), directory: tempDbDir.path);
    box = store.box<SongModel>();
    scanner = MockFileScannerService();
    tempMusicDir = await Directory.systemTemp.createTemp('repo_test_music_');
    tempArtworkDir = await Directory.systemTemp.createTemp(
      'repo_test_artwork_',
    );

    repository = SongRepositoryImpl(
      fileScannerService: scanner,
      store: store,
      musicDirectoryProvider: () => tempMusicDir.path,
      artworkCacheDirectoryProvider: () => tempArtworkDir.path,
    );
  });

  tearDown(() async {
    repository.closeStore();
    if (!store.isClosed()) store.close();
    if (await tempDbDir.exists()) {
      await tempDbDir.delete(recursive: true);
    }
    if (await tempMusicDir.exists()) {
      await tempMusicDir.delete(recursive: true);
    }
    if (await tempArtworkDir.exists()) {
      await tempArtworkDir.delete(recursive: true);
    }
  });

  SongModel makeSong(
    String id,
    String path,
    String title, {
    bool isExternal = false,
  }) => SongModel(
    id: id,
    path: path,
    title: title,
    artist: 'artist-$id',
    isExternal: isExternal,
  );

  group('getSongs', () {
    test('returns songs ordered by title', () async {
      box.putMany([
        makeSong('1', '/a.mp3', 'Charlie'),
        makeSong('2', '/b.mp3', 'Alpha'),
        makeSong('3', '/c.mp3', 'Bravo'),
      ]);

      final result = await repository.getSongs(offset: 0, limit: 10);

      expect(result.map((s) => s.title), ['Alpha', 'Bravo', 'Charlie']);
    });

    test('respects offset and limit', () async {
      box.putMany([
        makeSong('1', '/a.mp3', 'Alpha'),
        makeSong('2', '/b.mp3', 'Bravo'),
        makeSong('3', '/c.mp3', 'Charlie'),
        makeSong('4', '/d.mp3', 'Delta'),
      ]);

      final result = await repository.getSongs(offset: 1, limit: 2);

      expect(result.map((s) => s.title), ['Bravo', 'Charlie']);
    });

    test('returns empty list when no songs', () async {
      final result = await repository.getSongs(offset: 0, limit: 10);
      expect(result, isEmpty);
    });
  });

  group('getSongCount', () {
    test('returns the number of stored songs', () async {
      expect(await repository.getSongCount(), 0);

      box.putMany([
        makeSong('1', '/a.mp3', 'Alpha'),
        makeSong('2', '/b.mp3', 'Bravo'),
      ]);

      expect(await repository.getSongCount(), 2);
    });
  });

  group('addSongsByPaths', () {
    test('does nothing for an empty list', () async {
      await repository.addSongsByPaths([]);

      expect(await repository.getSongCount(), 0);
      verifyNever(() => scanner.buildSongModel(any()));
    });

    test('imports new songs and skips already-stored paths', () async {
      box.put(makeSong('existing', '/existing.mp3', 'Existing'));

      when(
        () => scanner.buildSongModel('/new.mp3'),
      ).thenAnswer((_) async => makeSong('new', '/new.mp3', 'New Song'));

      await repository.addSongsByPaths(['/existing.mp3', '/new.mp3']);

      // Scanner should only be asked to build the new path.
      verify(() => scanner.buildSongModel('/new.mp3')).called(1);
      verifyNever(() => scanner.buildSongModel('/existing.mp3'));

      final stored = box.getAll().map((s) => s.path).toSet();
      expect(stored, {'/existing.mp3', '/new.mp3'});
    });

    test('emits an upsert change when a song is added', () async {
      when(
        () => scanner.buildSongModel('/new.mp3'),
      ).thenAnswer((_) async => makeSong('new', '/new.mp3', 'New Song'));

      final changes = expectLater(
        repository.onSongChanged,
        emits(
          isA<SongChange>()
              .having((c) => c.type, 'type', SongChangeType.upsert)
              .having((c) => c.song.path, 'path', '/new.mp3'),
        ),
      );

      await repository.addSongsByPaths(['/new.mp3']);
      await changes;
    });

    test('skips paths the scanner cannot build a model for', () async {
      when(
        () => scanner.buildSongModel('/broken.mp3'),
      ).thenAnswer((_) async => null);

      await repository.addSongsByPaths(['/broken.mp3']);

      expect(await repository.getSongCount(), 0);
      verify(() => scanner.buildSongModel('/broken.mp3')).called(1);
    });

    test(
      'correctly marks songs as internal or external based on their path',
      () async {
        final internalPath = '${tempMusicDir.path}/internal.mp3';
        final externalPath = '/some/other/dir/external.mp3';

        when(() => scanner.buildSongModel(internalPath)).thenAnswer(
          (_) async => makeSong('internal', internalPath, 'Internal'),
        );
        when(() => scanner.buildSongModel(externalPath)).thenAnswer(
          (_) async => makeSong('external', externalPath, 'External'),
        );

        await repository.addSongsByPaths([internalPath, externalPath]);

        final storedInternal = box.getAll().firstWhere(
          (s) => s.path == internalPath,
        );
        final storedExternal = box.getAll().firstWhere(
          (s) => s.path == externalPath,
        );

        expect(storedInternal.isExternal, isFalse);
        expect(storedExternal.isExternal, isTrue);
      },
    );
  });

  group('deleteSongByPath', () {
    test(
      'removes the song from the database and emits a delete change event',
      () async {
        final songPath = '/to_delete.mp3';
        box.put(makeSong('to_delete', songPath, 'To Delete'));

        expect(await repository.getSongCount(), 1);

        final changes = expectLater(
          repository.onSongChanged,
          emits(
            isA<SongChange>()
                .having((c) => c.type, 'type', SongChangeType.delete)
                .having((c) => c.song.path, 'path', songPath),
          ),
        );

        await repository.deleteSongByPath(songPath);
        await changes;

        expect(await repository.getSongCount(), 0);
      },
    );

    test('does nothing if the song does not exist', () async {
      await repository.deleteSongByPath('/non_existent.mp3');
      expect(await repository.getSongCount(), 0);
    });
  });

  group('syncInitialSongLibrary', () {
    test(
      'syncs new files, removes deleted ones, and returns true when changes detected',
      () async {
        final fileStalePath = '${tempMusicDir.path}/stale.mp3';
        box.put(makeSong('stale', fileStalePath, 'Stale'));

        final fileAPath = '${tempMusicDir.path}/a.mp3';
        final fileBPath = '${tempMusicDir.path}/b.mp3';
        await File(fileAPath).create();
        await File(fileBPath).create();

        when(
          () => scanner.buildSongModel(fileAPath),
        ).thenAnswer((_) async => makeSong('a', fileAPath, 'A'));
        when(
          () => scanner.buildSongModel(fileBPath),
        ).thenAnswer((_) async => makeSong('b', fileBPath, 'B'));

        final result = await repository.syncInitialSongLibrary();

        expect(result, isTrue);
        final paths = box.getAll().map((s) => s.path).toSet();
        expect(paths, {fileAPath, fileBPath});
      },
    );

    test('returns false when no changes are detected', () async {
      final fileAPath = '${tempMusicDir.path}/a.mp3';
      await File(fileAPath).create();

      final songA = makeSong('a', fileAPath, 'A');
      box.put(songA);

      final result = await repository.syncInitialSongLibrary();

      expect(result, isFalse);
      expect(box.getAll().single.path, fileAPath);
    });

    test(
      'clears database and returns true when music directory does not exist',
      () async {
        box.put(makeSong('stale', '/old.mp3', 'Stale'));
        await tempMusicDir.delete(recursive: true);

        final result = await repository.syncInitialSongLibrary();

        expect(result, isTrue);
        expect(box.getAll(), isEmpty);
      },
    );

    test(
      'preserves custom external songs during folder sync if they still exist on disk',
      () async {
        // 1. Create a dummy external file
        final tempExternalDir = await Directory.systemTemp.createTemp(
          'repo_test_external_',
        );
        final externalFilePath = '${tempExternalDir.path}/custom.mp3';
        final externalFile = File(externalFilePath);
        await externalFile.create();

        // 2. Put it in the DB
        final customSong = makeSong(
          'custom',
          externalFilePath,
          'Custom File',
          isExternal: true,
        );
        box.put(customSong);

        // 3. Put an internal song in DB (which will be deleted since it is not on disk)
        final internalFilePath = '${tempMusicDir.path}/stale.mp3';
        box.put(makeSong('stale', internalFilePath, 'Stale'));

        // 4. Run sync
        final result = await repository.syncInitialSongLibrary();

        // Should return true (since changes were made: 'stale' was deleted)
        expect(result, isTrue);

        // Verify custom file is still in the DB, but stale song is deleted
        final storedPaths = box.getAll().map((s) => s.path).toSet();
        expect(storedPaths, {externalFilePath});

        // Cleanup
        await tempExternalDir.delete(recursive: true);
      },
    );

    test(
      'deletes custom external songs during folder sync if they no longer exist on disk',
      () async {
        // 1. Put a missing external file path in DB (without creating it on disk)
        final externalFilePath = '/nonexistent/external_song.mp3';
        final customSong = makeSong(
          'custom',
          externalFilePath,
          'Custom File',
          isExternal: true,
        );
        box.put(customSong);

        // 2. Run sync
        final result = await repository.syncInitialSongLibrary();

        // Should return true (since changes were made: missing custom file deleted)
        expect(result, isTrue);

        // Verify DB is empty
        expect(box.getAll(), isEmpty);
      },
    );
  });
}
