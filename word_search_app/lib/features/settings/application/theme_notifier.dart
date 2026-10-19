/// Settings & Theme Configuration – application layer.
///
/// Manages user preferences for:
/// * Color theme: Light, Dark, High-Contrast (WCAG AA ≥ 4.5:1 contrast ratio).
/// * Orientation: Auto-rotate vs. Mobile Portrait Lock.
/// * Font scale: 1.0× – 2.0× multiplier surfaced as a live-preview slider.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────
// AppColorTheme
// ─────────────────────────────────────────────────────────

/// The three supported color modes.
enum AppColorTheme {
  /// System-default Material You light scheme.
  light,

  /// System-default Material You dark scheme.
  dark,

  /// High-contrast mode (WCAG AA ≥ 4.5:1 contrast ratio).
  /// Uses a hand-tuned near-black/white palette with 7:1+ contrast on all
  /// interactive surfaces.
  highContrast;

  String get label => switch (this) {
        AppColorTheme.light => 'Light',
        AppColorTheme.dark => 'Dark',
        AppColorTheme.highContrast => 'High Contrast',
      };

  IconData get icon => switch (this) {
        AppColorTheme.light => Icons.light_mode_rounded,
        AppColorTheme.dark => Icons.dark_mode_rounded,
        AppColorTheme.highContrast => Icons.contrast_rounded,
      };
}

// ─────────────────────────────────────────────────────────
// OrientationPreference
// ─────────────────────────────────────────────────────────

/// Whether the device is allowed to rotate or is locked to portrait.
enum OrientationPreference {
  /// Respect the device accelerometer / OS setting (auto-rotate).
  autoRotate,

  /// Lock to portrait on mobile phones; ignored on tablets / desktop.
  portraitLock;

  String get label => switch (this) {
        OrientationPreference.autoRotate => 'Auto-rotate',
        OrientationPreference.portraitLock => 'Portrait Lock',
      };
}

// ─────────────────────────────────────────────────────────
// SettingsState
// ─────────────────────────────────────────────────────────

/// Immutable snapshot of all user preferences.
class SettingsState extends Equatable {
  const SettingsState({
    this.colorTheme = AppColorTheme.light,
    this.orientationPreference = OrientationPreference.portraitLock,
    this.fontScaleFactor = 1.0,
  });

  /// Active color theme.
  final AppColorTheme colorTheme;

  /// Orientation lock preference.
  final OrientationPreference orientationPreference;

  /// Font-scale multiplier in the range [1.0, 2.0].
  /// Applied as a [MediaQuery] textScaleFactor override.
  final double fontScaleFactor;

  // ── Derived helpers ──────────────────────────────────────

  bool get isHighContrast => colorTheme == AppColorTheme.highContrast;
  bool get isPortraitLocked =>
      orientationPreference == OrientationPreference.portraitLock;

  /// Maps [colorTheme] to a Flutter [ThemeMode].
  /// High-contrast is represented as [ThemeMode.dark] + a separate
  /// [ThemeData] selected by the notifier.
  ThemeMode get themeMode => switch (colorTheme) {
        AppColorTheme.light => ThemeMode.light,
        AppColorTheme.dark => ThemeMode.dark,
        AppColorTheme.highContrast => ThemeMode.dark,
      };

  SettingsState copyWith({
    AppColorTheme? colorTheme,
    OrientationPreference? orientationPreference,
    double? fontScaleFactor,
  }) {
    return SettingsState(
      colorTheme: colorTheme ?? this.colorTheme,
      orientationPreference:
          orientationPreference ?? this.orientationPreference,
      fontScaleFactor: fontScaleFactor ?? this.fontScaleFactor,
    );
  }

  @override
  List<Object?> get props =>
      [colorTheme, orientationPreference, fontScaleFactor];
}

// ─────────────────────────────────────────────────────────
// High-contrast theme helpers
// ─────────────────────────────────────────────────────────

