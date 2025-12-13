enum Difficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  int get cellsToRemove {
    switch (this) {
      case Difficulty.easy:
        return 30; // Remove 30 cells (51 filled)
      case Difficulty.medium:
        return 40; // Remove 40 cells (41 filled)
      case Difficulty.hard:
        return 50; // Remove 50 cells (31 filled)
    }
  }
}
