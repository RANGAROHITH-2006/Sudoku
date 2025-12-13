class Move {
  final int row;
  final int col;
  final int previousValue;
  final int newValue;

  Move({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.newValue,
  });

  @override
  String toString() {
    return 'Move(row: $row, col: $col, prev: $previousValue, new: $newValue)';
  }
}