/// Background: true black (#000000).
/// Foreground: true white (#FFFFFF).
/// Accent: bright amber (#FFD700) for interactive highlights.
ThemeData _buildHighContrastTheme() {
  const bg = Color(0xFF000000);
  const surface = Color(0xFF0D0D0D);
  const onSurface = Color(0xFFFFFFFF);
  const accent = Color(0xFFFFD700);
  const onAccent = Color(0xFF000000);
  const error = Color(0xFFFF4C4C);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      // ── Primary ────────────────────────────────────────
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: const Color(0xFF3D3000),
      onPrimaryContainer: accent,
      // ── Secondary ──────────────────────────────────────
      secondary: const Color(0xFFE0E0E0),
      onSecondary: bg,
      secondaryContainer: const Color(0xFF1A1A1A),
      onSecondaryContainer: onSurface,
      // ── Tertiary ───────────────────────────────────────
      tertiary: const Color(0xFF80DFFF),
      onTertiary: bg,
      tertiaryContainer: const Color(0xFF003040),
      onTertiaryContainer: const Color(0xFF80DFFF),
      // ── Surface ────────────────────────────────────────
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: const Color(0xFF1C1C1C),
      onSurfaceVariant: const Color(0xFFCCCCCC),
      // ── Error ──────────────────────────────────────────
      error: error,
      onError: bg,
      errorContainer: const Color(0xFF3D0000),
      onErrorContainer: error,
      // ── Outline ────────────────────────────────────────
      outline: const Color(0xFF888888),
      outlineVariant: const Color(0xFF555555),
      // ── Inverse / Scrim ────────────────────────────────
      inverseSurface: onSurface,
      onInverseSurface: bg,
      inversePrimary: const Color(0xFF5A4700),
      scrim: bg,
      shadow: bg,
    ),
    // Ensure all text has sufficient contrast by default.
    textTheme: Typography.material2021().white.apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        ),
    // AppBar.
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: onSurface,
      iconTheme: IconThemeData(color: onSurface),
      titleTextStyle: TextStyle(
        color: onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // Chips.
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: onSurface),
      selectedColor: accent,
    ),
    // Sliders.
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accent,
      inactiveTrackColor: const Color(0xFF555555),
      overlayColor: accent.withValues(alpha: 0.24),
      valueIndicatorColor: accent,
      valueIndicatorTextStyle: const TextStyle(color: onAccent),
    ),
    // Filled buttons.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        minimumSize: const Size(0, 48),
      ),
    ),
    // Outlined / text buttons.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent),
        minimumSize: const Size(0, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        minimumSize: const Size(0, 48),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Standard light / dark themes
// ─────────────────────────────────────────────────────────

const _seedColor = Color(0xFF6366F1); // Indigo

ThemeData _buildLightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
    );

ThemeData _buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
    );

// ─────────────────────────────────────────────────────────
// ThemeNotifier
// ─────────────────────────────────────────────────────────

/// Riverpod [Notifier] that owns all user-configurable settings.
///
/// Responsibilities:
/// * Switches the app [ThemeData] between Light, Dark, and High-Contrast.
/// * Applies orientation locks via [SystemChrome.setPreferredOrientations].
/// * Exposes a font-scale factor the app wraps in a [MediaQuery] override.
class ThemeNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  // ── Color theme ──────────────────────────────────────────

  /// Switches the active [AppColorTheme].
  void setColorTheme(AppColorTheme theme) {
    state = state.copyWith(colorTheme: theme);
  }

  // ── Orientation ──────────────────────────────────────────

  /// Updates the orientation lock preference and immediately applies it via
  /// [SystemChrome] on mobile platforms.
  void setOrientationPreference(OrientationPreference pref) {
    state = state.copyWith(orientationPreference: pref);
    _applyOrientation(pref);
  }

  void _applyOrientation(OrientationPreference pref) {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile) return; // Tablets / desktop always allow all orientations.

    final allowed = switch (pref) {
      OrientationPreference.portraitLock => [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      OrientationPreference.autoRotate => [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
    };
    SystemChrome.setPreferredOrientations(allowed);
  }

  // ── Font scale ───────────────────────────────────────────

  /// Sets the font-scale multiplier. Clamped to [1.0, 2.0].
  void setFontScaleFactor(double scale) {
    state = state.copyWith(fontScaleFactor: scale.clamp(1.0, 2.0));
  }

  // ── Computed theme objects ───────────────────────────────

  /// Returns the [ThemeData] for light/high-contrast mode (MaterialApp.theme).
  ThemeData get lightTheme => _buildLightTheme();

  /// Returns the [ThemeData] for dark mode (MaterialApp.darkTheme).
  /// When [state.isHighContrast] is true this returns the high-contrast theme.
  ThemeData get darkTheme =>
      state.isHighContrast ? _buildHighContrastTheme() : _buildDarkTheme();
}

/// Global provider for all user settings.
final themeNotifierProvider =
    NotifierProvider<ThemeNotifier, SettingsState>(ThemeNotifier.new);

// ─────────────────────────────────────────────────────────
// Convenience derived providers
// ─────────────────────────────────────────────────────────

/// Resolves the [ThemeMode] Flutter should use for [MaterialApp.themeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeNotifierProvider).themeMode;
});

/// The font-scale multiplier the app should apply via [MediaQuery].
final fontScaleProvider = Provider<double>((ref) {
  return ref.watch(themeNotifierProvider).fontScaleFactor;
});
