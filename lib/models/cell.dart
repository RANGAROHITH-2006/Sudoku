class Cell {
  final int row;
  final int col;
  int value;
  final bool isFixed;
  bool isHighlighted;
  bool isError;
  Set<int> notes; // For note-taking mode

  Cell({
    required this.row,
    required this.col,
    required this.value,
    this.isFixed = false,
    this.isHighlighted = false,
    this.isError = false,
    Set<int>? notes,
  }) : notes = notes ?? {};

  Cell copyWith({
    int? row,
    int? col,
    int? value,
    bool? isFixed,
    bool? isHighlighted,
    bool? isError,
    Set<int>? notes,
  }) {
    return Cell(
      row: row ?? this.row,
      col: col ?? this.col,
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isError: isError ?? this.isError,
      notes: notes ?? Set<int>.from(this.notes),
    );
  }

  @override
  String toString() {
    return 'Cell(row: $row, col: $col, value: $value, isFixed: $isFixed, notes: $notes)';
  }
}
