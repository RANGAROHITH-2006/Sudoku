import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../models/cell.dart';
import '../models/move.dart';
import '../models/difficulty.dart';
import '../logic/sudoku_generator.dart';
import '../logic/sudoku_solver.dart';

class GameController extends ChangeNotifier {
  List<List<Cell>> _board = [];
  List<Move> _moveHistory = [];
  int _mistakes = 0;
  int _seconds = 0;
  Timer? _timer;
  Difficulty _difficulty = Difficulty.easy;
  Cell? _selectedCell;
  bool _isGameOver = false;
  bool _isGameWon = false;
  bool _isPaused = false;
  bool _isNotesMode = false;
  int _hintsUsed = 0;
  final int _maxHints = 30;
  Set<String> _completedLines = {}; // Track completed rows/cols/boxes
  String? _lastCompletedLine; // For animation triggering
  // Transient wrong positions: not stored on Cell and auto-cleared
  final Set<String> _transientWrong = {};
  // The solved board (correct solution) stored as ints for quick checks.
  // Filled right after generating a new puzzle so we can validate against
  // the true solution and ignore incorrect user entries during checks.
  List<List<int>>? _solution;
  
  /// Clear the last completed line so UI won't re-trigger animations.
  void clearLastCompletedLine() {
    _lastCompletedLine = null;
  }

  // Getters
  List<List<Cell>> get board => _board;
  String? get lastCompletedLine => _lastCompletedLine;
  int get mistakes => _mistakes;
  int get seconds => _seconds;
  Difficulty get difficulty => _difficulty;
  Cell? get selectedCell => _selectedCell;
  bool get isGameOver => _isGameOver;
  bool get isGameWon => _isGameWon;
  bool get canUndo => _moveHistory.isNotEmpty;
  bool get isPaused => _isPaused;
  bool get isNotesMode => _isNotesMode;
  int get hintsUsed => _hintsUsed;
  int get hintsRemaining => _maxHints - _hintsUsed;
  bool get canUseHint => _hintsUsed < _maxHints && !_isGameOver && !_isGameWon;

  String get formattedTime {
    int minutes = _seconds ~/ 60;
    int secs = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Start a new game with the given difficulty
  void startNewGame(Difficulty difficulty) {
    _difficulty = difficulty;
    _resetGame();
    _generateBoard();
    _startTimer();
    notifyListeners();
  }

  /// Reset game state
  void _resetGame() {
    _board.clear();
    _moveHistory.clear();
    _mistakes = 0;
    _seconds = 0;
    _selectedCell = null;
    _isGameOver = false;
    _isGameWon = false;
    _isPaused = false;
    _isNotesMode = false;
    _hintsUsed = 0;
    _completedLines.clear();
    _lastCompletedLine = null;
    _timer?.cancel();
  }

  /// Generate a new Sudoku board
  void _generateBoard() {
    _board = SudokuGenerator.createPuzzle(_difficulty.cellsToRemove);

    // Compute and store the solution copy so validations can compare against
    // the true solution (so wrong user entries won't pollute checks).
    // Create a deep copy of cells for solving.
    List<List<Cell>> boardCopy = List.generate(
      9,
      (r) => List.generate(9, (c) => _board[r][c].copyWith()),
    );

    // Solve the copy — solver mutates cell values to fill the board.
    if (SudokuSolver.solve(boardCopy)) {
      _solution = List.generate(9, (r) => List.generate(9, (c) => boardCopy[r][c].value));
    } else {
      // Fallback: clear solution if solver failed (shouldn't happen)
      _solution = null;
    }
  }

  /// Start the timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
  }

  /// Stop the timer
  void _stopTimer() {
    _timer?.cancel();
  }

  /// Select a cell
  void selectCell(int row, int col) {
    if (_isGameOver || _isGameWon || _isPaused) return;

    // Clear previous highlights
    for (var rowCells in _board) {
      for (var cell in rowCells) {
        cell.isHighlighted = false;
      }
    }

    // Highlight selected cell (even if fixed, for visual feedback)
    _selectedCell = _board[row][col];
    _selectedCell!.isHighlighted = true;
    notifyListeners();
  }

