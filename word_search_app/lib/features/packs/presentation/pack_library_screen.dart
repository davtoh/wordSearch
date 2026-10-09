import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/models/models.dart';
import '../../word_search/application/game_provider.dart';
import '../data/pack_repository.dart';

/// Screen presenting the Pack Library, built-in multilingual script pools,
/// and JSON import/export utilities for offline word search packs.
class PackLibraryScreen extends ConsumerStatefulWidget {
  const PackLibraryScreen({
    super.key,
    this.customFilePicker,
  });

  /// Optional hook for injecting test file pickers in widget tests.
  final Future<String?> Function()? customFilePicker;

  @override
  ConsumerState<PackLibraryScreen> createState() => _PackLibraryScreenState();
}

class _PackLibraryScreenState extends ConsumerState<PackLibraryScreen> {
  bool _isImporting = false;

  Future<void> _handleImportJson() async {
    setState(() => _isImporting = true);
    try {
      String? jsonContent;
      String? fileName;

      if (widget.customFilePicker != null) {
        jsonContent = await widget.customFilePicker!();
        fileName = 'imported_pack.json';
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],

        );

        if (result.isNotEmpty) {
          final file = result.first;
          fileName = file.name;
          if (file.path != null) {
            jsonContent = await File(file.path!).readAsString();
          }
        }
      }

