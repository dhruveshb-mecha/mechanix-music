import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/presentation/screens/music_screen.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/music_bottom_bar.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_empty_screen.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_list.dart';
import 'package:mechanix_music/main.dart' as app;

/// Shared helpers for the Mechanix Music integration tests.
///
/// The app boots the *real* ObjectBox store, the music-library scan and the
/// real audio backend, so these tests must run on a device/emulator (or a
/// generated desktop/web target):
///
///   flutter test integration_test/<file>_test.dart -d <device>
///
/// They cannot run on the headless `flutter test` runner because they rely on
/// the app's native plugins (ObjectBox, audioplayers, path_provider).
class TestHelper {
  /// Bottom-navigation tab indices.
  static const int nowPlayingTab = 0;
  static const int searchTab = 1;
  static const int tracksTab = 2;
  static const int browseTab = 3;

  /// The asset for each bottom-navigation tab, in index order.
  static const List<String> tabIcons = [
    MusicIcons.playcircleIcon,
    MusicIcons.searchIcon,
    MusicIcons.tracksIcon,
    MusicIcons.fileIcon,
  ];

  /// Boots the real app and waits until the [MusicScreen] is on screen.
  static Future<void> launchApp(WidgetTester tester) async {
    app.main();
    await pumpUntil(
      tester,
      () => find.byType(MusicScreen).evaluate().isNotEmpty,
      reason: 'MusicScreen to appear',
    );
  }

  /// Pumps frames until [condition] is satisfied or [timeout] elapses.
  ///
  /// Avoids `pumpAndSettle`, which never returns while the library is loading
  /// (the Tracks tab shows an indefinite [CircularProgressIndicator] and the
  /// player/mini-player run continuous rotation animations).
  static Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 60),
    Duration step = const Duration(milliseconds: 100),
    String? reason,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return;
      await tester.pump(step);
    }
    if (!condition()) {
      throw TestFailure('Timed out waiting for: ${reason ?? 'condition'}');
    }
  }

  /// Finds an [Image] built from an [AssetImage] whose path is [assetPath].
  static Finder findImageAsset(String assetPath) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetPath,
      description: 'Image.asset($assetPath)',
    );
  }

  /// Finds a [MusicButton] by its declared icon path.
  static Finder findMusicButton(String iconPath) {
    return find.byWidgetPredicate(
      (widget) => widget is MusicButton && widget.iconPath == iconPath,
      description: 'MusicButton($iconPath)',
    );
  }

  /// Taps a bottom-navigation tab by its index.
  ///
  /// Resolves the tab via its unique icon asset (rather than positional
  /// `MusicButton.at(index)`) so it stays reliable even when the mini player
  /// adds an extra [MusicButton] above the tab row.
  static Future<void> tapTab(WidgetTester tester, int index) async {
    final tab = findMusicButton(tabIcons[index]);
    expect(tab, findsOneWidget, reason: 'tab $index should exist');
    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Waits for the Tracks tab to resolve to either a populated list or the
  /// empty state, i.e. the indefinite spinner has been replaced.
  static Future<void> waitForTracks(WidgetTester tester) async {
    await pumpUntil(
      tester,
      () =>
          find.byType(TrackList).evaluate().isNotEmpty ||
          find.byType(TrackEmptyScreen).evaluate().isNotEmpty,
      reason: 'tracks to finish loading',
    );
  }

  /// Whether the Tracks tab currently shows a populated list of songs.
  static bool tracksAreLoaded() => find.byType(TrackList).evaluate().isNotEmpty;

  /// Whether the bottom navigation is currently visible.
  static bool hasBottomBar() =>
      find.byType(MusicBottomBar).evaluate().isNotEmpty;
}
