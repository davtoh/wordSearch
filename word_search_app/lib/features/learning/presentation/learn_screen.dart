import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/models/models.dart';
import '../../word_search/presentation/widgets/board_widget.dart';
import '../application/learning_provider.dart';
import '../application/mastery_notifier.dart';

/// Screen presenting vocabulary flashcards, spaced-repetition performance metrics,
/// interactive mastery deck filtering, and targeted un-mastered word search practice.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({
    super.key,
    this.initialReviewMode = false,
  });

  /// Allows initializing directly into practice review board for testing.
  final bool initialReviewMode;

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Orientation lock: lock mobile phones to portrait, allow flexible orientations on tablets/desktop
    _configureOrientation();

    // Populate initial vocabulary deck if currently empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masteryNotifierProvider.notifier).seedDefaultDeckIfEmpty();
      if (widget.initialReviewMode) {
        ref.read(masteryNotifierProvider.notifier).generateUnmasteredPuzzle();
      }
    });
  }

  void _configureOrientation() {
    final isMobilePhone = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobilePhone) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _unfocusSoftKeyboard() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    FocusScope.of(context).unfocus();
  }

  void _handleStartUnmasteredGame() {
    _unfocusSoftKeyboard();
    final unmastered = ref.read(unmasteredWordsProvider);

    if (unmastered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All vocabulary words are currently mastered! Play standard games to discover new words.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final puzzle = ref
        .read(masteryNotifierProvider.notifier)
        .startUnmasteredGameAndNavigate(context: context);

    if (puzzle != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Started review puzzle with ${puzzle.words.length} un-mastered words!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final masteryState = ref.watch(masteryNotifierProvider);
    final masteryNotifier = ref.read(masteryNotifierProvider.notifier);
    final filteredWords = ref.watch(filteredVocabularyProvider);
    final summary = ref.watch(vocabularySummaryProvider);
    final unmasteredCount = ref.watch(unmasteredWordsProvider).length;

    return Focus(
      canRequestFocus: false,
      child: GestureDetector(
        key: const Key('learn_screen_gesture_detector'),
        behavior: HitTestBehavior.opaque,
        onTap: _unfocusSoftKeyboard,
        child: Scaffold(
          key: const Key('learn_screen_scaffold'),
          appBar: AppBar(
            leading: IconButton(
              key: const Key('learn_back_button'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Menu',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () {
                _unfocusSoftKeyboard();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.menu);
                }
              },
            ),
            title: const Text('Learn & Mastery'),
            actions: [
              // Toggle In-Screen Review Board
              IconButton(
                key: const Key('toggle_practice_board_button'),
                icon: Icon(
                  masteryState.isReviewMode
                      ? Icons.style_rounded
                      : Icons.grid_view_rounded,
                ),
                tooltip: masteryState.isReviewMode
                    ? 'Switch to Flashcards View'
                    : 'Switch to Review Grid View',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  _unfocusSoftKeyboard();
                  if (!masteryState.isReviewMode &&
                      masteryState.activeReviewPuzzle == null) {
                    masteryNotifier.generateUnmasteredPuzzle();
                  } else {
                    masteryNotifier.toggleReviewMode();
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                // Mode 1: Review Grid & Word Bank Mode
                if (masteryState.isReviewMode &&
                    masteryState.reviewGameState != null) {
                  return _buildReviewPracticeLayout(
                    context,
                    constraints,
                    isWide,
                    masteryState,
                    masteryNotifier,
                  );
                }

                // Mode 2: Flashcards & Vocabulary Deck Mode
                if (isWide) {
                  return _buildWideFlashcardLayout(
                    context,
                    constraints,
                    masteryState,
                    masteryNotifier,
                    filteredWords,
                    summary,
                    unmasteredCount,
                  );
                } else {
                  return _buildNarrowFlashcardLayout(
                    context,
                    constraints,
                    masteryState,
                    masteryNotifier,
                    filteredWords,
                    summary,
                    unmasteredCount,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mode 1: Responsive Review Grid & Word Bank Layout ────

  Widget _buildReviewPracticeLayout(
    BuildContext context,
    BoxConstraints constraints,
    bool isWide,
    MasteryState state,
    MasteryNotifier notifier,
  ) {
    final gameState = state.reviewGameState!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headerBanner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Targeted Practice: ${gameState.puzzle.words.length} Un-mastered Words',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            key: const Key('open_full_game_button'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.sports_esports_rounded, size: 18),
            label: const Text('Open in Game'),
            onPressed: () {
              _unfocusSoftKeyboard();
              _handleStartUnmasteredGame();
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('exit_practice_board_button'),
            icon: const Icon(Icons.close),
            tooltip: 'Exit Practice Mode',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              _unfocusSoftKeyboard();
              notifier.exitReviewPractice();
            },
          ),
        ],
      ),
    );

    // Responsive: Side-by-side on wide screens vs. stacked vertically on smartphones
    if (isWide) {
      return Column(
        children: [
          headerBanner,
          Expanded(
            child: Row(
              children: [
                // Grid area (left side)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Focus(
                      canRequestFocus: false,
                      child: BoardWidget(
                        gameState: gameState,
                        onCellTap: (_) => _unfocusSoftKeyboard(),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Word Bank list (right side)
                Expanded(
                  flex: 2,
                  child: _buildReviewWordBank(context, gameState, isHorizontal: false),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Narrow screen: Stacked vertically
      return Column(
        children: [
          headerBanner,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Focus(
                canRequestFocus: false,
                child: BoardWidget(
                  gameState: gameState,
                  onCellTap: (_) => _unfocusSoftKeyboard(),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Word Bank underneath on smartphones
          SizedBox(
            height: 180,
            child: _buildReviewWordBank(context, gameState, isHorizontal: true),
          ),
        ],
      );
    }
  }

  Widget _buildReviewWordBank(
    BuildContext context,
    dynamic gameState, {
    required bool isHorizontal,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final words = gameState.puzzle.words as List<WordEntry>;

    if (isHorizontal) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: words.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = words[index];
          final word = entry.word;
          final clue = entry.clue ?? '';

          return Focus(
            canRequestFocus: false,
            child: Semantics(
              label: 'Un-mastered word: $word. Clue: $clue',
              child: Card(
                key: Key('review_word_card_$index'),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final entry = words[index];
        final word = entry.word;
        final clue = entry.clue ?? '';

        return Focus(
          canRequestFocus: false,
          child: Semantics(
            label: 'Un-mastered word $word. Clue: $clue',
            child: Card(
              key: Key('review_word_card_$index'),
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  word,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  clue,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Mode 2: Wide Desktop/Tablet Flashcard Layout ─────────

  Widget _buildWideFlashcardLayout(
    BuildContext context,
    BoxConstraints constraints,
    MasteryState state,
    MasteryNotifier notifier,
    List<WordMasteryRecord> filteredWords,
    dynamic summary,
    int unmasteredCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Summary Metrics & Flashcard Deck
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryAndActionHeader(
                  context,
                  summary,
                  unmasteredCount,
                  notifier,
                  isWide: true,
                ),
                const SizedBox(height: 20),
                _buildFlashcardSection(
                  context,
                  state,
                  notifier,
                  filteredWords,
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Column: Filter Chips & Vocabulary Deck Table
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(context, notifier),
                const SizedBox(height: 12),
                _buildFilterChips(context, state, notifier),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildVocabularyList(
                    context,
                    filteredWords,
                    state,
                    notifier,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mode 2: Narrow Mobile Flashcard Layout ───────────────

  Widget _buildNarrowFlashcardLayout(
    BuildContext context,
    BoxConstraints constraints,
    MasteryState state,
    MasteryNotifier notifier,
    List<WordMasteryRecord> filteredWords,
    dynamic summary,
    int unmasteredCount,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Deck Summary Card & Primary Un-mastered Action
          _buildSummaryAndActionHeader(
            context,
            summary,
            unmasteredCount,
            notifier,
            isWide: false,
          ),
          const SizedBox(height: 20),

          // 2. Interactive Flashcard Area
          _buildFlashcardSection(
            context,
            state,
            notifier,
            filteredWords,
          ),
          const SizedBox(height: 24),

          // 3. Search and Filter Controls
          _buildSearchBar(context, notifier),
          const SizedBox(height: 10),
          _buildFilterChips(context, state, notifier),
          const SizedBox(height: 16),

          // 4. Vocabulary Bank List
          Text(
            'Vocabulary Bank (${filteredWords.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildVocabularyList(
            context,
            filteredWords,
            state,
            notifier,
            shrinkWrap: true,
          ),
        ],
      ),
    );
  }

  // ─── Summary & Un-mastered Action Header ───────────────────

  Widget _buildSummaryAndActionHeader(
    BuildContext context,
    dynamic summary,
    int unmasteredCount,
    MasteryNotifier notifier, {
    required bool isWide,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Focus(
      canRequestFocus: false,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.9),
              colorScheme.tertiaryContainer.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vocabulary Mastery Deck',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${summary.totalWords} Total Words • ${summary.masteryRate}% Mastered',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Spaced repetition indicators summary chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatPill(
                  context,
                  label: 'Needs Practice: ${summary.needsPractice}',
                  icon: Icons.flag_rounded,
                  color: Colors.red.shade700,
                  bgColor: Colors.red.shade50,
                ),
                _buildStatPill(
                  context,
                  label: 'Learning: ${summary.learning}',
                  icon: Icons.schedule_rounded,
                  color: Colors.orange.shade800,
                  bgColor: Colors.orange.shade50,
                ),
                _buildStatPill(
                  context,
                  label: 'Mastered: ${summary.mastered}',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Option to start a word search puzzle using ONLY un-mastered words
            Semantics(
              label:
                  'Start word search puzzle using only un-mastered words from vocabulary deck ($unmasteredCount words available)',
              button: true,
              child: FilledButton.icon(
                key: const Key('start_unmastered_puzzle_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: colorScheme.primary,
                ),
                onPressed: _handleStartUnmasteredGame,
                icon: const Icon(Icons.extension_rounded),
                label: Text(
                  'Practice $unmasteredCount Un-mastered Words in Puzzle',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Flashcard Section ─────────────────────────────────────

  Widget _buildFlashcardSection(
    BuildContext context,
    MasteryState state,
    MasteryNotifier notifier,
    List<WordMasteryRecord> filteredWords,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (filteredWords.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'No Flashcards Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try clearing your search query or switching mastery filters.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = state.currentCardIndex.clamp(0, filteredWords.length - 1);
    final record = filteredWords[safeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation controls & counter header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Flashcard ${safeIndex + 1} of ${filteredWords.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Semantics(
                  label: 'Previous vocabulary card',
                  button: true,
                  child: IconButton(
                    key: const Key('prev_flashcard_button'),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    tooltip: 'Previous Card',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () {
                      _unfocusSoftKeyboard();
                      notifier.previousCard(filteredWords.length);
                    },
                  ),
                ),
                Semantics(
                  label: 'Flip flashcard between word and definition',
                  button: true,
                  child: IconButton(
                    key: const Key('flip_flashcard_button'),
                    icon: const Icon(Icons.flip_rounded, size: 20),
                    tooltip: 'Flip Card',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () {
                      _unfocusSoftKeyboard();
                      notifier.flipCard();
                    },
                  ),
                ),
                Semantics(
                  label: 'Next vocabulary card',
                  button: true,
                  child: IconButton(
                    key: const Key('next_flashcard_button'),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    tooltip: 'Next Card',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () {
                      _unfocusSoftKeyboard();
                      notifier.nextCard(filteredWords.length);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Interactive Flashcard Body
        Focus(
          canRequestFocus: false,
          child: Semantics(
            container: true,
            label: state.isCardFlipped
                ? 'Back of flashcard for ${record.word}. Definition: ${record.clue ?? "No clue provided"}. Mastery level: ${record.masteryLevel.name}. Average solve time: ${record.averageSolveTime.toStringAsFixed(1)} seconds. Tap to flip.'
                : 'Front of flashcard for ${record.word}. Reading: ${record.reading ?? "Not provided"}. Mastery level: ${record.masteryLevel.name}. Double tap to flip to definition.',
            button: true,
            child: InkWell(
              key: const Key('flashcard_card'),
              onTap: () {
                _unfocusSoftKeyboard();
                notifier.flipCard();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(minHeight: 220),
                decoration: BoxDecoration(
                  color: state.isCardFlipped
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getMasteryColor(record.masteryLevel).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: state.isCardFlipped
                    ? _buildFlashcardBack(context, record)
                    : _buildFlashcardFront(context, record),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Spaced repetition review rating controls
        _buildSpacedRepetitionRatingBar(context, record, notifier),
      ],
    );
  }

  Widget _buildFlashcardFront(BuildContext context, WordMasteryRecord record) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                record.language.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            _buildMasteryBadge(record.masteryLevel),
          ],
        ),
        const SizedBox(height: 24),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            record.word,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (record.reading != null && record.reading!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            record.reading!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded,
                size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Tap to flip for definition & spaced-repetition metrics',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlashcardBack(BuildContext context, WordMasteryRecord record) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxHint = record.hintTiersHistory.isNotEmpty
        ? record.hintTiersHistory.reduce(max)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              record.word,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            _buildMasteryBadge(record.masteryLevel),
          ],
        ),
        const Divider(height: 20),
        Text(
          'Definition / Clue',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          record.clue ?? 'No definition or clue available.',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),

        // Spaced-repetition metrics indicators
        Text(
          'Spaced Repetition Performance',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildMetricItem(
              icon: Icons.speed_rounded,
              label: 'Solve Velocity',
              value: record.timesSolved > 0
                  ? '${record.averageSolveTime.toStringAsFixed(1)}s avg'
                  : 'Unsolved',
            ),
            _buildMetricItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'Solves',
              value: '${record.timesSolved} / ${record.timesEncountered}',
            ),
            _buildMetricItem(
              icon: Icons.mouse_rounded,
              label: 'Error Clicks',
              value: '${record.errorClicks}',
            ),
            _buildMetricItem(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Max Hint Tier',
              value: 'Tier $maxHint',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Spaced Repetition Rating Controls ────────────────────

  Widget _buildSpacedRepetitionRatingBar(
    BuildContext context,
    WordMasteryRecord record,
    MasteryNotifier notifier,
  ) {
    return Focus(
      canRequestFocus: false,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Rate ${record.word} as Needs Practice',
              button: true,
              child: OutlinedButton.icon(
                key: const Key('rate_needs_practice_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                onPressed: () {
                  _unfocusSoftKeyboard();
                  notifier.updateWordMastery(
                    word: record.word,
                    language: record.language,
                    newLevel: MasteryLevel.needsPractice,
                  );
                },
                icon: const Icon(Icons.flag_rounded, size: 16),
                label: const Text('Needs Practice'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Rate ${record.word} as Learning',
              button: true,
              child: OutlinedButton.icon(
                key: const Key('rate_learning_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                onPressed: () {
                  _unfocusSoftKeyboard();
                  notifier.updateWordMastery(
                    word: record.word,
                    language: record.language,
                    newLevel: MasteryLevel.learning,
                  );
                },
                icon: const Icon(Icons.schedule_rounded, size: 16),
                label: const Text('Learning'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Rate ${record.word} as Mastered',
              button: true,
              child: FilledButton.icon(
                key: const Key('rate_mastered_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: Colors.green.shade700,
                ),
                onPressed: () {
                  _unfocusSoftKeyboard();
                  notifier.updateWordMastery(
                    word: record.word,
                    language: record.language,
                    newLevel: MasteryLevel.mastered,
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Mastered'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search & Filters ──────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, MasteryNotifier notifier) {
    return TextField(
      key: const Key('vocabulary_search_field'),
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search vocabulary word, clue, or reading...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  _searchController.clear();
                  notifier.setSearchQuery('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: notifier.setSearchQuery,
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    MasteryState state,
    MasteryNotifier notifier,
  ) {
    return Focus(
      canRequestFocus: false,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: MasteryFilter.values.map((filter) {
            final isSelected = state.selectedFilter == filter;
            final keyName = 'mastery_filter_${filter.name.replaceAll(RegExp(r'(?=[A-Z])'), '_').toLowerCase()}';

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                key: Key(keyName),
                selected: isSelected,
                label: Text(filter.label),
                onSelected: (_) {
                  _unfocusSoftKeyboard();
                  notifier.setFilter(filter);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Vocabulary Deck List ──────────────────────────────────

  Widget _buildVocabularyList(
    BuildContext context,
    List<WordMasteryRecord> words,
    MasteryState state,
    MasteryNotifier notifier, {
    bool shrinkWrap = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No matching vocabulary entries found.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: words.length,
      itemBuilder: (context, index) {
        final record = words[index];
        final isCurrentCard = state.currentCardIndex == index;

        return Focus(
          canRequestFocus: false,
          child: Semantics(
            label:
                'Vocabulary entry ${record.word}, status ${record.masteryLevel.name}, solved ${record.timesSolved} of ${record.timesEncountered} times',
            child: Card(
              key: Key('vocab_word_card_$index'),
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isCurrentCard ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isCurrentCard
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: isCurrentCard ? 2 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: () {
                  _unfocusSoftKeyboard();
                  notifier.jumpToCard(index);
                },
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getMasteryColor(record.masteryLevel)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    _getMasteryIcon(record.masteryLevel),
                    size: 16,
                    color: _getMasteryColor(record.masteryLevel),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        record.word,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (record.reading != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          record.reading!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  record.clue ?? 'No definition',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  record.timesSolved > 0
                      ? '${record.averageSolveTime.toStringAsFixed(1)}s'
                      : '-',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  Color _getMasteryColor(MasteryLevel level) => switch (level) {
        MasteryLevel.mastered => Colors.green.shade700,
        MasteryLevel.learning => Colors.orange.shade800,
        MasteryLevel.needsPractice => Colors.red.shade700,
        MasteryLevel.unseen => Colors.grey.shade600,
      };

  IconData _getMasteryIcon(MasteryLevel level) => switch (level) {
        MasteryLevel.mastered => Icons.check_circle_rounded,
        MasteryLevel.learning => Icons.schedule_rounded,
        MasteryLevel.needsPractice => Icons.flag_rounded,
        MasteryLevel.unseen => Icons.help_outline_rounded,
      };

  Widget _buildMasteryBadge(MasteryLevel level) {
    final color = _getMasteryColor(level);
    final icon = _getMasteryIcon(level);
    final text = switch (level) {
      MasteryLevel.mastered => 'Mastered',
      MasteryLevel.learning => 'Learning',
      MasteryLevel.needsPractice => 'Needs Practice',
      MasteryLevel.unseen => 'Unseen',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
