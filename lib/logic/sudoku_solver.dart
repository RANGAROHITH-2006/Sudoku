import '../models/cell.dart';

class SudokuSolver {
  /// Solve the Sudoku board
  static bool solve(List<List<Cell>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col].value == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isValid(board, row, col, num)) {
              board[row][col].value = num;

              if (solve(board)) {
                return true;
              }

              board[row][col].value = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Check if a number is valid at a given position
  static bool isValid(List<List<Cell>> board, int row, int col, int num) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (x != col && board[row][x].value == num) return false;
    }

    // Check column
    for (int x = 0; x < 9; x++) {
      if (x != row && board[x][col].value == num) return false;
    }

    // Check 3x3 box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int r = boxRow + i;
        int c = boxCol + j;
        if ((r != row || c != col) && board[r][c].value == num) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get the correct value for a cell
  static int? getCorrectValue(List<List<Cell>> board, int row, int col) {
    // Create a copy of the board
    List<List<Cell>> boardCopy = List.generate(
      9,
      (r) => List.generate(
        9,
        (c) => board[r][c].copyWith(),
      ),
    );

    // Solve the board
    if (solve(boardCopy)) {
      return boardCopy[row][col].value;
    }

    return null;
  }

  /// Check if the board is completely solved
  static bool isSolved(List<List<Cell>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col].value == 0) return false;
        if (!isValid(board, row, col, board[row][col].value)) return false;
      }
    }
    return true;
  }
}
