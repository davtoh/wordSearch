/// Settings & Theme Configuration Screen.
///
/// Provides live configuration of:
/// * Color theme: Light / Dark / High-Contrast (WCAG AA).
/// * Orientation preference: Auto-rotate vs. Portrait Lock.
/// * Font scale: 1.0× – 2.0× with a live-preview slider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ai/application/gemini_service.dart';
import '../application/theme_notifier.dart';

// ─────────────────────────────────────────────────────────
// SettingsScreen
// ─────────────────────────────────────────────────────────

/// Full settings view wired to [ThemeNotifier].
///
/// All interactive controls (toggles, chips, sliders) use
/// [Focus(canRequestFocus: false)] so they never trigger the soft keyboard.
/// A screen-wide [GestureDetector] calls [FocusScope.unfocus()] to dismiss
/// any residual keyboard from embedded text fields elsewhere in the app.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeNotifierProvider);
    final notifier = ref.read(themeNotifierProvider.notifier);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          leading: Focus(
            canRequestFocus: false,
            child: IconButton(
              key: const Key('settings_back_button'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
          title: const Text('Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // ── Color Theme ─────────────────────────────────────
            _SectionHeader(
              key: const Key('theme_section_header'),
              icon: Icons.palette_rounded,
              title: 'Color Theme',
            ),
            const SizedBox(height: 12),
            _ColorThemeSelector(
              current: settings.colorTheme,
              onChanged: notifier.setColorTheme,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // ── Orientation ──────────────────────────────────────
            _SectionHeader(
              key: const Key('orientation_section_header'),
              icon: Icons.screen_rotation_rounded,
              title: 'Orientation',
            ),
            const SizedBox(height: 12),
            _OrientationSelector(
              current: settings.orientationPreference,
              onChanged: notifier.setOrientationPreference,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // ── Font Scale ───────────────────────────────────────
            _SectionHeader(
              key: const Key('font_scale_section_header'),
              icon: Icons.text_fields_rounded,
              title: 'Font Size',
            ),
            const SizedBox(height: 8),
            _FontScaleSlider(
              value: settings.fontScaleFactor,
              onChanged: notifier.setFontScaleFactor,
              theme: theme,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // ── Live Preview ─────────────────────────────────────
            _SectionHeader(
              key: const Key('preview_section_header'),
              icon: Icons.preview_rounded,
              title: 'Live Preview',
            ),
            const SizedBox(height: 12),
            _LivePreviewCard(
              fontScaleFactor: settings.fontScaleFactor,
              colorTheme: settings.colorTheme,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // ── Gemini AI Configuration ──────────────────────────
            _SectionHeader(
              key: const Key('ai_section_header'),
              icon: Icons.auto_awesome_rounded,
              title: 'AI Word Generator',
            ),
            const SizedBox(height: 12),
            const _AiSettingsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _SectionHeader
// ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _ColorThemeSelector
// ─────────────────────────────────────────────────────────

/// Three-option chip row for Light / Dark / High-Contrast selection.
class _ColorThemeSelector extends StatelessWidget {
  const _ColorThemeSelector({
    required this.current,
    required this.onChanged,
  });

  final AppColorTheme current;
  final ValueChanged<AppColorTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Color theme selector',
      child: Wrap(
        key: const Key('color_theme_selector'),
        spacing: 10,
        runSpacing: 8,
        children: AppColorTheme.values.map((t) {
          final isSelected = current == t;
          return Focus(
            canRequestFocus: false,
            child: Semantics(
              label: '${t.label} theme${isSelected ? ', selected' : ''}',
              button: true,
              child: ChoiceChip(
                key: Key('theme_chip_${t.name}'),
                avatar: Icon(
                  t.icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: Text(t.label),
                selected: isSelected,
                onSelected: (_) => onChanged(t),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _OrientationSelector
// ─────────────────────────────────────────────────────────

/// Two-segment toggle for Auto-rotate vs. Portrait Lock.
class _OrientationSelector extends StatelessWidget {
  const _OrientationSelector({
    required this.current,
    required this.onChanged,
  });

  final OrientationPreference current;
  final ValueChanged<OrientationPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Orientation preference selector',
      child: Wrap(
        key: const Key('orientation_selector'),
        spacing: 10,
        runSpacing: 8,
        children: OrientationPreference.values.map((pref) {
          final isSelected = current == pref;
          return Focus(
            canRequestFocus: false,
            child: Semantics(
              label: '${pref.label}${isSelected ? ', selected' : ''}',
              button: true,
              child: ChoiceChip(
                key: Key('orientation_chip_${pref.name}'),
                avatar: Icon(
                  pref == OrientationPreference.autoRotate
                      ? Icons.screen_rotation_rounded
                      : Icons.screen_lock_portrait_rounded,
                  size: 18,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurface,
                ),
                label: Text(pref.label),
                selected: isSelected,
                onSelected: (_) => onChanged(pref),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _FontScaleSlider
// ─────────────────────────────────────────────────────────

/// Slider for selecting font scale factor in [1.0, 2.0].
/// Displays the current value as a percentage label (100% – 200%).
class _FontScaleSlider extends StatelessWidget {
  const _FontScaleSlider({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pct = '${(value * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Size: $pct',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text('A',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Text('A',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Semantics(
          label: 'Font size slider, current value $pct',
          slider: true,
          child: Focus(
            canRequestFocus: false,
            child: Slider(
              key: const Key('font_scale_slider'),
              value: value,
              min: 1.0,
              max: 2.0,
              divisions: 10,
              label: pct,
              onChanged: onChanged,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('100%',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('200%',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _LivePreviewCard
// ─────────────────────────────────────────────────────────

/// A card demonstrating how the current [fontScaleFactor] and [colorTheme]
/// affect actual text rendering in the UI.
class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({
    required this.fontScaleFactor,
    required this.colorTheme,
  });

  final double fontScaleFactor;
  final AppColorTheme colorTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Apply the user's font scale to the preview via a local MediaQuery override.
    return Card(
      key: const Key('live_preview_card'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(fontScaleFactor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.preview_rounded,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Preview — ${colorTheme.label} · '
                    '${(fontScaleFactor * 100).round()}%',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Word Search',
                key: const Key('preview_display_text'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find hidden words in the grid before time runs out. '
                'Explore topics from Science to History.',
                key: const Key('preview_body_text'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              // Mini chip row to demonstrate interactive surfaces.
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    key: const Key('preview_chip_easy'),
                    label: const Text('Easy'),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle:
                        TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  Chip(
                    key: const Key('preview_chip_hard'),
                    label: const Text('Hard'),
                    backgroundColor: colorScheme.tertiaryContainer,
                    labelStyle:
                        TextStyle(color: colorScheme.onTertiaryContainer),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _AiSettingsSection
// ─────────────────────────────────────────────────────────

class _AiSettingsSection extends ConsumerWidget {
  const _AiSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final geminiService = ref.watch(geminiServiceProvider);
    final customKey = ref.watch(customGeminiApiKeyProvider);
    final isConfigured = geminiService.isConfigured;

    return Card(
      key: const Key('ai_settings_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfigured ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isConfigured ? colorScheme.primary : colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isConfigured
                      ? 'AI Service Connected'
                      : 'No API Key Configured',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isConfigured ? colorScheme.primary : colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Model: ${geminiService.modelName}\n'
              '${customKey != null ? "Using custom key" : (isConfigured ? "Detected from .env / environment" : "Add GEMINI_API_KEY in .env or set below")}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Focus(
                  canRequestFocus: false,
                  child: OutlinedButton.icon(
                    key: const Key('set_api_key_button'),
                    onPressed: () => _showApiKeyDialog(context, ref, customKey),
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: Text(customKey != null ? 'Edit Key' : 'Set Key'),
                  ),
                ),
                if (customKey != null) ...[
                  const SizedBox(width: 8),
                  Focus(
                    canRequestFocus: false,
                    child: TextButton(
                      key: const Key('clear_api_key_button'),
                      onPressed: () => ref
                          .read(customGeminiApiKeyProvider.notifier)
                          .setApiKey(null),
                      child: const Text('Reset to .env'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentKey,
  ) async {
    final controller = TextEditingController(text: currentKey ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key. It will be stored in memory for this session.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy... or AQ....',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(customGeminiApiKeyProvider.notifier)
                  .setApiKey(controller.text.trim());
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

