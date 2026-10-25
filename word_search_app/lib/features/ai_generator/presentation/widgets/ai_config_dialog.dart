import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/application/gemini_service.dart';

/// Shows the mobile-friendly AI Configuration modal dialog or bottom sheet.
Future<void> showAiConfigDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => const AiConfigDialog(),
  );
}

/// Interactive dialog for configuring Gemini API key, model selection, and
/// clipboard actions designed specifically for smooth mobile phone usage.
class AiConfigDialog extends ConsumerStatefulWidget {
  const AiConfigDialog({super.key});

  @override
  ConsumerState<AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends ConsumerState<AiConfigDialog> {
  late final TextEditingController _keyController;
  late String _selectedModel;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final currentCustomKey = ref.read(customGeminiApiKeyProvider);
    _keyController = TextEditingController(text: currentCustomKey ?? '');
    _selectedModel = ref.read(selectedGeminiModelProvider);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    if (!mounted) return;

    if (text != null && text.isNotEmpty) {
      setState(() {
        _keyController.text = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasted API key from clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty. Copy your API key first.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyStudioUrl() async {
    const url = 'https://aistudio.google.com/app/apikey';
    await Clipboard.setData(const ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google AI Studio link copied! Open browser to get key.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _save() {
    final enteredKey = _keyController.text.trim();
    ref
        .read(customGeminiApiKeyProvider.notifier)
        .setApiKey(enteredKey.isNotEmpty ? enteredKey : null);
    ref.read(selectedGeminiModelProvider.notifier).setModel(_selectedModel);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enteredKey.isNotEmpty
              ? 'Gemini AI configured with $_selectedModel!'
              : 'Gemini AI reset to default environment settings.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final geminiService = ref.watch(geminiServiceProvider);
    final isConfigured = geminiService.isConfigured;
    final hasCustomKey = ref.watch(customGeminiApiKeyProvider) != null;

    final selectedOption = kGeminiModels.firstWhere(
      (m) => m.id == _selectedModel,
      orElse: () => kGeminiModels.first,
    );

    return AlertDialog(
      key: const Key('ai_config_dialog'),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gemini AI Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isConfigured
                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isConfigured
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: isConfigured
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isConfigured
                          ? 'AI Status: Connected & Ready'
                          : 'AI Status: API Key Missing',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isConfigured
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Model Selection
            Text(
              'AI Model',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: kGeminiModels.map((opt) {
                final isSelected = opt.id == _selectedModel;
                return ChoiceChip(
                  key: Key('model_chip_${opt.id}'),
                  label: Text(
                    opt.isRecommended ? '${opt.name} ★' : opt.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedModel = opt.id);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              selectedOption.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            // API Key Input
            Text(
              'Gemini API Key',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('ai_config_key_input'),
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                hintText: 'Paste key (AIzaSy... or AQ....)',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 20,
                      ),
                      tooltip: _obscureKey ? 'Show key' : 'Hide key',
                      onPressed: () {
                        setState(() => _obscureKey = !_obscureKey);
                      },
                    ),
                    if (_keyController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() => _keyController.clear());
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Mobile Quick Action: Paste from Clipboard button
            OutlinedButton.icon(
              key: const Key('paste_key_button'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Paste Key from Clipboard'),
            ),
            const SizedBox(height: 4),

            // Free Key Link action
            TextButton.icon(
              key: const Key('get_free_key_link_button'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.secondary,
              ),
              onPressed: _copyStudioUrl,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'Get free key at aistudio.google.com (tap to copy link)',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (hasCustomKey)
          TextButton(
            key: const Key('ai_config_reset_button'),
            onPressed: () {
              ref.read(customGeminiApiKeyProvider.notifier).setApiKey(null);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to environment / .env configuration.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        TextButton(
          key: const Key('ai_config_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('ai_config_save_button'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
