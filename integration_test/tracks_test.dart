import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_music/features/music/presentation/screens/player_screen.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/music_mini_player.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_empty_screen.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_list.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_tile.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tracks tab', () {
    testWidgets('full tracks flow', (tester) async {
      // ── Launch & wait for tracks ──────────────────────────────────────────
      await TestHelper.launchApp(tester);
      await TestHelper.waitForTracks(tester);

      // --- Resolves to either a track list or the empty screen ---
      final hasList = find.byType(TrackList).evaluate().isNotEmpty;
      final isEmpty = find.byType(TrackEmptyScreen).evaluate().isNotEmpty;
      expect(hasList || isEmpty, isTrue);

      // ── Empty library path ────────────────────────────────────────────────
      if (!TestHelper.tracksAreLoaded()) {
        expect(find.byType(TrackEmptyScreen), findsOneWidget);
        expect(find.text('No music tracks available'), findsOneWidget);
        return;
      }

      // ── Tap a track → player opens ────────────────────────────────────────
      final firstTrack = find.byType(TrackTile).first;
      expect(firstTrack, findsOneWidget);

      await tester.tap(firstTrack);
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(PlayerScreen).evaluate().isNotEmpty,
        reason: 'player screen to open after tapping a track',
      );
      // Fixed pump — pumpAndSettle() hangs while audio stream is active.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(PlayerScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));

      // ── Back → mini player is mounted ─────────────────────────────────────
      await tester.tap(TestHelper.findMusicButton('assets/icons/back.png'));

      await tester.pump(const Duration(milliseconds: 600));

      await TestHelper.pumpUntil(
        tester,
        () => find.byType(PlayerScreen).evaluate().isEmpty,
        reason: 'player screen to close',
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MusicMiniPlayer), findsOneWidget);

      // ── Track list scrolls without crashing ───────────────────────────────
      await tester.drag(find.byType(TrackList), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TrackList), findsOneWidget);

      // ── Pause before leaving — stops FramePositionUpdater callbacks ───────
      final pauseBtn = TestHelper.findMusicButton('assets/icons/pause.png');
      if (pauseBtn.evaluate().isNotEmpty) {
        await tester.tap(pauseBtn);
        await tester.pump(const Duration(milliseconds: 400));
      }
    });
  });
}
