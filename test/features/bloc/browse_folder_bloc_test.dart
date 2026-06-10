import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockBrowseRepository extends Mock implements BrowseRepository {}

FileSystemEntry entry(String name, {bool isDirectory = false, String? path}) =>
    FileSystemEntry(
      name: name,
      path: path ?? '/music/$name',
      isDirectory: isDirectory,
      modifiedDate: DateTime(2020),
    );

// Shared instances — BrowseFolderState compares entries by identity.
final fileA = entry('a.mp3');
final fileB = entry('b.mp3');
final fileC = entry('c.mp3');
final subDir = entry('sub', isDirectory: true, path: '/music/sub');

const dirPath = '/music';
const dirName = 'music';

void main() {
  late MockBrowseRepository repository;

  setUp(() {
    repository = MockBrowseRepository();
  });

  BrowseFolderBloc buildBloc() => BrowseFolderBloc(
    repository: repository,
    directoryPath: dirPath,
    folderName: dirName,
  );

  const base = BrowseFolderState(directoryPath: dirPath, folderName: dirName);

  void stubList(
    String path, {
    required int offset,
    required List<FileSystemEntry> entries,
    required bool hasMore,
  }) {
    when(
      () => repository.listDirectory(
        path,
        offset: offset,
        limit: Constants.pageSize,
      ),
    ).thenAnswer((_) async => (entries: entries, hasMore: hasMore));
  }

  test('initial state reflects the constructor arguments', () {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(bloc.state, base);
  });

  group('BrowseFolderLoad', () {
    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'emits [loading, loaded] on success',
      setUp: () =>
          stubList(dirPath, offset: 0, entries: [fileA, fileB], hasMore: true),
      build: buildBloc,
      act: (bloc) => bloc.add(const BrowseFolderLoad()),
      expect: () => [
        base.copyWith(isLoading: true, clearError: true),
        base.copyWith(entries: [fileA, fileB], isLoading: false, hasMore: true),
      ],
      verify: (_) => verify(
        () => repository.listDirectory(
          dirPath,
          offset: 0,
          limit: Constants.pageSize,
        ),
      ).called(1),
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'emits [loading, error] when the repository throws',
      setUp: () => when(
        () => repository.listDirectory(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('disk error')),
      build: buildBloc,
      act: (bloc) => bloc.add(const BrowseFolderLoad()),
      expect: () => [
        base.copyWith(isLoading: true, clearError: true),
        base.copyWith(isLoading: false, error: 'Failed to load directory'),
      ],
    );
  });

  group('BrowseFolderLoadMore', () {
    final loaded = base.copyWith(entries: [fileA, fileB], hasMore: true);

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'appends the next page on success',
      setUp: () =>
          stubList(dirPath, offset: 2, entries: [fileC], hasMore: false),
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc.add(const BrowseFolderLoadMore()),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          entries: [fileA, fileB, fileC],
          isLoadingMore: false,
          hasMore: false,
        ),
      ],
      verify: (_) => verify(
        () => repository.listDirectory(
          dirPath,
          offset: 2,
          limit: Constants.pageSize,
        ),
      ).called(1),
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'recovers (clears isLoadingMore, keeps entries) when the fetch throws',
      setUp: () => when(
        () => repository.listDirectory(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('disk error')),
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc.add(const BrowseFolderLoadMore()),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(isLoadingMore: false),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'does nothing when a load-more is already in progress',
      build: buildBloc,
      seed: () => loaded.copyWith(isLoadingMore: true),
      act: (bloc) => bloc.add(const BrowseFolderLoadMore()),
      expect: () => const <BrowseFolderState>[],
      verify: (_) => verifyNever(
        () => repository.listDirectory(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ),
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'does nothing when there are no more entries',
      build: buildBloc,
      seed: () => base.copyWith(entries: [fileA], hasMore: false),
      act: (bloc) => bloc.add(const BrowseFolderLoadMore()),
      expect: () => const <BrowseFolderState>[],
      verify: (_) => verifyNever(
        () => repository.listDirectory(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ),
    );
  });

  group('BrowseFolderNavigate', () {
    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'resets state, clears selection, and loads the new directory',
      setUp: () =>
          stubList('/music/sub', offset: 0, entries: [fileC], hasMore: false),
      build: buildBloc,
      seed: () => base.copyWith(
        entries: [fileA, fileB],
        isSelectionMode: true,
        selectedPaths: {fileA.path},
      ),
      act: (bloc) => bloc.add(const BrowseFolderNavigate('/music/sub')),
      expect: () => [
        const BrowseFolderState(
          directoryPath: '/music/sub',
          folderName: 'sub',
          isLoading: true,
        ),
        BrowseFolderState(
          directoryPath: '/music/sub',
          folderName: 'sub',
          entries: [fileC],
        ),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'uses "/" as the folder name when navigating to root',
      setUp: () => stubList('/', offset: 0, entries: [fileA], hasMore: false),
      build: buildBloc,
      act: (bloc) => bloc.add(const BrowseFolderNavigate('/')),
      expect: () => [
        const BrowseFolderState(
          directoryPath: '/',
          folderName: '/',
          isLoading: true,
        ),
        const BrowseFolderState(
          directoryPath: '/',
          folderName: '/',
        ).copyWith(entries: [fileA]),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'emits an error state when loading the new directory throws',
      setUp: () => when(
        () => repository.listDirectory(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('disk error')),
      build: buildBloc,
      act: (bloc) => bloc.add(const BrowseFolderNavigate('/music/sub')),
      expect: () => [
        const BrowseFolderState(
          directoryPath: '/music/sub',
          folderName: 'sub',
          isLoading: true,
        ),
        const BrowseFolderState(
          directoryPath: '/music/sub',
          folderName: 'sub',
          error: 'Failed to load directory',
        ),
      ],
    );
  });

  group('BrowseFolderSetSelectionMode', () {
    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'enters selection mode with the provided path',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const BrowseFolderSetSelectionMode(path: '/music/a.mp3')),
      expect: () => [
        base.copyWith(isSelectionMode: true, selectedPaths: {'/music/a.mp3'}),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'exits selection mode when no path is provided',
      build: buildBloc,
      seed: () =>
          base.copyWith(isSelectionMode: true, selectedPaths: {'/music/a.mp3'}),
      act: (bloc) => bloc.add(const BrowseFolderSetSelectionMode()),
      expect: () => [
        base.copyWith(isSelectionMode: false, selectedPaths: const {}),
      ],
    );
  });

  group('BrowseFolderToggleSelection', () {
    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'adds a path and turns on selection mode',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const BrowseFolderToggleSelection('/music/a.mp3')),
      expect: () => [
        base.copyWith(isSelectionMode: true, selectedPaths: {'/music/a.mp3'}),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'removes the last path and turns off selection mode',
      build: buildBloc,
      seed: () =>
          base.copyWith(isSelectionMode: true, selectedPaths: {'/music/a.mp3'}),
      act: (bloc) =>
          bloc.add(const BrowseFolderToggleSelection('/music/a.mp3')),
      expect: () => [
        base.copyWith(isSelectionMode: false, selectedPaths: const {}),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'removes one path while others remain selected',
      build: buildBloc,
      seed: () => base.copyWith(
        isSelectionMode: true,
        selectedPaths: {'/music/a.mp3', '/music/b.mp3'},
      ),
      act: (bloc) =>
          bloc.add(const BrowseFolderToggleSelection('/music/a.mp3')),
      expect: () => [
        base.copyWith(isSelectionMode: true, selectedPaths: {'/music/b.mp3'}),
      ],
    );
  });

  group('BrowseFolderSelectAll', () {
    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'selects every audio file (ignoring directories)',
      build: buildBloc,
      seed: () => base.copyWith(entries: [subDir, fileA, fileB]),
      act: (bloc) => bloc.add(const BrowseFolderSelectAll()),
      expect: () => [
        base.copyWith(
          entries: [subDir, fileA, fileB],
          isSelectionMode: true,
          selectedPaths: {fileA.path, fileB.path},
        ),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'deselects everything when all audio files are already selected',
      build: buildBloc,
      seed: () => base.copyWith(
        entries: [fileA, fileB],
        isSelectionMode: true,
        selectedPaths: {fileA.path, fileB.path},
      ),
      act: (bloc) => bloc.add(const BrowseFolderSelectAll()),
      expect: () => [
        base.copyWith(
          entries: [fileA, fileB],
          isSelectionMode: false,
          selectedPaths: const {},
        ),
      ],
    );

    blocTest<BrowseFolderBloc, BrowseFolderState>(
      'does nothing when there are no audio files',
      build: buildBloc,
      seed: () => base.copyWith(entries: [subDir]),
      act: (bloc) => bloc.add(const BrowseFolderSelectAll()),
      expect: () => const <BrowseFolderState>[],
    );
  });
}
