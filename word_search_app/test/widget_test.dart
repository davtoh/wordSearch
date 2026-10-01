import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/main.dart';

void main() {
  testWidgets('App loads bootstrap screen smoke test', (WidgetTester tester) async {
    // WordSearchApp's home is GameScreen which uses Riverpod; wrap in ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(child: WordSearchApp()),
    );
    await tester.pumpAndSettle();

    // The AppBar title renders 'Word Search App' inside a FittedBox;
    // find.textContaining is resilient to widget tree wrapping.
    expect(find.textContaining('Word Search'), findsWidgets);
  });
}
