import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/game_state.dart';

/// Interactive Word Search Grid Board rendered with a high-performance [CustomPainter].
class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.gameState,
    this.onCellDragStart,
    this.onCellDragUpdate,
    this.onCellDragEnd,
    this.onCellTap,
  });

  final GameState gameState;
  final ValueChanged<(int, int)>? onCellDragStart;
  final ValueChanged<(int, int)>? onCellDragUpdate;
  final VoidCallback? onCellDragEnd;
  final ValueChanged<(int, int)>? onCellTap;

  (int, int)? _getCellAtPosition(Offset localPosition, Size size) {
    final rows = gameState.puzzle.rows;
    final cols = gameState.puzzle.cols;
    if (rows <= 0 || cols <= 0) return null;

    final padding = 8.0;
    final availW = size.width - 2 * padding;
    final availH = size.height - 2 * padding;

    final cellSize = min(availW / cols, availH / rows);
    final gridW = cellSize * cols;
    final gridH = cellSize * rows;

    final originX = (size.width - gridW) / 2;
    final originY = (size.height - gridH) / 2;

    final relX = localPosition.dx - originX;
    final relY = localPosition.dy - originY;

    if (relX < 0 || relY < 0 || relX >= gridW || relY >= gridH) {
      return null;
    }

    final c = (relX / cellSize).floor().clamp(0, cols - 1);
    final r = (relY / cellSize).floor().clamp(0, rows - 1);

    return (r, c);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availSide = min(constraints.maxWidth, constraints.maxHeight);
        final size = Size(availSide, availSide);

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              FocusScope.of(context).unfocus();
              final cell = _getCellAtPosition(details.localPosition, size);
              if (cell != null) {
                onCellDragStart?.call(cell);
              }
            },
            onPanUpdate: (details) {
              final cell = _getCellAtPosition(details.localPosition, size);
              if (cell != null) {
                onCellDragUpdate?.call(cell);
              }
            },
            onPanEnd: (_) => onCellDragEnd?.call(),
            onTapDown: (details) {
              FocusScope.of(context).unfocus();
              final cell = _getCellAtPosition(details.localPosition, size);
              if (cell != null) {
                onCellTap?.call(cell);
              }
            },
            child: CustomPaint(
              size: size,
              painter: _BoardPainter(
                gameState: gameState,
                isDark: isDark,
                colorScheme: theme.colorScheme,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.gameState,
    required this.isDark,
    required this.colorScheme,
  });

  final GameState gameState;
  final bool isDark;
  final ColorScheme colorScheme;

  // Palette of vibrant colors for discovered word highlights
  static const List<Color> _wordColors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF0EA5E9), // Sky
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final puzzle = gameState.puzzle;
    final rows = puzzle.rows;
    final cols = puzzle.cols;
    if (rows <= 0 || cols <= 0) return;

    const padding = 8.0;
    final availW = size.width - 2 * padding;
    final availH = size.height - 2 * padding;

    final cellSize = min(availW / cols, availH / rows);
    final gridW = cellSize * cols;
    final gridH = cellSize * rows;

    final originX = (size.width - gridW) / 2;
    final originY = (size.height - gridH) / 2;

    // 1. Board Background Card
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(originX - 4, originY - 4, gridW + 8, gridH + 8),
      const Radius.circular(16),
    );

    final cardBgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(boardRect, cardBgPaint);

    final cardBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(boardRect, cardBorderPaint);

    // 2. Cell background grid
    final cellBgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cellRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            originX + c * cellSize + 1.5,
            originY + r * cellSize + 1.5,
            cellSize - 3.0,
            cellSize - 3.0,
          ),
          Radius.circular(max(4.0, cellSize * 0.15)),
        );
        canvas.drawRRect(cellRRect, cellBgPaint);
      }
    }

    // 3. Draw found words highlights
    for (int i = 0; i < gameState.foundWords.length; i++) {
      final word = gameState.foundWords[i];
      final color = _wordColors[i % _wordColors.length];

      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final (r, c) in word.coords) {
        final cellRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            originX + c * cellSize + 1.5,
            originY + r * cellSize + 1.5,
            cellSize - 3.0,
            cellSize - 3.0,
          ),
          Radius.circular(max(4.0, cellSize * 0.15)),
        );
        canvas.drawRRect(cellRRect, fillPaint);
        canvas.drawRRect(cellRRect, borderPaint);
      }
    }

    // 4. Draw revealed coordinates on surrender / give-up
    if (gameState.revealedAllOnGiveUp) {
      final giveUpFillPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final giveUpBorderPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (final (r, c) in gameState.foundCoordsMap.keys) {
        final cellRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            originX + c * cellSize + 1.5,
            originY + r * cellSize + 1.5,
            cellSize - 3.0,
            cellSize - 3.0,
          ),
          Radius.circular(max(4.0, cellSize * 0.15)),
        );
        canvas.drawRRect(cellRRect, giveUpFillPaint);
        canvas.drawRRect(cellRRect, giveUpBorderPaint);
      }
    }

    // 5. Draw active hint highlights (gold glow)
    if (gameState.activeHintCoords.isNotEmpty) {
      final hintFillPaint = Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.40)
        ..style = PaintingStyle.fill;

      final hintBorderPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      for (final (r, c) in gameState.activeHintCoords) {
        final cellRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            originX + c * cellSize + 1.5,
            originY + r * cellSize + 1.5,
            cellSize - 3.0,
            cellSize - 3.0,
          ),
          Radius.circular(max(4.0, cellSize * 0.15)),
        );
        canvas.drawRRect(cellRRect, hintFillPaint);
        canvas.drawRRect(cellRRect, hintBorderPaint);
      }
    }

    // 6. Draw active drag selection line
    if (gameState.selectedCoords.isNotEmpty) {
      final selectFillPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;

      final selectBorderPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      for (final (r, c) in gameState.selectedCoords) {
        final cellRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            originX + c * cellSize + 1.5,
            originY + r * cellSize + 1.5,
            cellSize - 3.0,
            cellSize - 3.0,
          ),
          Radius.circular(max(4.0, cellSize * 0.15)),
        );
        canvas.drawRRect(cellRRect, selectFillPaint);
        canvas.drawRRect(cellRRect, selectBorderPaint);
      }
    }

    // 7. Draw letters in centers of cells
    final fontSize = max(13.0, cellSize * 0.50);
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
    );

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final char = puzzle.grid[r][c];
        if (char.isEmpty) continue;

        final textSpan = TextSpan(text: char, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final charX = originX + c * cellSize + (cellSize - textPainter.width) / 2;
        final charY = originY + r * cellSize + (cellSize - textPainter.height) / 2;

        textPainter.paint(canvas, Offset(charX, charY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.gameState != gameState ||
        oldDelegate.isDark != isDark ||
        oldDelegate.colorScheme != colorScheme;
  }
}
