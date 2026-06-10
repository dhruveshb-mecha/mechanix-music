import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_music/features/browse_music/presentation/screens/folder_contents_screen.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/browse_folder_tile.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_audio_tile.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_directory_tile.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_content_body.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_content_bottom_bar.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/selection_header.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Browse tab', () {
    testWidgets('full browse flow', (tester) async {
      // ── Launch & open Browse tab ──────────────────────────────────────────
      await TestHelper.launchApp(tester);
      await TestHelper.tapTab(tester, TestHelper.browseTab);
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(BrowseFolderTile).evaluate().isNotEmpty,
        reason: 'browse folder list to appear',
      );

      // --- Quick-access folders ---
      expect(find.text('Browse music folders'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recents'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);

      // ── Open Home folder ──────────────────────────────────────────────────
      await tester.tap(find.text('Home'));
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(FolderContentsScreen).evaluate().isNotEmpty,
        reason: 'folder contents screen to open',
      );
      await TestHelper.pumpUntil(
        tester,
        () => find
            .descendant(
              of: find.byType(FolderContentsScreen),
              matching: find.byType(CircularProgressIndicator),
            )
            .evaluate()
            .isEmpty,
        reason: 'folder load to finish',
      );

      // --- Breadcrumb header visible ---
      expect(find.byType(FolderContentsScreen), findsOneWidget);
      expect(find.text('Browse music'), findsOneWidget);
      expect(find.byType(FolderContentsBody), findsOneWidget);
      expect(find.byType(FolderContentBottomBar), findsOneWidget);

      // ── Folder Bottom Bar back button navigates up/back ───────────────────
      final backButton = TestHelper.findMusicButton('assets/icons/back.png');
      expect(backButton, findsOneWidget);

      // Dynamically test navigating to a subdirectory if one exists, then going up
      final dirTiles = find.byType(FolderDirectoryTile);
      if (dirTiles.evaluate().isNotEmpty) {
        final firstDir = dirTiles.first;
        final dirWidget = tester.widget<FolderDirectoryTile>(firstDir);
        final dirName = dirWidget.entry.name;

        // Go down
        await tester.tap(firstDir);
        await tester.pumpAndSettle();

        // Verify sub-folder loaded
        expect(find.text(dirName), findsWidgets);

        // Go back up using the bottom bar back button
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should be back at parent directory (Home)
        expect(find.byType(FolderContentsScreen), findsOneWidget);
      }

      // Tap bottom back button at the root folder level to pop the screen
      await tester.tap(backButton);
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(FolderContentsScreen).evaluate().isEmpty,
        reason: 'to pop back to the browse list',
      );

      expect(find.byType(FolderContentsScreen), findsNothing);
      expect(find.text('Browse music folders'), findsOneWidget);

      // ── Selection flow (only when audio files are present) ────────────────
      // Re-open Home for the selection steps.
      await tester.tap(find.text('Home'));
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(FolderContentsScreen).evaluate().isNotEmpty,
        reason: 'folder contents screen to open (second time)',
      );
      await TestHelper.pumpUntil(
        tester,
        () => find
            .descendant(
              of: find.byType(FolderContentsScreen),
              matching: find.byType(CircularProgressIndicator),
            )
            .evaluate()
            .isEmpty,
        reason: 'folder load to finish (second time)',
      );

      final audioTiles = find.byType(FolderAudioTile);
      if (audioTiles.evaluate().isEmpty) {
        // No audio files on this device — skip selection assertions.
        return;
      }

      // --- Long-press enters selection mode ---
      await tester.longPress(audioTiles.first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SelectionHeader), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byTooltip('Select all'), findsOneWidget);
      expect(find.byTooltip('Save to library'), findsOneWidget);

      // --- Select All toggles selection for all items ---
      await tester.tap(find.byTooltip('Select all'));
      await tester.pump(const Duration(milliseconds: 400));

      final totalAudioCount = audioTiles.evaluate().length;
      expect(find.text('$totalAudioCount selected'), findsOneWidget);

      // --- Save to library displays SnackBar and cancels selection mode ---
      await tester.tap(find.byTooltip('Save to library'));
      await tester.pump();

      // Verify SnackBar appears (since background is Color(0xFF151515))
      expect(find.byType(SnackBar), findsWidgets);

      // Settle SnackBar durations
      await tester.pump(const Duration(seconds: 3));

      // SelectionHeader should be gone and selection mode exited
      expect(find.byType(SelectionHeader), findsNothing);
      expect(find.text('Browse music'), findsOneWidget);
    });
  });
}
