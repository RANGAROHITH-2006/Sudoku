import 'dart:math';
import '../models/cell.dart';

class SudokuGenerator {
  static final Random _random = Random();

  /// Generate a complete valid Sudoku board
  static List<List<int>> generateCompleteBoard() {
    List<List<int>> board = List.generate(
      9,
      (_) => List.filled(9, 0),
    );

    _fillBoard(board);
    return board;
  }

  /// Fill the board using backtracking
  static bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);

          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;

              if (_fillBoard(board)) {
                return true;
              }

              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Check if placing a number is valid
  static bool _isValid(List<List<int>> board, int row, int col, int num) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (board[row][x] == num) return false;
    }

    // Check column
    for (int x = 0; x < 9; x++) {
      if (board[x][col] == num) return false;
    }

    // Check 3x3 box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[boxRow + i][boxCol + j] == num) return false;
      }
    }

    return true;
  }

  /// Remove cells from a complete board to create a puzzle
  /// Ensures each 3x3 box has at least 2 empty cells
  static List<List<Cell>> createPuzzle(int cellsToRemove) {
    List<List<int>> completeBoard = generateCompleteBoard();
    List<List<int>> puzzleBoard = List.generate(
      9,
      (i) => List.generate(9, (j) => completeBoard[i][j]),
    );

    // Track empty cells per box
    Map<String, int> boxEmptyCells = {};
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        boxEmptyCells['${br}_$bc'] = 0;
      }
    }

    int removed = 0;
    int maxAttempts = cellsToRemove * 10; // Prevent infinite loop
    int attempts = 0;

    while (removed < cellsToRemove && attempts < maxAttempts) {
      attempts++;
      int row = _random.nextInt(9);
      int col = _random.nextInt(9);

      if (puzzleBoard[row][col] != 0) {
        int boxRow = row ~/ 3;
        int boxCol = col ~/ 3;
        String boxKey = '${boxRow}_$boxCol';

        // Check if this box would have too many filled cells (less than 2 empty)
        // Only enforce minimum empty cells when we're close to the target
        if (removed >= cellsToRemove - 18) { // Last 18 cells (2 per box)
          int currentEmpty = boxEmptyCells[boxKey] ?? 0;
          
          // Don't remove if this box already has 7 empty cells (max we want)
          if (currentEmpty >= 7) {
            continue;
          }
          
          // Ensure we're leaving at least 2 empty per box
          int totalInBox = 9;
          int emptyInBox = currentEmpty;
          if (emptyInBox >= totalInBox - 2) {
            continue; // This box would have only 1 or 0 filled cells
          }
        }

        puzzleBoard[row][col] = 0;
        boxEmptyCells[boxKey] = (boxEmptyCells[boxKey] ?? 0) + 1;
        removed++;
      }
    }

    // Final validation: ensure each box has at least 2 empty cells
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        int emptyCount = 0;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            if (puzzleBoard[boxRow * 3 + i][boxCol * 3 + j] == 0) {
              emptyCount++;
            }
          }
        }

        // If box has less than 2 empty cells, remove more
        while (emptyCount < 2) {
          for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
              int r = boxRow * 3 + i;
              int c = boxCol * 3 + j;
              if (puzzleBoard[r][c] != 0 && emptyCount < 2) {
                puzzleBoard[r][c] = 0;
                emptyCount++;
              }
            }
          }
        }
      }
    }

    // Convert to Cell objects
    return List.generate(
      9,
      (row) => List.generate(
        9,
        (col) => Cell(
          row: row,
          col: col,
          value: puzzleBoard[row][col],
          isFixed: puzzleBoard[row][col] != 0,
        ),
      ),
    );
  }
}
