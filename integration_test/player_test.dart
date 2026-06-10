import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/presentation/screens/music_screen.dart';
import 'package:mechanix_music/features/music/presentation/screens/player_screen.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_controls.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_header.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_vinyl.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_tile.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Player screen', () {
    testWidgets('full player flow', (tester) async {
      // ── Launch & wait for tracks ──────────────────────────────────────────
      await TestHelper.launchApp(tester);
      await TestHelper.waitForTracks(tester);

      // Empty library — nothing to test.
      if (!TestHelper.tracksAreLoaded()) return;

      // ── Open the player ───────────────────────────────────────────────────
      await tester.tap(find.byType(TrackTile).first);
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(PlayerScreen).evaluate().isNotEmpty,
        reason: 'player screen to open',
      );
      await tester.pump(const Duration(milliseconds: 600));

      // --- Header, vinyl and controls are visible ---
      expect(find.byType(PlayerHeader), findsOneWidget);
      expect(find.byType(PlayerVinyl), findsOneWidget);
      expect(find.byType(PlayerControls), findsOneWidget);

      // --- Previous / play-pause / next controls are present ---
      expect(
        TestHelper.findMusicButton('assets/icons/previous.png'),
        findsOneWidget,
      );
      expect(
        TestHelper.findMusicButton('assets/icons/next.png'),
        findsOneWidget,
      );
      final hasPause = TestHelper.findMusicButton(
        'assets/icons/pause.png',
      ).evaluate().isNotEmpty;
      final hasResume = TestHelper.findMusicButton(
        'assets/icons/resume.png',
      ).evaluate().isNotEmpty;
      expect(hasPause || hasResume, isTrue);

      // ── Play / pause toggles twice without crashing ───────────────────────
      for (var i = 0; i < 2; i++) {
        final pause = TestHelper.findMusicButton('assets/icons/pause.png');
        final resume = TestHelper.findMusicButton('assets/icons/resume.png');
        final toggle = pause.evaluate().isNotEmpty ? pause : resume;
        await tester.tap(toggle.first);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(PlayerControls), findsOneWidget);

      // ── Next and previous are tappable ────────────────────────────────────
      await tester.tap(TestHelper.findMusicButton('assets/icons/next.png'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PlayerScreen), findsOneWidget);

      await tester.tap(TestHelper.findMusicButton('assets/icons/previous.png'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PlayerScreen), findsOneWidget);

      // ── Pause before leaving — stops FramePositionUpdater callbacks ───────
      // If the song is currently playing (pause icon visible), tap pause so
      // audioplayers stops scheduling frame callbacks before the widget tree
      // is torn down. Without this the test ends with "animation still running"
      // because FramePositionUpdater keeps ticking after dispose.
      final pauseBtn = TestHelper.findMusicButton('assets/icons/pause.png');
      if (pauseBtn.evaluate().isNotEmpty) {
        await tester.tap(pauseBtn);
        await tester.pump(const Duration(milliseconds: 400));
      }

      // ── Back button returns to the music screen ───────────────────────────
      expect(find.byType(MusicButton), findsWidgets);
      await tester.tap(TestHelper.findMusicButton('assets/icons/back.png'));
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(PlayerScreen).evaluate().isEmpty,
        reason: 'player screen to close',
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.byType(MusicScreen), findsOneWidget);
    });
  });
}
