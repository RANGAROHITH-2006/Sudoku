import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/screens/home_screen.dart';
import '../models/difficulty.dart';
import '../controllers/game_controller.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_header.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.startNewGame(widget.difficulty);

    // Listen for game state changes
    _controller.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (_controller.isGameOver) {
      _showGameOverDialog();
    } else if (_controller.isGameWon) {
      _showWinDialog();
    } else if (_controller.isPaused) {
      _showPauseDialog();
    }
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Game Paused',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a short break — your progress is saved.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  // Buttons stacked vertically to match requested design
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.0),
                            child: Text(
                              'Continue',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _controller.resumeGame();
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            // Navigator.pop(context);
                            _showConfirmDialog(
                              title: 'Restart game?',
                              message:
                                  'This will restart the current puzzle. Continue?',
                              onConfirm: () {
                                _controller.retry();
                                Navigator.pop(context);
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Restart',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            // Navigator.pop(context);
                            _showHelpDialog();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'How to play',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            // Navigator.pop(context);
                            _showConfirmDialog(
                              title: 'Leave game?',
                              message:
                                  'Are you sure you want to leave? Your progress will be lost.',
                              onConfirm: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Leave game',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog({
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) { // ✅ important
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext), // ✅
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // ✅ close dialog
                        onConfirm();                  // ✅ then act
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _showHelpDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'How to play',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[700]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Fill the grid so that each row, column, and 3×3 box contains the numbers 1 to 9.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tap a cell to select it, then use the number pad to place a number.',

                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Use pencil mode to jot down possible numbers in a cell.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 12),

                  // Controls
                  Text(
                    '• Undo: Revert your most recent move.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Erase: Remove the selected number or notes from a cell.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Hint: Reveal a correct number for a selected cell when you are stuck.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 18.0,
                        ),
                        child: Text(
                          'Got it',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel,
                    color: Color(0xFFE74C3C),
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Game Over',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You made ${_controller.mistakes} mistakes. Try again to beat the puzzle!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _controller.retry();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // completed image
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'assets/images/completed.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Color(0xFFFFA500),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Congratulations!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You solved the puzzle!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _controller.formattedTime,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 28),
                      Column(
                        children: [
                          const Text(
                            'Mistakes',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_controller.mistakes}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Home'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _controller.retry();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'Play Again',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: WillPopScope(
        onWillPop: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Leave game?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Are you sure you want to leave the game? Your progress may be lost.',
                        style: TextStyle(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Leave'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          return confirmed ?? false;
        },
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.grey[100],
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.pause, color: Colors.grey[800]),
              onPressed: () => _controller.pauseGame(),
            ),
            title: Text(
              widget.difficulty.displayName,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline, color: Colors.grey[800]),
                onPressed: () {
                  _showHelpDialog();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const GameHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SudokuGrid(),
                          SizedBox(height: 32),
                          GameControls(),
                          SizedBox(height: 24),
                          NumberPad(),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