  /// Check if a cell should be highlighted (same row, col, box, or same value)
  bool shouldHighlightCell(int row, int col) {
    if (_selectedCell == null) return false;
    
    int selectedRow = _selectedCell!.row;
    int selectedCol = _selectedCell!.col;
    int selectedValue = _selectedCell!.value;

    // Same cell
    if (row == selectedRow && col == selectedCol) return false;

    // Same row or column
    if (row == selectedRow || col == selectedCol) return true;

    // Same 3x3 box
    int selectedBoxRow = selectedRow ~/ 3;
    int selectedBoxCol = selectedCol ~/ 3;
    int cellBoxRow = row ~/ 3;
    int cellBoxCol = col ~/ 3;
    if (selectedBoxRow == cellBoxRow && selectedBoxCol == cellBoxCol) return true;

    // Same value (if selected cell has a value and current cell has same value)
    if (selectedValue != 0 && _board[row][col].value == selectedValue) return true;

    return false;
  }

  /// Place a number in the selected cell
  void placeNumber(int number) {
    if (_selectedCell == null || _isGameOver || _isGameWon || _isPaused) return;
    if (_selectedCell!.isFixed) return;

    int row = _selectedCell!.row;
    int col = _selectedCell!.col;

    // Notes mode
    if (_isNotesMode && number != 0) {
      if (_board[row][col].notes.contains(number)) {
        _board[row][col].notes.remove(number);
      } else {
        _board[row][col].notes.add(number);
      }
      notifyListeners();
      return;
    }

    int previousValue = _board[row][col].value;

    // Allow erasing (placing 0)
    if (number == 0) {
      if (previousValue != 0) {
        _moveHistory.add(Move(
          row: row,
          col: col,
          previousValue: previousValue,
          newValue: 0,
        ));
        _board[row][col].value = 0;
        _board[row][col].notes.clear();
        
        // Re-validate affected cells when number is removed
        _revalidateAffectedCells(row, col);
        notifyListeners();
      }
      return;
    }

    // Don't add to history if placing the same number
    if (previousValue == number) return;

    // Record the move
    _moveHistory.add(Move(
      row: row,
      col: col,
      previousValue: previousValue,
      newValue: number,
    ));

    // Place the number
    _board[row][col].value = number;
    _board[row][col].notes.clear();

    // Helper key for transient tracking
    String key = '${row}_$col';

    // Validate this cell against board while ignoring transient-wrong entries
    bool isValid = _isValidIgnoringTransients(_board, row, col, number);
    if (!isValid) {
      // Count a mistake for an invalid placement but do not persistently store
      _mistakes++;
      _vibrate();

      // Mark this position transiently so it doesn't pollute other validations
      _transientWrong.add(key);

      // Auto-clear transient mark after a short delay
      Timer(const Duration(milliseconds: 1500), () {
        if (_transientWrong.remove(key)) notifyListeners();
      });

      if (_mistakes >= 3) {
        _gameOver();
        return; // avoid double notify (we already notified in _gameOver)
      }
    } else {
      // If it was transiently marked wrong before, clear it because user corrected
      if (_transientWrong.remove(key)) {
        // nothing else needed
      }

      // Only check completions when this placement is valid
      _checkCompletions(row, col);

      // Check if game is won
      if (_checkWin()) {
        _gameWon();
        return; // avoid double notify (we already notified in _gameWon)
      }
    }

    // Re-validate affected cells UI-wise (no persistent error flags are set)
    _revalidateAffectedCells(row, col);

    notifyListeners();
  }

  /// NOTE: We no longer persistently store cell error flags in the model.
  /// Error state is computed on demand using `isCellWrong`.

  /// Re-validate all cells affected by a change at (row, col)
  void _revalidateAffectedCells(int row, int col) {
    // We don't persist error flags. This method exists to trigger UI updates
    // after a change so that callers can rely on UI reading validation
    // state via `isCellWrong` which computes validity on demand.
    // (No state changes needed here.)
  }

  String _posKey(int r, int c) => '${r}_$c';

  bool _isTransient(int r, int c) => _transientWrong.contains(_posKey(r, c));

