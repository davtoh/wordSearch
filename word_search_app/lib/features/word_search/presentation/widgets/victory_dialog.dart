import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../learning/application/learning_provider.dart';
import '../../application/game_provider.dart';
import '../../domain/game_state.dart';

/// Shows the [VictoryDialog] as a modal bottom sheet.
Future<T?> showVictoryModalSheet<T>({
  required BuildContext context,
  required GameState gameState,
  VoidCallback? onPlayAgain,
  VoidCallback? onReturnToMainMenu,
  VoidCallback? onAddToLearnDeck,
}) {
  return VictoryDialog.show<T>(
    context: context,
    gameState: gameState,
    onPlayAgain: onPlayAgain,
    onReturnToMainMenu: onReturnToMainMenu,
    onAddToLearnDeck: onAddToLearnDeck,
  );
}

/// Alias for [showVictoryModalSheet].
Future<T?> showVictoryDialog<T>({
  required BuildContext context,
  required GameState gameState,
  VoidCallback? onPlayAgain,
  VoidCallback? onReturnToMainMenu,
  VoidCallback? onAddToLearnDeck,
}) =>
    showVictoryModalSheet<T>(
      context: context,
      gameState: gameState,
      onPlayAgain: onPlayAgain,
      onReturnToMainMenu: onReturnToMainMenu,
      onAddToLearnDeck: onAddToLearnDeck,
    );

/// Victory Modal Sheet / Dialog shown when a puzzle session completes.
/// Displays elapsed time, words found count, and hint usage statistics,
/// along with quick actions to Play Again, Return to Main Menu, or Add Words to Learn Deck.
class VictoryDialog extends ConsumerStatefulWidget {
  const VictoryDialog({
    super.key,
    required this.gameState,
    this.onPlayAgain,
    this.onReturnToMainMenu,
    this.onAddToLearnDeck,
  });

  /// The active completed game state.
  final GameState gameState;

  /// Callback when "Play Again" is tapped. If null, resets the game and pops.
  final VoidCallback? onPlayAgain;

  /// Callback when "Return to Main Menu" is tapped. If null, pops and navigates to '/'.
  final VoidCallback? onReturnToMainMenu;

  /// Callback when "Add Words to Learn Deck" is tapped. If null, adds words to [playerProfileProvider].
  final VoidCallback? onAddToLearnDeck;

  /// Static entrypoint to present the victory sheet inside a modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required GameState gameState,
    VoidCallback? onPlayAgain,
    VoidCallback? onReturnToMainMenu,
    VoidCallback? onAddToLearnDeck,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VictoryDialog(
        gameState: gameState,
        onPlayAgain: onPlayAgain,
        onReturnToMainMenu: onReturnToMainMenu,
        onAddToLearnDeck: onAddToLearnDeck,
      ),
    );
  }

  @override
  ConsumerState<VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends ConsumerState<VictoryDialog> {
  bool _addedToDeck = false;

  String _formatTime(double seconds) {
    final totalSecs = seconds.floor().clamp(0, 99999);
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _handlePlayAgain() {
    if (widget.onPlayAgain != null) {
      widget.onPlayAgain!();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ref.read(gameProvider.notifier).resetGame();
    }
  }

  void _handleReturnToMainMenu() {
    if (widget.onReturnToMainMenu != null) {
      widget.onReturnToMainMenu!();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _handleAddToLearnDeck() {
    if (_addedToDeck) return;

    if (widget.onAddToLearnDeck != null) {
      widget.onAddToLearnDeck!();
    } else {
      final wordsToAdd = widget.gameState.foundWords.isNotEmpty
          ? widget.gameState.foundWords
          : widget.gameState.puzzle.words;

      ref.read(playerProfileProvider.notifier).addWordsToLearnDeck(
            words: wordsToAdd,
            solveTimeSeconds: widget.gameState.totalElapsedSeconds,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Words added to Learn Deck!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _addedToDeck = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final foundCount = widget.gameState.foundWords.length;
    final totalCount = widget.gameState.puzzle.words.length;
    final timeStr = _formatTime(widget.gameState.totalElapsedSeconds);
    final hintsCount = widget.gameState.hintsUsedCount;

    return Semantics(
      container: true,
      label:
          'Victory dialog. Puzzle completed in $timeStr with $foundCount of $totalCount words found and $hintsCount hints used.',
      child: Container(
        key: const Key('victory_modal_sheet'),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Celebration Badge & Title
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.tertiaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  'Puzzle Completed!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  widget.gameState.puzzle.title.isNotEmpty
                      ? '${widget.gameState.puzzle.title} • ${widget.gameState.puzzle.difficulty.humanReadable}'
                      : widget.gameState.puzzle.difficulty.humanReadable,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Dashboard Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        key: const Key('victory_time_elapsed_stat'),
                        icon: Icons.timer_outlined,
                        label: 'Time Elapsed',
                        value: timeStr,
                        semanticsLabel: 'Time elapsed: $timeStr',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        key: const Key('victory_words_found_stat'),
                        icon: Icons.check_circle_outline,
                        label: 'Words Found',
                        value: '$foundCount / $totalCount',
                        semanticsLabel: '$foundCount of $totalCount words found',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        key: const Key('victory_hints_used_stat'),
                        icon: Icons.lightbulb_outline,
                        label: 'Hint Usage',
                        value: hintsCount == 0 ? '0 (None)' : '$hintsCount used',
                        semanticsLabel: '$hintsCount hints used',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Found Words Preview (Chips)
                if (widget.gameState.puzzle.words.isNotEmpty) ...[
                  Text(
                    'Discovered Words (${widget.gameState.puzzle.words.length})',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: widget.gameState.puzzle.words.map((w) {
                      return Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          w.word,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                // 1. Play Again (Primary FilledButton)
                Focus(
                  canRequestFocus: false,
                  child: FilledButton.icon(
                    key: const Key('victory_play_again_button'),
                    onPressed: _handlePlayAgain,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Play Again'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Add Words to Learn Deck (Secondary Tonal Button)
                Focus(
                  canRequestFocus: false,
                  child: FilledButton.tonalIcon(
                    key: const Key('victory_add_to_learn_deck_button'),
                    onPressed: _handleAddToLearnDeck,
                    icon: Icon(
                      _addedToDeck
                          ? Icons.check_circle_rounded
                          : Icons.school_rounded,
                    ),
                    label: Text(
                      _addedToDeck ? 'Added to Learn Deck' : 'Add Words to Learn Deck',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Return to Main Menu (Outlined Button)
                Focus(
                  canRequestFocus: false,
                  child: OutlinedButton.icon(
                    key: const Key('victory_main_menu_button'),
                    onPressed: _handleReturnToMainMenu,
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Return to Main Menu'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    required String semanticsLabel,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      label: semanticsLabel,
      child: Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: colorScheme.primary),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
