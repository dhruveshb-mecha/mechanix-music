import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/browse_music_top_bar.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/music_bottom_bar.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom navigation', () {
    testWidgets('full navigation flow', (tester) async {
      await TestHelper.launchApp(tester); // ← launched ONCE

      // --- Tracks tab (initial state) ---
      expect(find.byType(MusicBottomBar), findsOneWidget);
      expect(find.byType(MusicButton), findsNWidgets(4));
      expect(find.text('Tracks'), findsOneWidget);

      // --- Now Playing tab ---
      await TestHelper.tapTab(tester, TestHelper.nowPlayingTab);
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      // --- Search tab ---
      await TestHelper.tapTab(tester, TestHelper.searchTab);
      expect(find.text('Search'), findsWidgets);

      // --- Browse tab ---
      await TestHelper.tapTab(tester, TestHelper.browseTab);
      expect(find.byType(BrowseMusicTopBar), findsOneWidget);
      expect(find.text('Browse music folders'), findsOneWidget);

      // --- Back to Tracks ---
      await TestHelper.tapTab(tester, TestHelper.tracksTab);
      expect(find.text('Tracks'), findsOneWidget);
    });
  });
}
