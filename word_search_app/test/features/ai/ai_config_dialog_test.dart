import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/features/ai/application/gemini_service.dart';
import 'package:word_search_app/features/ai_generator/presentation/ai_generator_screen.dart';
import 'package:word_search_app/features/ai_generator/presentation/widgets/ai_config_dialog.dart';

Widget _wrapDialog({ProviderContainer? container}) {
  return UncontrolledProviderScope(
    container: container ?? ProviderContainer(),
    child: const MaterialApp(
      home: Scaffold(
        body: AiConfigDialog(),
      ),
    ),
  );
}

void main() {
  group('SelectedGeminiModelNotifier unit tests', () {
    test('initial model matches resolved default model', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialModel = container.read(selectedGeminiModelProvider);
      expect(initialModel, isNotEmpty);
      expect(kGeminiModels.any((m) => m.id == initialModel), isTrue);
    });

    test('setModel updates selected model state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedGeminiModelProvider.notifier);
      notifier.setModel('gemini-3.8-flash');

      expect(container.read(selectedGeminiModelProvider), 'gemini-3.8-flash');
    });

    test('geminiServiceProvider reflects selected model', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedGeminiModelProvider.notifier).setModel('gemini-3.1-flash-lite');
      final service = container.read(geminiServiceProvider);
      expect(service.modelName, 'gemini-3.1-flash-lite');
    });
  });

  group('AiConfigDialog widget tests', () {
    testWidgets('renders title, status banner, model chips, and paste button',
        (tester) async {
      await tester.pumpWidget(_wrapDialog());
      await tester.pumpAndSettle();

      expect(find.text('Gemini AI Configuration'), findsOneWidget);
      expect(find.byKey(const Key('paste_key_button')), findsOneWidget);
      expect(find.byKey(const Key('get_free_key_link_button')), findsOneWidget);
      expect(find.byKey(const Key('ai_config_key_input')), findsOneWidget);

      for (final model in kGeminiModels) {
        expect(find.byKey(Key('model_chip_${model.id}')), findsOneWidget);
      }
    });

    testWidgets('tapping model choice chip updates local selection',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapDialog(container: container));
      await tester.pumpAndSettle();

      // Tap 3.8 Flash chip
      await tester.tap(find.byKey(const Key('model_chip_gemini-3.8-flash')));
      await tester.pumpAndSettle();

      // Enter key and save
      await tester.enterText(
        find.byKey(const Key('ai_config_key_input')),
        'AIzaSyTestApiKey123',
      );
      await tester.tap(find.byKey(const Key('ai_config_save_button')));
      await tester.pumpAndSettle();

      expect(container.read(selectedGeminiModelProvider), 'gemini-3.8-flash');
      expect(container.read(customGeminiApiKeyProvider), 'AIzaSyTestApiKey123');
    });

    testWidgets('AiGeneratorScreen contains status badge and config button',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AiGeneratorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_config_action_button')), findsOneWidget);
      expect(find.byKey(const Key('ai_status_badge')), findsOneWidget);

      // Tap status badge to open dialog
      await tester.tap(find.byKey(const Key('ai_status_badge')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_config_dialog')), findsOneWidget);
    });

    testWidgets('AiGeneratorScreen opens config dialog from AppBar action',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AiGeneratorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_config_action_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_config_dialog')), findsOneWidget);
    });
  });
}