  /// Validate a placement while ignoring any transient-wrong values.
  bool _isValidIgnoringTransients(List<List<Cell>> board, int row, int col, int num) {
    // Row
    for (int c = 0; c < 9; c++) {
      if (c == col) continue;
      final other = board[row][c].value;
      if (other == 0) continue;
      // If we have the true solution, ignore any cell that is not correct
      // (i.e. user-entered wrong values). This ensures wrong values do
      // not pollute validation of other cells.
      if (_solution != null) {
        if (other != _solution![row][c]) continue;
      } else if (_isTransient(row, c)) {
        // Fallback to transient behavior if no solution available
        continue;
      }
      if (other == num) return false;
    }

    // Column
    for (int r = 0; r < 9; r++) {
      if (r == row) continue;
      final other = board[r][col].value;
      if (other == 0) continue;
      if (_solution != null) {
        if (other != _solution![r][col]) continue;
      } else if (_isTransient(r, col)) {
        continue;
      }
      if (other == num) return false;
    }

    // Box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r == row && c == col) continue;
        final other = board[r][c].value;
        if (other == 0) continue;
        if (_solution != null) {
          if (other != _solution![r][c]) continue;
        } else if (_isTransient(r, c)) {
          continue;
        }
        if (other == num) return false;
      }
    }

    return true;
  }

  /// Get count of remaining numbers for a specific value
  int getRemainingCount(int number) {
    int count = 0;
    for (var row in _board) {
      for (var cell in row) {
        if (cell.value == number) {
          count++;
        }
      }
    }
    return 9 - count; // Each number should appear 9 times in a complete board
  }

  /// Undo the last move
  void undo() {
    if (_moveHistory.isEmpty || _isGameOver || _isGameWon) return;

    Move lastMove = _moveHistory.removeLast();
    _board[lastMove.row][lastMove.col].value = lastMove.previousValue;
    _transientWrong.remove(_posKey(lastMove.row, lastMove.col));

    // If we undid a mistake, we don't decrease the mistake counter
    // (as per typical Sudoku game rules)

    // Re-validate affected groups after undo
    _revalidateAffectedCells(lastMove.row, lastMove.col);

    notifyListeners();
  }

  /// Get a hint
  void getHint() {
    if (_isGameOver || _isGameWon || _isPaused || !canUseHint) return;

    // Find an empty cell
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (!_board[row][col].isFixed && _board[row][col].value == 0) {
          int? correctValue = SudokuSolver.getCorrectValue(_board, row, col);
          if (correctValue != null) {
            // Record the move
            _moveHistory.add(Move(
              row: row,
              col: col,
              previousValue: _board[row][col].value,
              newValue: correctValue,
            ));

            _board[row][col].value = correctValue;
            _board[row][col].notes.clear();
            _transientWrong.remove(_posKey(row, col));
            _hintsUsed++;

            // Re-validate affected cells after hint
            _revalidateAffectedCells(row, col);

            // Check for completed lines
            _checkCompletions(row, col);

            // Check if game is won
            if (_checkWin()) {
              _gameWon();
              return; // avoid double notify (we already notified in _gameWon)
            }

            notifyListeners();
            return;
          }
        }
      }
    }
  }

  /// Toggle notes mode
  void toggleNotesMode() {
    _isNotesMode = !_isNotesMode;
    notifyListeners();
  }

  /// Pause the game
  void pauseGame() {
    if (_isGameOver || _isGameWon) return;
    _isPaused = true;
    _stopTimer();
    notifyListeners();
  }

  /// Resume the game
  void resumeGame() {
    if (_isGameOver || _isGameWon) return;
    _isPaused = false;
    _startTimer();
    notifyListeners();
  }

  /// Erase the selected cell
  void eraseCell() {
    if (_selectedCell == null || _isGameOver || _isGameWon || _isPaused) return;
    if (_selectedCell!.isFixed) return;
    
    int row = _selectedCell!.row;
    int col = _selectedCell!.col;
    
    if (_board[row][col].value != 0) {
      _moveHistory.add(Move(
        row: row,
        col: col,
        previousValue: _board[row][col].value,
        newValue: 0,
      ));
      _board[row][col].value = 0;
      _transientWrong.remove(_posKey(row, col));
    }
    _board[row][col].notes.clear();
    notifyListeners();
  }

  /// Vibrate on error
  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      // Vibration not supported on this device
    }
  }

  /// Check for completed rows, columns, and boxes
  void _checkCompletions(int row, int col) {
    _lastCompletedLine = null;
    
    // Check row
    String rowKey = 'row_$row';
    if (!_completedLines.contains(rowKey) && _isRowComplete(row)) {
      _completedLines.add(rowKey);
      _lastCompletedLine = rowKey;
      _vibrate();
    }

    // Check column
    String colKey = 'col_$col';
    if (!_completedLines.contains(colKey) && _isColumnComplete(col)) {
      _completedLines.add(colKey);
      if (_lastCompletedLine == null) _lastCompletedLine = colKey;
      _vibrate();
    }

    // Check box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    String boxKey = 'box_${boxRow}_$boxCol';
    if (!_completedLines.contains(boxKey) && _isBoxComplete(boxRow, boxCol)) {
      _completedLines.add(boxKey);
      if (_lastCompletedLine == null) _lastCompletedLine = boxKey;
      _vibrate();
    }
  }

  /// Check if a row is complete and valid (ignoring error cells)
  bool _isRowComplete(int row) {
    Set<int> seen = {};
    for (int col = 0; col < 9; col++) {
      int value = _board[row][col].value;
      // Ignore empty cells or invalid placements - they don't count as filled
      if (value == 0) return false;
      // Use solution-aware validation: only consider cells that match the solution
      if (_solution != null) {
        if (value != _solution![row][col]) return false;
      } else if (!_isValidIgnoringTransients(_board, row, col, value)) {
        return false;
      }
      if (seen.contains(value)) return false;
      seen.add(value);
    }
    return true;
  }

  /// Check if a column is complete and valid (ignoring error cells)
  bool _isColumnComplete(int col) {
    Set<int> seen = {};
    for (int row = 0; row < 9; row++) {
      int value = _board[row][col].value;
      // Ignore empty cells or invalid placements - they don't count as filled
      if (value == 0) return false;
      if (_solution != null) {
        if (value != _solution![row][col]) return false;
      } else if (!_isValidIgnoringTransients(_board, row, col, value)) {
        return false;
      }
      if (seen.contains(value)) return false;
      seen.add(value);
    }
    return true;
  }

  /// Check if a 3x3 box is complete and valid (ignoring error cells)
  bool _isBoxComplete(int boxRow, int boxCol) {
    Set<int> seen = {};
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int value = _board[boxRow + i][boxCol + j].value;
        // Ignore empty cells or invalid placements - they don't count as filled
        if (value == 0) return false;
        int r = boxRow + i;
        int c = boxCol + j;
        if (_solution != null) {
          if (value != _solution![r][c]) return false;
        } else if (!_isValidIgnoringTransients(_board, r, c, value)) {
          return false;
        }
        if (seen.contains(value)) return false;
        seen.add(value);
      }
    }
    return true;
  }

  /// Compute whether a given cell currently holds an invalid (wrong) value.
  /// This is computed on-demand and not stored as persistent state on the
  /// `Cell` model so that a corrected value immediately stops being shown
  /// as wrong.
  bool isCellWrong(int row, int col) {
    final cell = _board[row][col];
    if (cell.value == 0 || cell.isFixed) return false;
    // If we have the true solution, a cell is wrong iff it doesn't match it.
    if (_solution != null) {
      return cell.value != _solution![row][col];
    }

    // Fallback: show transient wrong if set, otherwise compute validity
    if (_transientWrong.contains(_posKey(row, col))) return true;
    return !_isValidIgnoringTransients(_board, row, col, cell.value);
  }

  /// Get completed lines for UI animations
  bool isLineCompleted(String lineKey) {
    return _completedLines.contains(lineKey);
  }

  /// Get cells for a completed line in reading order (for sequential animation)
  List<Cell> getCellsForLine(String lineKey) {
    List<Cell> cells = [];
    
    if (lineKey.startsWith('row_')) {
      int row = int.parse(lineKey.split('_')[1]);
      for (int col = 0; col < 9; col++) {
        cells.add(_board[row][col]);
      }
    } else if (lineKey.startsWith('col_')) {
      int col = int.parse(lineKey.split('_')[1]);
      for (int row = 0; row < 9; row++) {
        cells.add(_board[row][col]);
      }
    } else if (lineKey.startsWith('box_')) {
      List<String> parts = lineKey.split('_');
      int boxRow = int.parse(parts[1]);
      int boxCol = int.parse(parts[2]);
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          cells.add(_board[boxRow + i][boxCol + j]);
        }
      }
    }
    
    return cells;
  }

  /// Check if the game is won
  bool _checkWin() {
    return SudokuSolver.isSolved(_board);
  }

  /// Handle game over
  void _gameOver() {
    _isGameOver = true;
    _stopTimer();
    notifyListeners();
  }

  /// Handle game won
  void _gameWon() {
    _isGameWon = true;
    _stopTimer();
    notifyListeners();
  }

  /// Retry with same difficulty
  void retry() {
    startNewGame(_difficulty);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
