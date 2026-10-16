import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/features/settings/application/theme_notifier.dart';
import 'package:word_search_app/features/settings/presentation/settings_screen.dart';

// ─────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────

Widget _wrapSettings() {
  return const ProviderScope(
    child: MaterialApp(home: SettingsScreen()),
  );
}

ProviderContainer _makeContainer({SettingsState? initial}) {
  final container = ProviderContainer(
    overrides: initial == null
        ? []
        : [
            themeNotifierProvider.overrideWith(
              () => _SeedableThemeNotifier(initial),
            ),
          ],
  );
  return container;
}

/// Allows seeding ThemeNotifier with a custom initial state in tests.
class _SeedableThemeNotifier extends ThemeNotifier {
  _SeedableThemeNotifier(this._initial);
  final SettingsState _initial;

  @override
  SettingsState build() => _initial;
}

// ─────────────────────────────────────────────────────────
// ThemeNotifier unit tests
// ─────────────────────────────────────────────────────────

void main() {
  group('ThemeNotifier unit tests', () {
    test('initial state has light theme, portrait lock, 1.0 font scale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(themeNotifierProvider);
      expect(state.colorTheme, AppColorTheme.light);
      expect(state.orientationPreference, OrientationPreference.portraitLock);
      expect(state.fontScaleFactor, 1.0);
      expect(state.isHighContrast, isFalse);
      expect(state.isPortraitLocked, isTrue);
    });

    test('setColorTheme updates colorTheme and themeMode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.dark);
      expect(container.read(themeNotifierProvider).colorTheme, AppColorTheme.dark);
      expect(container.read(themeNotifierProvider).themeMode, ThemeMode.dark);

      notifier.setColorTheme(AppColorTheme.highContrast);
      expect(container.read(themeNotifierProvider).isHighContrast, isTrue);
      // High-contrast is surfaced as ThemeMode.dark (custom dark theme).
      expect(container.read(themeNotifierProvider).themeMode, ThemeMode.dark);

      notifier.setColorTheme(AppColorTheme.light);
      expect(container.read(themeNotifierProvider).themeMode, ThemeMode.light);
    });

    test('setOrientationPreference updates orientationPreference', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeNotifierProvider.notifier)
          .setOrientationPreference(OrientationPreference.autoRotate);

      final state = container.read(themeNotifierProvider);
      expect(state.orientationPreference, OrientationPreference.autoRotate);
      expect(state.isPortraitLocked, isFalse);
    });

    test('setFontScaleFactor clamps to [1.0, 2.0]', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setFontScaleFactor(0.5); // below minimum
      expect(container.read(themeNotifierProvider).fontScaleFactor, 1.0);

      notifier.setFontScaleFactor(3.0); // above maximum
      expect(container.read(themeNotifierProvider).fontScaleFactor, 2.0);

      notifier.setFontScaleFactor(1.5); // valid mid-range
      expect(container.read(themeNotifierProvider).fontScaleFactor, 1.5);
    });

    test('lightTheme returns a valid ThemeData with light brightness', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      final theme = notifier.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme returns standard dark theme when colorTheme is dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.dark);
      final theme = notifier.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme returns high-contrast theme when colorTheme is highContrast',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.highContrast);
      final theme = notifier.darkTheme;
      expect(theme.brightness, Brightness.dark);
      // High-contrast uses a near-black scaffold background.
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('high-contrast colorScheme primary is amber (WCAG AAA contrast with black)',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.highContrast);
      final scheme = notifier.darkTheme.colorScheme;
      expect(scheme.primary, const Color(0xFFFFD700));
      expect(scheme.onPrimary, const Color(0xFF000000));
    });

    test('themeModeProvider derives correctly from colorTheme', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeNotifierProvider.notifier).setColorTheme(AppColorTheme.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeNotifierProvider.notifier).setColorTheme(AppColorTheme.highContrast);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('fontScaleProvider tracks fontScaleFactor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(fontScaleProvider), 1.0);

      container.read(themeNotifierProvider.notifier).setFontScaleFactor(1.8);
      expect(container.read(fontScaleProvider), 1.8);
    });

    test('SettingsState copyWith preserves unchanged fields', () {
      const original = SettingsState(
        colorTheme: AppColorTheme.dark,
        orientationPreference: OrientationPreference.autoRotate,
        fontScaleFactor: 1.5,
      );

      final updated = original.copyWith(colorTheme: AppColorTheme.light);
      expect(updated.colorTheme, AppColorTheme.light);
      expect(updated.orientationPreference, OrientationPreference.autoRotate);
      expect(updated.fontScaleFactor, 1.5);
    });

    test('SettingsState equality holds for identical states', () {
      const a = SettingsState(
        colorTheme: AppColorTheme.highContrast,
        fontScaleFactor: 1.25,
      );
      const b = SettingsState(
        colorTheme: AppColorTheme.highContrast,
        fontScaleFactor: 1.25,
      );
      expect(a, equals(b));
    });
  });

  // ─────────────────────────────────────────────────────────
  // SettingsScreen widget tests
  // ─────────────────────────────────────────────────────────

  group('SettingsScreen widget tests', () {
    testWidgets('renders all three section headers', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pump();

      expect(find.byKey(const Key('theme_section_header')), findsOneWidget);
      expect(find.byKey(const Key('orientation_section_header')), findsOneWidget);
      expect(find.byKey(const Key('font_scale_section_header')), findsOneWidget);
    });

    testWidgets('renders color-theme chip for each AppColorTheme value',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      for (final theme in AppColorTheme.values) {
        expect(
          find.byKey(Key('theme_chip_${theme.name}')),
          findsOneWidget,
          reason: 'Expected chip for ${theme.name}',
        );
      }
    });

    testWidgets('tapping Dark chip changes state to dark theme', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Dark chip.
      await tester.tap(find.byKey(const Key('theme_chip_dark')));
      await tester.pump();

      expect(
        container.read(themeNotifierProvider).colorTheme,
        AppColorTheme.dark,
      );
    });

    testWidgets('tapping High Contrast chip updates state to highContrast',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme_chip_highContrast')));
      await tester.pump();

      expect(
        container.read(themeNotifierProvider).isHighContrast,
        isTrue,
      );
    });

    testWidgets('renders orientation chip for each OrientationPreference',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      for (final pref in OrientationPreference.values) {
        expect(
          find.byKey(Key('orientation_chip_${pref.name}')),
          findsOneWidget,
          reason: 'Expected chip for ${pref.name}',
        );
      }
    });

    testWidgets('tapping Auto-rotate chip updates orientation preference',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Intercept the SystemChrome call so it doesn't throw in test.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
          find.byKey(const Key('orientation_chip_autoRotate')));
      await tester.pump();

      expect(
        container.read(themeNotifierProvider).orientationPreference,
        OrientationPreference.autoRotate,
      );
    });

    testWidgets('renders font scale slider with correct initial value',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const Key('font_scale_slider')),
      );
      expect(slider.value, 1.0);
      expect(slider.min, 1.0);
      expect(slider.max, 2.0);
    });

    testWidgets('dragging font scale slider to 1.5 updates state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the slider and drag it to the midpoint (1.5 = 50% of 1.0–2.0).
      final sliderFinder = find.byKey(const Key('font_scale_slider'));
      final sliderRect = tester.getRect(sliderFinder);
      final midX = sliderRect.left + sliderRect.width * 0.5;
      await tester.tapAt(Offset(midX, sliderRect.center.dy));
      await tester.pump();

      final scale = container.read(themeNotifierProvider).fontScaleFactor;
      // Allow ±0.1 tolerance for slider step rounding.
      expect(scale, greaterThanOrEqualTo(1.4));
      expect(scale, lessThanOrEqualTo(1.6));
    });

    testWidgets('live preview card is rendered', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('live_preview_card')), findsOneWidget);
      expect(find.byKey(const Key('preview_display_text')), findsOneWidget);
      expect(find.byKey(const Key('preview_body_text')), findsOneWidget);
    });

    testWidgets('live preview card reflects updated font scale', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Set scale to 2.0 via the notifier directly.
      container.read(themeNotifierProvider.notifier).setFontScaleFactor(2.0);
      await tester.pump();

      // The preview card should exist and the slider should show max value.
      expect(find.byKey(const Key('live_preview_card')), findsOneWidget);
      final slider =
          tester.widget<Slider>(find.byKey(const Key('font_scale_slider')));
      expect(slider.value, 2.0);
    });

    testWidgets('preview section header is rendered', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preview_section_header')), findsOneWidget);
    });

    testWidgets(
        'non-text controls cannot request focus (keyboard prevention)',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      // The theme chips must be wrapped in Focus(canRequestFocus: false).
      for (final t in AppColorTheme.values) {
        final chipKey = Key('theme_chip_${t.name}');
        final focusWidgets = tester.widgetList<Focus>(
          find.ancestor(
            of: find.byKey(chipKey),
            matching: find.byType(Focus),
          ),
        );
        // At least one ancestor Focus should have canRequestFocus: false.
        final hasNoFocusAncestor =
            focusWidgets.any((f) => f.canRequestFocus == false);
        expect(
          hasNoFocusAncestor,
          isTrue,
          reason: '${t.name} chip should have a non-focusable Focus ancestor',
        );
      }
    });

    testWidgets('all AppColorTheme labels are displayed', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      for (final t in AppColorTheme.values) {
        expect(
          find.text(t.label),
          findsOneWidget,
          reason: 'Expected label "${t.label}" to be visible',
        );
      }
    });

    testWidgets('all OrientationPreference labels are displayed', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      for (final pref in OrientationPreference.values) {
        expect(
          find.text(pref.label),
          findsOneWidget,
          reason: 'Expected label "${pref.label}" to be visible',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────
  // High-contrast WCAG AA contrast verification
  // ─────────────────────────────────────────────────────────

  group('High-contrast WCAG AA contrast ratio', () {
    /// Relative luminance per WCAG 2.1 §1.4.3.
    double _luminance(Color c) {
      double f(double v) {
        v = v / 255.0;
        return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) * ((v + 0.055) / 1.055);
      }
      return 0.2126 * f(c.red.toDouble()) +
          0.7152 * f(c.green.toDouble()) +
          0.0722 * f(c.blue.toDouble());
    }

    double _contrast(Color a, Color b) {
      final la = _luminance(a);
      final lb = _luminance(b);
      final lighter = la > lb ? la : lb;
      final darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('high-contrast primary (amber) on onPrimary (black) exceeds 4.5:1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.highContrast);
      final scheme = notifier.darkTheme.colorScheme;

      final ratio = _contrast(scheme.primary, scheme.onPrimary);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason:
              'WCAG AA requires ≥ 4.5:1 contrast ratio. Got ${ratio.toStringAsFixed(2)}:1');
    });

    test('high-contrast surface (near-black) on onSurface (white) exceeds 4.5:1',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.highContrast);
      final scheme = notifier.darkTheme.colorScheme;

      final ratio = _contrast(scheme.surface, scheme.onSurface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason:
              'WCAG AA requires ≥ 4.5:1 contrast ratio. Got ${ratio.toStringAsFixed(2)}:1');
    });

    test('high-contrast error (bright red) on errorContainer (near-black) exceeds 4.5:1',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeNotifierProvider.notifier);

      notifier.setColorTheme(AppColorTheme.highContrast);
      final scheme = notifier.darkTheme.colorScheme;

      final ratio = _contrast(scheme.error, scheme.errorContainer);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason:
              'WCAG AA requires ≥ 4.5:1 contrast ratio. Got ${ratio.toStringAsFixed(2)}:1');
    });
  });
}
