import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/cell.dart';

class SudokuGrid extends StatefulWidget {
  const SudokuGrid({super.key});

  @override
  State<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends State<SudokuGrid> with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  String? _animatingLine;
  int _currentAnimatingCell = -1;
  List<Cell> _animatingCells = [];

  @override
  void initState() {
    super.initState();
    _sequenceController = AnimationController(
      duration: const Duration(milliseconds: 100), // Per cell animation
      vsync: this,
    );
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  void _triggerSequentialAnimation(String lineKey, GameController controller) async {
    if (_animatingLine == lineKey) return;
    
    setState(() {
      _animatingLine = lineKey;
      _animatingCells = controller.getCellsForLine(lineKey);
      _currentAnimatingCell = -1;
    });

    // Animate each cell sequentially
    for (int i = 0; i < _animatingCells.length; i++) {
      setState(() {
        _currentAnimatingCell = i;
      });
      await _sequenceController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Hold the color for 2-3 seconds
    await Future.delayed(const Duration(milliseconds: 2500));

    // Fade out
    if (mounted) {
      setState(() {
        _animatingLine = null;
        _currentAnimatingCell = -1;
        _animatingCells = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        // Check for new completions and trigger animation
        if (controller.lastCompletedLine != null && 
            controller.lastCompletedLine != _animatingLine) {
          final lineKey = controller.lastCompletedLine!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerSequentialAnimation(lineKey, controller);
            // Prevent the controller from re-emitting the same completion
            controller.clearLastCompletedLine();
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: Colors.grey[800]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double size = constraints.maxWidth;
                double cellSize = size / 9;

                return Stack(
                  children: [
                    // Draw cells
                    ...List.generate(9, (row) {
                      return List.generate(9, (col) {
                        Cell cell = controller.board[row][col];
                        int cellIndex = _getCellIndexInLine(cell);
                        bool isAnimating = cellIndex >= 0 && cellIndex <= _currentAnimatingCell;
                        
                        return Positioned(
                          left: col * cellSize,
                          top: row * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: _CellWidget(
                            cell: cell,
                            isAnimating: isAnimating,
                            onTap: () => controller.selectCell(row, col),
                          ),
                        );
                      });
                    }).expand((list) => list).toList(),
                    // Draw 3x3 grid lines
                    ..._buildThickGridLines(size),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _getCellIndexInLine(Cell cell) {
    if (_animatingLine == null || _animatingCells.isEmpty) return -1;
    
    for (int i = 0; i < _animatingCells.length; i++) {
      if (_animatingCells[i].row == cell.row && _animatingCells[i].col == cell.col) {
        return i;
      }
    }
    return -1;
  }

  List<Widget> _buildThickGridLines(double size) {
    List<Widget> lines = [];
    double cellSize = size / 9;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      lines.add(
        Positioned(
          left: i * cellSize * 3 - 1,
          top: 0,
          width: 2,
          height: size,
          child: Container(color: Colors.grey[800]),
        ),
      );
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      lines.add(
        Positioned(
          left: 0,
          top: i * cellSize * 3 - 1,
          width: size,
          height: 2,
          child: Container(color: Colors.grey[800]),
        ),
      );
    }

    return lines;
  }
}

class _CellWidget extends StatelessWidget {
  final Cell cell;
  final VoidCallback onTap;
  final bool isAnimating;

  const _CellWidget({
    required this.cell,
    required this.onTap,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context, listen: false);
    final shouldHighlight = controller.shouldHighlightCell(cell.row, cell.col);
    final cellIsWrong = controller.isCellWrong(cell.row, cell.col);
    
    Color backgroundColor;
    Color? borderColor;
    double borderWidth = 0.5;
    
    // Animation takes priority
    if (isAnimating) {
      backgroundColor = Colors.blue[700]!;
    } else if (cellIsWrong) {
      // RED BACKGROUND for errors (immediate visual feedback)
      backgroundColor = Colors.red[300]!;
      borderColor = Colors.red[600];
      borderWidth = 2.0;
    } else if (cell.isHighlighted) {
      // Selected cell
      backgroundColor = Colors.blue[400]!;
    } else if (shouldHighlight) {
      // Related cells (same row, col, box, or value)
      backgroundColor = Colors.blue[50]!;
    } else {
      backgroundColor = Colors.white;
    }

    // Text color
    Color textColor;
    if (cellIsWrong) {
      textColor = Colors.red[700]!; // Red text for errors too
    } else if (cell.isFixed) {
      textColor = Colors.grey[900]!;
    } else {
      textColor = Colors.blue[900]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor ?? Colors.grey[300]!,
            width: borderWidth,
          ),
          boxShadow: shouldHighlight ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Center(
          child: cell.value != 0
              ? Text(
                  cell.value.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: cell.isFixed ? FontWeight.bold : FontWeight.w600,
                    color: textColor,
                  ),
                )
              : cell.notes.isNotEmpty
                  ? _buildNotesGrid()
                  : null,
        ),
      ),
    );
  }

  Widget _buildNotesGrid() {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(2),
      children: List.generate(9, (index) {
        int num = index + 1;
        bool hasNote = cell.notes.contains(num);
        return Center(
          child: Text(
            hasNote ? num.toString() : '',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }),
    );
  }
}
