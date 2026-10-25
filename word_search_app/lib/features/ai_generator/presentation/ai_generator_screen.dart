/// AI Topic Generator Screen.
///
/// Presents a prompt input field, generation controls, and an editable
/// Wrap-chip layout of AI-generated candidate words that the user can trim
/// before launching a [GameScreen] word-search puzzle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../application/gemini_service.dart';

// ─────────────────────────────────────────────────────────
// AiGeneratorScreen
// ─────────────────────────────────────────────────────────

/// Full-screen AI Topic Generator view.
///
/// Key UX behaviours:
/// * Only the topic [TextField] triggers the soft keyboard; all other
///   interactive targets use [Focus(canRequestFocus: false)] so they
///   never accidentally steal keyboard focus.
/// * A screen-wide [GestureDetector] calls
///   [FocusScope.of(context).unfocus()] so the keyboard is dismissed
///   whenever the user taps outside the text field.
/// * Loading state is shown as a [CircularProgressIndicator] overlay.
/// * Errors are surfaced in a [SnackBar] and an inline banner.
/// * Candidate words returned by Gemini are shown in an editable
///   [Wrap] of [Chip]s; each chip can be deleted and the user can add
///   custom words via a small bottom-sheet dialog.
class AiGeneratorScreen extends ConsumerStatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  ConsumerState<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends ConsumerState<AiGeneratorScreen> {
  // Explicit FocusNode so the keyboard only appears when this field is tapped.
  late final FocusNode _topicFocusNode;
  late final TextEditingController _topicController;

  @override
  void initState() {
    super.initState();
    _topicFocusNode = FocusNode();
    _topicController = TextEditingController();
  }

  @override
  void dispose() {
    _topicFocusNode.dispose();
    _topicController.dispose();
    super.dispose();
  }

  // ── Keyboard helpers ─────────────────────────────────────

  void _unfocusKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // ── Generation ───────────────────────────────────────────

