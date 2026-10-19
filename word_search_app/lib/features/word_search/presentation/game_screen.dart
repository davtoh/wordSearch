import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../learning/application/learning_provider.dart';
import '../application/game_provider.dart';
import '../domain/game_state.dart';
import 'widgets/board_widget.dart';
import 'widgets/victory_dialog.dart';

/// Main responsive Game Screen supporting both Mobile (vertical stack + NavigationBar)
/// and Tablet/Desktop (side-by-side + NavigationRail) layouts.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  String _formatTime(double seconds) {
    final totalSecs = seconds.floor().clamp(0, 99999);
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    // Trigger Victory Modal Sheet when game becomes completed
    ref.listen<GameState>(gameProvider, (previous, next) {
      final wasCompleted = previous?.isCompleted ?? false;
      if (!wasCompleted && next.isCompleted) {
        showVictoryModalSheet(
          context: context,
          gameState: next,
          onPlayAgain: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            ref.read(gameProvider.notifier).resetGame();
          },
          onReturnToMainMenu: () {
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
          },
          onAddToLearnDeck: () {
            ref.read(playerProfileProvider.notifier).addWordsToLearnDeck(
                  words: next.foundWords.isNotEmpty
                      ? next.foundWords
                      : next.puzzle.words,
                  solveTimeSeconds: next.totalElapsedSeconds,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Words added to Learn Deck!'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      }
    });

    final theme = Theme.of(context);

    // Unfocus soft keyboard whenever tapping outside input fields
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('game_back_to_menu_button'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Main Menu',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
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
            },
          ),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Word Search App'),
          ),
          centerTitle: false,
          actions: [
            // Mode Switcher / Indicator
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Chip(
                    avatar: Icon(
                      gameState.mode == GameMode.timedAttack
                          ? Icons.timer
                          : Icons.spa,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      gameState.mode == GameMode.timedAttack
                          ? 'Timed: ${_formatTime(gameState.timeRemaining)}'
                          : 'Casual: ${_formatTime(gameState.totalElapsedSeconds)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(
                gameState.status == GameStatus.paused
                    ? Icons.play_arrow
                    : Icons.pause,
              ),
              tooltip: gameState.status == GameStatus.paused
                  ? 'Resume Game'
                  : 'Pause Game',
              onPressed: () => gameNotifier.togglePause(),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (isWide) {
                return _buildWideLayout(context, ref, gameState, gameNotifier);
              } else {
                return _buildNarrowLayout(context, ref, gameState, gameNotifier);
              }
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width < 720
            ? _buildBottomBar(context, ref, gameState, gameNotifier)
            : null,
      ),
    );
  }

  // ─── Narrow Mobile Layout ────────────────────────────────

  Widget _buildNarrowLayout(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    GameNotifier notifier,
  ) {
    return Column(
      children: [
        // Top HUD indicators (Progress and status)
        _buildHudBar(context, state),

        // Radar or Stall Notification Pill
        if (state.stallAlert != null || state.proximityFeedback != null)
          _buildAlertPill(context, state),

        // Board Center Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: BoardWidget(
              gameState: state,
              onCellDragStart: notifier.startSelection,
              onCellDragUpdate: notifier.updateSelection,
              onCellDragEnd: notifier.confirmSelection,
              onCellTap: notifier.checkProximity,
            ),
          ),
        ),

        // Word Bank Bottom Drawer
        _buildWordBank(context, state, notifier, isHorizontal: true),
      ],
    );
  }

  // ─── Wide Desktop / Tablet Layout ────────────────────────

  Widget _buildWideLayout(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    GameNotifier notifier,
  ) {
    return Row(
      children: [
        // Side Navigation Rail for quick game controls
        NavigationRail(
          selectedIndex: state.status == GameStatus.paused ? 1 : 0,
          labelType: NavigationRailLabelType.all,
          destinations: [
            NavigationRailDestination(
              icon: Icon(
                state.status == GameStatus.paused
                    ? Icons.play_arrow
                    : Icons.sports_esports,
              ),
              label: Text(
                state.status == GameStatus.paused ? 'Resume' : 'Play',
              ),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.lightbulb_outline),
              label: Text('Hint'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.flag_outlined),
              label: Text('Give Up'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.refresh),
              label: Text('Reset'),
            ),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                notifier.togglePause();
              case 1:
                _handleRequestHint(context, notifier);
              case 2:
                _confirmGiveUp(context, notifier);
              case 3:
                notifier.resetGame();
            }
          },
        ),

        const VerticalDivider(width: 1),

        // Central Board Grid Area
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildHudBar(context, state),
              if (state.stallAlert != null || state.proximityFeedback != null)
                _buildAlertPill(context, state),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BoardWidget(
                    gameState: state,
                    onCellDragStart: notifier.startSelection,
                    onCellDragUpdate: notifier.updateSelection,
                    onCellDragEnd: notifier.confirmSelection,
                    onCellTap: notifier.checkProximity,
                  ),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Sidebar: Word Bank list & definitions
        Expanded(
          flex: 2,
          child: _buildWordBank(context, state, notifier, isHorizontal: false),
        ),
      ],
    );
  }

  // ─── HUD Indicators Bar ──────────────────────────────────

  Widget _buildHudBar(BuildContext context, GameState state) {
    final theme = Theme.of(context);
    final foundCount = state.foundWords.length;
    final totalCount = state.puzzle.words.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Semantics(
        container: true,
        label: 'Game HUD: $foundCount of $totalCount words found, ${(state.progress * 100).toInt()}% completed',
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4.0,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Found: $foundCount / $totalCount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (state.status == GameStatus.won)
            InkWell(
              key: const Key('hud_victory_completed_button'),
              onTap: () => showVictoryModalSheet(
                context: context,
                gameState: state,
              ),
              child: const Text(
                '🎉 Completed!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (state.status == GameStatus.givenUp)
            const Text(
              '🏳️ Surrendered',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (state.status == GameStatus.timeOut)
            const Text(
              '⏰ Time Out!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${(state.progress * 100).toInt()}% Done',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      ),
    );
  }

  // ─── Alert / Radar Banner ────────────────────────────────

  Widget _buildAlertPill(BuildContext context, GameState state) {
    if (state.proximityFeedback != null) {
      final fb = state.proximityFeedback!;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Color(fb.colorValue).withValues(alpha: 0.20),
          border: Border.all(color: Color(fb.colorValue), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          fb.message,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(fb.colorValue),
          ),
        ),
      );
    }

    if (state.stallAlert != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.20),
          border: Border.all(color: Colors.amber, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          state.stallAlert!,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Word Bank Component ─────────────────────────────────

  Widget _buildWordBank(
    BuildContext context,
    GameState state,
    GameNotifier notifier, {
    required bool isHorizontal,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foundTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (isHorizontal) {
      final textScale = MediaQuery.textScalerOf(context).scale(1.0);
      final bankHeight = (80.0 * textScale).clamp(80.0, 160.0);

      return Semantics(
        container: true,
        label: 'Word Bank, ${state.puzzle.words.length} words to find',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            height: bankHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: state.puzzle.words.map((w) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Semantics(
                      button: true,
                      label:
                          'Word ${w.word}, ${w.found ? "already found" : "not found"}${w.clue != null ? ". Clue: ${w.clue}" : ""}',
                      child: FilterChip(
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            w.word,
                            style: TextStyle(
                              decoration:
                                  w.found ? TextDecoration.lineThrough : null,
                              color: w.found ? foundTextColor : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        selected: w.found,
                        onSelected: (_) => _handleRequestHint(
                          context,
                          notifier,
                          targetWord: w.word,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } else {
      // Vertical list on desktop/wide layout
      return Semantics(
        container: true,
        label: 'Word Bank, ${state.puzzle.words.length} words to find',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Word Bank (${state.puzzle.words.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: state.puzzle.words.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final w = state.puzzle.words[index];
                  return Semantics(
                    label:
                        'Word ${w.word}, ${w.found ? "already found" : "not found"}${w.clue != null ? ". Clue: ${w.clue}" : ""}',
                    child: ListTile(
                      minVerticalPadding: 14.0, // Ensures >= 48dp touch target
                      leading: Icon(
                        w.found
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: w.found ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        w.word,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration:
                              w.found ? TextDecoration.lineThrough : null,
                          color: w.found ? foundTextColor : null,
                        ),
                      ),
                      subtitle: w.clue != null ? Text(w.clue!) : null,
                      trailing: !w.found
                          ? IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.help_outline, size: 22),
                              tooltip: 'Get hint for ${w.word}',
                              onPressed: () => _handleRequestHint(
                                context,
                                notifier,
                                targetWord: w.word,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─── Mobile Bottom Navigation Bar ────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    GameNotifier notifier,
  ) {
    return NavigationBar(
      selectedIndex: 0,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outline),
          label: 'Hint',
        ),
        NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          label: 'Give Up',
        ),
        NavigationDestination(
          icon: Icon(Icons.refresh),
          label: 'Reset',
        ),
      ],
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            _handleRequestHint(context, notifier);
          case 1:
            _confirmGiveUp(context, notifier);
          case 2:
            notifier.resetGame();
        }
      },
    );
  }

  // ─── Dialogs & Actions ───────────────────────────────────

  void _handleRequestHint(
    BuildContext context,
    GameNotifier notifier, {
    String? targetWord,
  }) {
    final result = notifier.requestHint(targetWord: targetWord);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmGiveUp(BuildContext context, GameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Give Up?'),
        content: const Text(
          'Are you sure you want to surrender? All remaining words will be revealed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.giveUp();
            },
            child: const Text('Reveal Words'),
          ),
        ],
      ),
    );
  }
}