      if (jsonContent != null && mounted) {
        final importedPack = ref
            .read(packListProvider.notifier)
            .importFromJson(jsonContent, filePath: fileName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Successfully imported pack "${importedPack.title}" (${importedPack.puzzleCount} puzzles)!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Import Failed'),
              ],
            ),
            content: Text(
              'Could not parse the selected pack JSON. Please ensure it adheres to the standard puzzle pack schema.\n\nDetails: $e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showExportDialog({
    required String title,
    required String jsonString,
    String? subtitle,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.file_download_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            key: const Key('copy_json_button'),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('JSON copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportActivePuzzle() {
    final activePuzzle = ref.read(gameProvider).puzzle;
    final repo = ref.read(packRepositoryProvider);
    final jsonStr = repo.exportPuzzleToJson(activePuzzle);

    _showExportDialog(
      title: 'Export Active Puzzle',
      subtitle:
          'Standard JSON representation of "${activePuzzle.metadata.title}" (${activePuzzle.rows}x${activePuzzle.cols}, ${activePuzzle.totalWords} words).',
      jsonString: jsonStr,
    );
  }

  void _exportPack(PuzzlePack pack) {
    final repo = ref.read(packRepositoryProvider);
    final jsonStr = repo.exportPackToJson(pack);

    _showExportDialog(
      title: 'Export Pack: ${pack.title}',
      subtitle: 'Complete schema containing ${pack.puzzleCount} puzzle definition(s).',
      jsonString: jsonStr,
    );
  }

  void _playPuzzle(Puzzle puzzle) {
    ref.read(gameProvider.notifier).initGame(puzzle);
    context.go(AppRoutes.game);
  }

  void _playScriptSample(ScriptPoolInfo pool) {
    final puzzle = pool.generateSamplePuzzle();
    _playPuzzle(puzzle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final packs = ref.watch(packListProvider);
    final repo = ref.watch(packRepositoryProvider);
    final scriptPools = repo.getBuiltInScriptPools();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('pack_library_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Menu',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.menu);
            }
          },
        ),
        title: const Text('Pack Library'),
        actions: [
          TextButton.icon(
            key: const Key('export_active_puzzle_button'),
            icon: const Icon(Icons.output_rounded, size: 20),
            label: const Text('Export Active'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
            onPressed: _exportActivePuzzle,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Import action banner
                      _buildHeroHeader(context, isWide),
                      const SizedBox(height: 28),

                      // Section 1: Built-in Script Pools (core/scripts.py Port)
                      Row(
                        children: [
                          Icon(Icons.translate_rounded,
                              color: colorScheme.primary, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Multilingual Script Pools',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Built-in character pools and diacritics ported from the core Unicode engine.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grid / Reflow for Script Pools
                      _buildScriptPoolsGrid(context, scriptPools, constraints.maxWidth),

                      const SizedBox(height: 36),

                      // Section 2: Curated & Imported Puzzle Packs
                      Row(
                        children: [
                          Icon(Icons.folder_special_rounded,
                              color: colorScheme.secondary, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Puzzle Packs & Collections',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${packs.length} Packs Loaded',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a collection to play or export its JSON structure.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Packs List / Grid
                      _buildPacksGrid(context, packs, constraints.maxWidth),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 28.0 : 20.0,
        vertical: 20.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.8),
            colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
                  Icons.auto_stories_rounded,
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
                      'Word Search Library',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Explore diverse world scripts or import community JSON packs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('import_pack_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _isImporting ? null : _handleImportJson,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_upload_rounded),
                label: const Text('Import JSON Pack'),
              ),
              OutlinedButton.icon(
                key: const Key('export_active_hero_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.6),
                ),
                onPressed: _exportActivePuzzle,
                icon: const Icon(Icons.data_object_rounded),
                label: const Text('Export Current Puzzle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScriptPoolsGrid(
    BuildContext context,
    List<ScriptPoolInfo> scriptPools,
    double maxWidth,
  ) {
    final double cardWidth;
    if (maxWidth < 640) {
      cardWidth = maxWidth - 32;
    } else if (maxWidth < 1000) {
      cardWidth = (maxWidth - 48) / 2;
    } else {
      cardWidth = (maxWidth - 64) / 3;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: scriptPools.map((pool) {
        return SizedBox(
          width: cardWidth,
          child: _ScriptPoolCard(
            pool: pool,
            onPlay: () => _playScriptSample(pool),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPacksGrid(
    BuildContext context,
    List<PuzzlePack> packs,
    double maxWidth,
  ) {
    if (packs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No packs currently loaded',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final double cardWidth;
    if (maxWidth < 640) {
      cardWidth = maxWidth - 32;
    } else if (maxWidth < 1000) {
      cardWidth = (maxWidth - 48) / 2;
    } else {
      cardWidth = (maxWidth - 64) / 3;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: packs.map((pack) {
        return SizedBox(
          width: cardWidth,
          child: _PuzzlePackCard(
            pack: pack,
            onPlay: () {
              if (pack.puzzleCount > 0) {
                _playPuzzle(pack.getPuzzle(0));
              }
            },
            onExport: () => _exportPack(pack),
            onDelete: pack.filePath != null
                ? () {
                    ref.read(packListProvider.notifier).removePack(pack.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed pack "${pack.title}"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// UI Cards: Script Pool Card
// ─────────────────────────────────────────────────────────

class _ScriptPoolCard extends StatelessWidget {
  const _ScriptPoolCard({
    required this.pool,
    required this.onPlay,
  });

  final ScriptPoolInfo pool;
  final VoidCallback onPlay;

  Color _accentColor(ScriptType script) => switch (script) {
        ScriptType.latinAccented => const Color(0xFFF97316), // Orange
        ScriptType.hiragana => const Color(0xFFEC4899), // Pink
        ScriptType.katakana => const Color(0xFF8B5CF6), // Purple
        ScriptType.kanji => const Color(0xFF10B981), // Emerald
        ScriptType.cyrillic => const Color(0xFF3B82F6), // Blue
        _ => const Color(0xFF64748B),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(pool.scriptType);

    return Material(
      color: colorScheme.surface,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Script Badge & Character Count
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pool.nativeName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pool.characterCount} Chars',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Script Name
            Text(
              pool.name,
              key: Key('script_title_${pool.scriptType.name}'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              pool.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Preview glyphs display strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pool.previewGlyphs,
                style: theme.textTheme.bodyMedium?.copyWith(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),

            // Action Button: Play Sample Script Puzzle
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: Key('play_script_${pool.scriptType.name}'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text('Play ${pool.name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// UI Cards: Puzzle Pack Card
// ─────────────────────────────────────────────────────────

class _PuzzlePackCard extends StatelessWidget {
  const _PuzzlePackCard({
    required this.pack,
    required this.onPlay,
    required this.onExport,
    this.onDelete,
  });

  final PuzzlePack pack;
  final VoidCallback onPlay;
  final VoidCallback onExport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pack.language.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pack.scriptType.value,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${pack.puzzleCount} Puzzles',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pack Title
            Text(
              pack.title,
              key: Key('pack_title_${pack.id}'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Pack Description
            Text(
              pack.description.isNotEmpty
                  ? pack.description
                  : 'Ready-to-play word search puzzle package.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: Key('play_pack_${pack.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Play'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  key: Key('export_pack_${pack.id}'),
                  icon: const Icon(Icons.file_download_rounded, size: 20),
                  tooltip: 'Export JSON',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: onExport,
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    key: Key('delete_pack_${pack.id}'),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.redAccent),
                    tooltip: 'Remove Imported Pack',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