  Future<void> _onGenerate() async {
    _unfocusKeyboard();
    final notifier = ref.read(aiGeneratorProvider.notifier);
    notifier.setTopic(_topicController.text);
    await notifier.generateWords();

    // Show error in SnackBar if the generation failed.
    if (!mounted) return;
    final state = ref.read(aiGeneratorProvider);
    if (state.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('ai_error_snack_bar'),
          content: Text(state.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            key: const Key('ai_error_retry_action'),
            label: 'Retry',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _onGenerate,
          ),
        ),
      );
    }
  }

  // ── Game launch ──────────────────────────────────────────

  Future<void> _onLaunchGame() async {
    _unfocusKeyboard();
    await ref.read(aiGeneratorProvider.notifier).launchGame(
          navigateTo: (route) => context.go(route),
        );
  }

  // ── Add word dialog ──────────────────────────────────────

  Future<void> _showAddWordDialog() async {
    _unfocusKeyboard();
    final wordController = TextEditingController();
    final clueController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('add_word_dialog'),
        title: const Text('Add a Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('add_word_input'),
              controller: wordController,
              decoration: const InputDecoration(
                labelText: 'Word',
                hintText: 'e.g. QUANTUM',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('add_clue_input'),
              controller: clueController,
              decoration: const InputDecoration(
                labelText: 'Clue (optional)',
                hintText: 'e.g. Smallest unit of energy',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('add_word_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('add_word_confirm_button'),
            onPressed: () {
              ref.read(aiGeneratorProvider.notifier).addCandidateWord(
                    word: wordController.text,
                    clue: clueController.text.trim().isNotEmpty
                        ? clueController.text.trim()
                        : null,
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    wordController.dispose();
    clueController.dispose();
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGeneratorProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen for state changes to show errors proactively.
    ref.listen<AiGeneratorState>(aiGeneratorProvider, (prev, next) {
      if (next.isError && next.errorMessage != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('ai_error_snack_bar'),
            content: Text(next.errorMessage!),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    return GestureDetector(
      // Dismiss keyboard when tapping outside the text field.
      onTap: _unfocusKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          leading: Focus(
            canRequestFocus: false,
            child: IconButton(
              key: const Key('ai_generator_back_button'),
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
          title: const Text('AI Topic Generator'),
          actions: [
            // Clear all chip button — non-text, so canRequestFocus: false.
            if (aiState.hasWords)
              Focus(
                canRequestFocus: false,
                child: IconButton(
                  key: const Key('ai_clear_words_button'),
                  icon: const Icon(Icons.clear_all_rounded),
                  tooltip: 'Clear all words',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () {
                    ref.read(aiGeneratorProvider.notifier).clearCandidates();
                  },
                ),
              ),
          ],
        ),
        body: _AiGeneratorBody(
          aiState: aiState,
          topicFocusNode: _topicFocusNode,
          topicController: _topicController,
          onGenerate: _onGenerate,
          onLaunchGame: _onLaunchGame,
          onAddWord: _showAddWordDialog,
          onRemoveWord: (index) =>
              ref.read(aiGeneratorProvider.notifier).removeCandidateAt(index),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _AiGeneratorBody
// ─────────────────────────────────────────────────────────

/// Scrollable body of the generator screen, extracted for readability.
class _AiGeneratorBody extends StatelessWidget {
  const _AiGeneratorBody({
    required this.aiState,
    required this.topicFocusNode,
    required this.topicController,
    required this.onGenerate,
    required this.onLaunchGame,
    required this.onAddWord,
    required this.onRemoveWord,
  });

  final AiGeneratorState aiState;
  final FocusNode topicFocusNode;
  final TextEditingController topicController;
  final VoidCallback onGenerate;
  final VoidCallback onLaunchGame;
  final VoidCallback onAddWord;
  final void Function(int index) onRemoveWord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // ── Scrollable content ───────────────────────────────
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Topic input ──────────────────────────────
                  _TopicInputSection(
                    focusNode: topicFocusNode,
                    controller: topicController,
                    isLoading: aiState.isLoading,
                    onGenerate: onGenerate,
                  ),
                  const SizedBox(height: 16),

                  // ── Difficulty selector ──────────────────────
                  _DifficultyRow(aiState: aiState),
                  const SizedBox(height: 8),

                  // ── Error banner ─────────────────────────────
                  if (aiState.isError && aiState.errorMessage != null) ...[
                    _ErrorBanner(message: aiState.errorMessage!),
                    const SizedBox(height: 12),
                  ],

                  // ── Candidate chip wrap ──────────────────────
                  if (aiState.hasWords) ...[
                    _CandidateWordsSection(
                      words: aiState.candidateWords,
                      onRemove: onRemoveWord,
                      onAddWord: onAddWord,
                    ),
                    const SizedBox(height: 24),

                    // ── Launch game button ───────────────────────
                    _LaunchGameButton(
                      wordCount: aiState.candidateWords.length,
                      onPressed: aiState.candidateWords.length >= 3
                          ? onLaunchGame
                          : null,
                    ),
                  ],

                  // ── Empty state / hint ───────────────────────
                  if (aiState.isIdle && !aiState.hasWords)
                    _EmptyStateHint(colorScheme: colorScheme, theme: theme),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),

        // ── Loading overlay ──────────────────────────────────
        if (aiState.isLoading)
          Container(
            key: const Key('ai_loading_overlay'),
            color: colorScheme.surface.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    key: Key('ai_loading_indicator'),
                  ),
                  SizedBox(height: 16),
                  Text('Generating words…'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _TopicInputSection
// ─────────────────────────────────────────────────────────

class _TopicInputSection extends ConsumerWidget {
  const _TopicInputSection({
    required this.focusNode,
    required this.controller,
    required this.isLoading,
    required this.onGenerate,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final geminiService = ref.watch(geminiServiceProvider);
    final isConfigured = geminiService.isConfigured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter a Topic',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConfigured
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 14,
                  color: isConfigured
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isConfigured ? 'Gemini AI Ready' : 'API Key Missing',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isConfigured
                        ? colorScheme.primary
                        : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // The ONLY widget in this screen that can own keyboard focus.
        TextField(
          key: const Key('ai_topic_input'),
          focusNode: focusNode,
          controller: controller,
          enabled: !isLoading,
          decoration: InputDecoration(
            hintText: 'e.g. Space Exploration, Ancient Rome, Chemistry…',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.auto_awesome_rounded),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    key: const Key('ai_topic_clear_button'),
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clear,
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onGenerate(),
        ),
        const SizedBox(height: 12),

        // Generate button — non-text, so canRequestFocus: false.
        Focus(
          canRequestFocus: false,
          child: FilledButton.icon(
            key: const Key('ai_generate_button'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: isLoading ? null : onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(isLoading ? 'Generating…' : 'Generate Words'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _DifficultyRow
// ─────────────────────────────────────────────────────────

class _DifficultyRow extends ConsumerWidget {
  const _DifficultyRow({required this.aiState});

  final AiGeneratorState aiState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(aiGeneratorProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: Difficulty.values
          .where((d) => d != Difficulty.dynamic)
          .map((d) => Focus(
                canRequestFocus: false,
                child: ChoiceChip(
                  key: Key('difficulty_chip_${d.name}'),
                  label: Text(d.name[0].toUpperCase() + d.name.substring(1)),
                  selected: aiState.difficulty == d,
                  onSelected: (_) => notifier.setDifficulty(d),
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _ErrorBanner
// ─────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('ai_error_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _CandidateWordsSection
// ─────────────────────────────────────────────────────────

/// Editable Wrap of [Chip]s showing the AI-generated candidate words.
class _CandidateWordsSection extends StatelessWidget {
  const _CandidateWordsSection({
    required this.words,
    required this.onRemove,
    required this.onAddWord,
  });

  final List<Map<String, String?>> words;
  final void Function(int index) onRemove;
  final VoidCallback onAddWord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Text(
                'Candidate Words (${words.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Add word button — non-text target, canRequestFocus: false.
              Focus(
                canRequestFocus: false,
                child: TextButton.icon(
                  key: const Key('ai_add_word_button'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: onAddWord,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Candidate words wrap list. Tap the × on a chip to remove it.',
          child: Wrap(
            key: const Key('candidate_words_wrap'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < words.length; i++)
                Semantics(
                  label: 'Word: ${words[i]['word']}. Tap to remove.',
                  button: true,
                  child: Focus(
                    canRequestFocus: false,
                    child: InputChip(
                      key: Key('candidate_chip_$i'),
                      label: Text(
                        words[i]['word'] ?? '',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: colorScheme.secondaryContainer,
                      tooltip: words[i]['clue'],
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      deleteButtonTooltipMessage: 'Remove word',
                      onDeleted: () => onRemove(i),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _LaunchGameButton
// ─────────────────────────────────────────────────────────

class _LaunchGameButton extends StatelessWidget {
  const _LaunchGameButton({
    required this.wordCount,
    required this.onPressed,
  });

  final int wordCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Start word search puzzle with $wordCount words',
      child: Focus(
        canRequestFocus: false,
        child: FilledButton.icon(
          key: const Key('ai_launch_game_button'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: colorScheme.tertiary,
            foregroundColor: colorScheme.onTertiary,
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: Text(
            'Start Puzzle ($wordCount words)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _EmptyStateHint
// ─────────────────────────────────────────────────────────

class _EmptyStateHint extends StatelessWidget {
  const _EmptyStateHint({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Type a topic and tap Generate',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Gemini AI creates fresh, thematic vocabulary words for your puzzle.\n'
            'Uses your GEMINI_API_KEY from .env or configured in Settings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
