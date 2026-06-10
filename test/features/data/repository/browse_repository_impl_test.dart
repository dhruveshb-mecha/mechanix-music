import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository_impl.dart';

void main() {
  late MemoryFileSystem fs;
  late BrowseRepositoryImpl repository;

  setUp(() {
    fs = MemoryFileSystem();
    repository = BrowseRepositoryImpl(fileSystem: fs);
  });

  Future<void> writeProcMounts(String content) async {
    await fs.directory('/proc').create(recursive: true);
    await fs.file('/proc/mounts').writeAsString(content);
  }

  Future<void> touch(String path) async {
    await fs.file(path).create(recursive: true);
  }

  group('getMountedDrives', () {
    test(
      'always includes Root, even when /proc/mounts is unavailable',
      () async {
        final drives = await repository.getMountedDrives();

        expect(drives, hasLength(1));
        expect(drives.single.title, 'Root (/)');
        expect(drives.single.path, '/');
      },
    );

    test('includes /dev block devices mounted under /media or /mnt', () async {
      await writeProcMounts(
        '/dev/sda1 /media/usb-drive vfat rw 0 0\n'
        '/dev/sdb1 /mnt/backup ext4 rw 0 0\n',
      );

      final drives = await repository.getMountedDrives();

      expect(drives.map((d) => d.path), [
        '/',
        '/media/usb-drive',
        '/mnt/backup',
      ]);
      // Label is the last path segment.
      expect(drives[1].title, 'usb-drive');
      expect(drives[2].title, 'backup');
    });

    test('skips non /dev devices and mounts outside /media and /mnt', () async {
      await writeProcMounts(
        'proc /proc proc rw 0 0\n' // not /dev
        'sysfs /sys sysfs rw 0 0\n' // not /dev
        '/dev/sda1 / ext4 rw 0 0\n' // /dev but mounted at /
        '/dev/sdc1 /home/user ext4 rw 0 0\n' // /dev but not /media or /mnt
        '/dev/sdd1 /media/ok vfat rw 0 0\n', // valid
      );

      final drives = await repository.getMountedDrives();

      expect(drives.map((d) => d.path), ['/', '/media/ok']);
    });

    test('ignores empty lines and malformed entries', () async {
      await writeProcMounts(
        '\n'
        '/dev/sda1\n' // only one field
        '\n'
        '/dev/sdb1 /media/valid vfat rw 0 0\n',
      );

      final drives = await repository.getMountedDrives();

      expect(drives.map((d) => d.path), ['/', '/media/valid']);
    });
  });

  group('listDirectory', () {
    test('returns empty when the directory does not exist', () async {
      final result = await repository.listDirectory('/missing');

      expect(result.entries, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('includes subdirectories and audio files only', () async {
      await fs.directory('/music/album').create(recursive: true);
      await touch('/music/song.mp3');
      await touch('/music/track.flac');
      await touch('/music/notes.txt'); // non-audio -> excluded
      await touch('/music/cover.jpg'); // non-audio -> excluded

      final result = await repository.listDirectory('/music');

      final byName = {for (final e in result.entries) e.name: e};
      expect(byName.keys, {'album', 'song.mp3', 'track.flac'});
      expect(byName['album']!.isDirectory, isTrue);
      expect(byName['song.mp3']!.isDirectory, isFalse);
      expect(result.hasMore, isFalse);
    });

    test('excludes hidden entries (files and directories)', () async {
      await fs.directory('/music/.hiddenDir').create(recursive: true);
      await fs.directory('/music/visible').create(recursive: true);
      await touch('/music/.secret.mp3');
      await touch('/music/song.mp3');

      final result = await repository.listDirectory('/music');

      expect(result.entries.map((e) => e.name).toSet(), {
        'visible',
        'song.mp3',
      });
    });

    test('populates entry fields from the file system', () async {
      await touch('/music/song.mp3');

      final result = await repository.listDirectory('/music');
      final entry = result.entries.single;

      expect(entry.name, 'song.mp3');
      expect(entry.path, '/music/song.mp3');
      expect(entry.isDirectory, isFalse);
      expect(
        entry.modifiedDate,
        (await fs.file('/music/song.mp3').stat()).modified,
      );
    });

    test('paginates with offset/limit and reports hasMore', () async {
      for (var i = 0; i < 5; i++) {
        await touch('/music/song_$i.mp3');
      }

      final page0 = await repository.listDirectory(
        '/music',
        offset: 0,
        limit: 2,
      );
      final page1 = await repository.listDirectory(
        '/music',
        offset: 2,
        limit: 2,
      );
      final page2 = await repository.listDirectory(
        '/music',
        offset: 4,
        limit: 2,
      );

      expect(page0.entries, hasLength(2));
      expect(page0.hasMore, isTrue);
      expect(page1.entries, hasLength(2));
      expect(page1.hasMore, isTrue);
      expect(page2.entries, hasLength(1));
      expect(page2.hasMore, isFalse);

      // Order is filesystem-defined; assert the pages together cover everything
      // exactly once.
      final allNames = [
        ...page0.entries,
        ...page1.entries,
        ...page2.entries,
      ].map((e) => e.name).toSet();
      expect(allNames, {
        'song_0.mp3',
        'song_1.mp3',
        'song_2.mp3',
        'song_3.mp3',
        'song_4.mp3',
      });
    });

    test(
      'hasMore is false when the page exactly drains the directory',
      () async {
        await touch('/music/a.mp3');
        await touch('/music/b.mp3');

        final result = await repository.listDirectory(
          '/music',
          offset: 0,
          limit: 2,
        );

        expect(result.entries, hasLength(2));
        expect(result.hasMore, isFalse);
      },
    );

    test('returns empty when offset is beyond the available entries', () async {
      await touch('/music/a.mp3');

      final result = await repository.listDirectory(
        '/music',
        offset: 5,
        limit: 30,
      );

      expect(result.entries, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test(
      'returns empty when the directory has no audio files or folders',
      () async {
        await fs.directory('/music').create(recursive: true);
        await touch('/music/readme.txt');

        final result = await repository.listDirectory('/music');

        expect(result.entries, isEmpty);
        expect(result.hasMore, isFalse);
      },
    );
  });
}
