import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/main.dart';

void main() {
  testWidgets('App loads bootstrap screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WordSearchApp());

    expect(find.text('Word Search App'), findsOneWidget);
  });
}
