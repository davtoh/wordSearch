// test/features/word_search/presentation/game_screen_test.dart
// Widget tests for responsive layout adaptation, NavigationBar vs NavigationRail,
// BoardWidget gestures, and focus management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/engine/grid_engine.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/word_search/application/game_provider.dart';
import 'package:word_search_app/features/word_search/presentation/game_screen.dart';
import 'package:word_search_app/features/word_search/presentation/widgets/board_widget.dart';

void main() {
  Widget createTestWidget({
    Size screenSize = const Size(400, 800),
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const GameScreen(),
        ),
      ),
    );
  }

  testWidgets('renders narrow layout on mobile screens with NavigationBar and HUD',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    // Verify AppBar and title
    expect(find.text('Word Search App'), findsOneWidget);

    // Verify HUD elements
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.textContaining('Found: 0 /'), findsOneWidget);

    // Verify BoardWidget is present
    expect(find.byType(BoardWidget), findsOneWidget);

    // Verify Mobile NavigationBar is rendered
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    // Verify Word Bank chips
    expect(find.byType(FilterChip), findsWidgets);
  });

  testWidgets('renders wide layout on tablet/desktop with NavigationRail and Sidebar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(screenSize: const Size(1024, 768)));
    await tester.pumpAndSettle();

    // Verify NavigationRail is rendered on wide screen
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Verify Word Bank vertical list is displayed in sidebar
    expect(find.textContaining('Word Bank ('), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('tapping outside input fields unfocuses soft keyboards',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Stack(
            children: [
              const GameScreen(),
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Material(
                    child: TextField(focusNode: focusNode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // Tap on BoardWidget to trigger FocusScope.unfocus()
    await tester.tap(find.byType(BoardWidget));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('BoardWidget responds to pan and tap gestures',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final puzzle = GridEngine.generatePuzzle(
      wordsData: const [
        {'word': 'CAT', 'clue': 'Feline'},
        {'word': 'DOG', 'clue': 'Canine'},
      ],
      difficulty: Difficulty.easy,
    );

    container.read(gameProvider.notifier).initGame(puzzle, autoStartTimer: false);

    await tester.pumpWidget(createTestWidget(container: container));
    await tester.pumpAndSettle();

    final boardFinder = find.byType(BoardWidget);
    expect(boardFinder, findsOneWidget);

    // Tap on board center to test proximity trigger
    await tester.tap(boardFinder);
    await tester.pump();

    // Perform a small drag on the board
    final center = tester.getCenter(boardFinder);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // State is alive and intact
    final state = container.read(gameProvider);
    expect(state.status, GameStatus.playing);
  });

  testWidgets('requesting hint displays SnackBar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Hint button in NavigationBar
    await tester.tap(find.text('Hint'));
    await tester.pump();

    // Verify SnackBar pops up
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
