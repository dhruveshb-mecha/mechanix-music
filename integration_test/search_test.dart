import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/search_tab.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search tab', () {
    testWidgets('navigation and basic state', (tester) async {
      await TestHelper.launchApp(tester);

      // --- Go to Search tab ---
      await TestHelper.tapTab(tester, TestHelper.searchTab);

      // Verify SearchTab is visible
      expect(find.byType(SearchTab), findsOneWidget);
      expect(find.text('Search'), findsWidgets);
    });
  });
}
