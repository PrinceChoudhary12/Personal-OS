// lib/features/brain_games/presentation/screens/brain_games_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/brain_games_providers.dart';
import '../../domain/models/game_model.dart';

class BrainGamesScreen extends ConsumerStatefulWidget {
  const BrainGamesScreen({super.key});

  @override
  ConsumerState<BrainGamesScreen> createState() => _BrainGamesScreenState();
}

class _BrainGamesScreenState extends ConsumerState<BrainGamesScreen> {
  String? _activeGameType; // 'memory_matrix', 'number_recall', 'reaction_speed', 'sequence_memory', 'mental_math'

  void _startGame(String type) {
    setState(() {
      _activeGameType = type;
    });
  }

  void _closeGame() {
    setState(() {
      _activeGameType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scoresAsync = ref.watch(brainGamesStreamProvider);

    if (_activeGameType != null) {
      return _buildActiveGameView(_activeGameType!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Brain Games',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.6,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: scoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load brain training scores',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
              ],
            ),
          ),
        ),
        data: (scores) {
          final scoreMap = {for (var s in scores) s.gameType: s};

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header Panel ---
                    _buildHeaderCard(context, scores),
                    const SizedBox(height: 24),

                    // --- Grid of Games ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 650) {
                          crossAxisCount = 2;
                        }
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.45,
                          children: [
                             _buildGameCard(
                               context,
                               type: 'memory_matrix',
                               title: 'Memory Matrix',
                               description: 'Recall the spatial pattern of highlighted tiles on a grid.',
                               icon: Icons.grid_on_rounded,
                               accentColor: AppColors.gameMemory,
                               stat: scoreMap['memory_matrix'],
                               difficulty: 'Medium',
                             ),
                             _buildGameCard(
                               context,
                               type: 'number_recall',
                               title: 'Number Recall',
                               description: 'Remember a number that increases in digit length each round.',
                               icon: Icons.pin_rounded,
                               accentColor: AppColors.gameRecall,
                               stat: scoreMap['number_recall'],
                               difficulty: 'Easy',
                             ),
                             _buildGameCard(
                               context,
                               type: 'reaction_speed',
                               title: 'Reaction Speed',
                               description: 'Click as fast as you can when the screen turns green.',
                               icon: Icons.flash_on_rounded,
                               accentColor: AppColors.gameReaction,
                               stat: scoreMap['reaction_speed'],
                               isMs: true,
                               difficulty: 'Easy',
                             ),
                             _buildGameCard(
                               context,
                               type: 'sequence_memory',
                               title: 'Sequence Memory',
                               description: 'Remember an increasing sequence of flashing color pads.',
                               icon: Icons.repeat_rounded,
                               accentColor: AppColors.gameSequence,
                               stat: scoreMap['sequence_memory'],
                               difficulty: 'Hard',
                             ),
                             _buildGameCard(
                               context,
                               type: 'mental_math',
                               title: 'Mental Math',
                               description: 'Solve simple math equations as fast as possible in 30 seconds.',
                               icon: Icons.calculate_rounded,
                               accentColor: AppColors.gameMath,
                               stat: scoreMap['mental_math'],
                               difficulty: 'Medium',
                             ),
                           ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, List<GameModel> scores) {
    final totalPlays = scores.fold<int>(0, (sum, s) => sum + s.totalPlays);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brain Training Lab',
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Train cognitive speed, recall, and math dexterity.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPill('$totalPlays plays', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildPill('+20 XP per game', AppColors.accent),
                    const SizedBox(width: 8),
                    _buildPill('5 games', AppColors.secondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required GameModel? stat,
    bool isMs = false,
    String difficulty = 'Medium',
  }) {
    final plays = stat?.totalPlays ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String bestScoreText = plays > 0 ? 'N/A' : '–';
    if (stat != null && stat.bestScore > 0) {
      bestScoreText = isMs
          ? '${stat.bestScore.toInt()} ms'
          : '${stat.bestScore.toInt()} pts';
    }

    final difficultyColor = difficulty == 'Easy'
        ? AppColors.success
        : difficulty == 'Hard'
            ? AppColors.error
            : AppColors.warning;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _startGame(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: icon + difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: difficultyColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      difficulty,
                      style: AppTypography.labelSmall.copyWith(
                        color: difficultyColor,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              // Title + description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headingSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              // Bottom: plays + best score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline_rounded, size: 13, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '$plays plays',
                        style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bestScoreText,
                      style: AppTypography.labelSmall.copyWith(
                        color: accentColor,
                        fontSize: 10,
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
  }

  Widget _buildActiveGameView(String type) {
    switch (type) {
      case 'memory_matrix':
        return _MemoryMatrixGame(onClose: _closeGame);
      case 'number_recall':
        return _NumberRecallGame(onClose: _closeGame);
      case 'reaction_speed':
        return _ReactionSpeedGame(onClose: _closeGame);
      case 'sequence_memory':
        return _SequenceMemoryGame(onClose: _closeGame);
      case 'mental_math':
        return _MentalMathGame(onClose: _closeGame);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. MEMORY MATRIX GAME
// ─────────────────────────────────────────────────────────────────────────────
class _MemoryMatrixGame extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _MemoryMatrixGame({required this.onClose});

  @override
  ConsumerState<_MemoryMatrixGame> createState() => _MemoryMatrixGameState();
}

class _MemoryMatrixGameState extends ConsumerState<_MemoryMatrixGame> {
  int _score = 0;
  int _lives = 3;
  int _gridSize = 3; // 3x3 grid
  int _highlightCount = 3;
  bool _showingPattern = false;
  bool _isPlaying = false;
  bool _isGameOver = false;

  final List<int> _targetTiles = [];
  final List<int> _selectedTiles = [];

  void _startNewRound() {
    _targetTiles.clear();
    _selectedTiles.clear();
    _showingPattern = true;

    // Adjust parameters based on score
    if (_score >= 8) {
      _gridSize = 4;
      _highlightCount = 5;
    } else if (_score >= 4) {
      _gridSize = 3;
      _highlightCount = 4;
    } else {
      _gridSize = 3;
      _highlightCount = 3;
    }

    // Generate random distinct target indexes
    final totalCells = _gridSize * _gridSize;
    final r = Random();
    while (_targetTiles.length < _highlightCount) {
      int idx = r.nextInt(totalCells);
      if (!_targetTiles.contains(idx)) {
        _targetTiles.add(idx);
      }
    }

    setState(() {});

    // Flash grid
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showingPattern = false;
        });
      }
    });
  }

  void _handleTileTap(int idx) {
    if (_showingPattern || _isGameOver || !_isPlaying) return;
    if (_selectedTiles.contains(idx)) return;

    setState(() {
      _selectedTiles.add(idx);
    });

    if (_targetTiles.contains(idx)) {
      // Correct tile
      if (_selectedTiles.length == _highlightCount) {
        // Complete round successfully
        setState(() {
          _score++;
        });
        Timer(const Duration(milliseconds: 500), _startNewRound);
      }
    } else {
      // Incorrect tile
      setState(() {
        _lives--;
      });
      if (_lives <= 0) {
        _endGame();
      } else {
        // Show sequence again and reset selections
        setState(() {
          _showingPattern = true;
          _selectedTiles.clear();
        });
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showingPattern = false;
            });
          }
        });
      }
    }
  }

  void _endGame() {
    setState(() {
      _isGameOver = true;
    });
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null) {
      ref.read(brainGamesRepositoryProvider).recordGamePlay(user.uid, 'memory_matrix', _score.toDouble());
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _lives = 3;
      _gridSize = 3;
      _highlightCount = 3;
      _isPlaying = true;
      _isGameOver = false;
    });
    _startNewRound();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Matrix'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlaying && !_isGameOver) ...[
                const Icon(Icons.grid_on_rounded, size: 72, color: Colors.blueAccent),
                const SizedBox(height: 20),
                const Text(
                  'Memory Matrix',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Remember and tap the spatial pattern of highlighted tiles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Start Game', style: TextStyle(color: Colors.white)),
                ),
              ] else if (_isGameOver) ...[
                const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
                const SizedBox(height: 20),
                const Text('Game Over!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('You scored $_score rounds!', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _resetGame,
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ] else ...[
                // Playing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Score: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Icon(
                          index < _lives ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  _showingPattern ? 'Remember the pattern!' : 'Tap the highlighted cells!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _showingPattern ? Colors.blueAccent : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 30),
                AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _gridSize * _gridSize,
                    itemBuilder: (context, index) {
                      bool isHighlighted = _targetTiles.contains(index);
                      bool isSelected = _selectedTiles.contains(index);

                      Color color = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
                      if (_showingPattern && isHighlighted) {
                        color = Colors.blueAccent;
                      } else if (!_showingPattern) {
                        if (isSelected) {
                          color = isHighlighted ? Colors.green : Colors.redAccent;
                        }
                      }

                      return InkWell(
                        onTap: () => _handleTileTap(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. NUMBER RECALL GAME
// ─────────────────────────────────────────────────────────────────────────────
class _NumberRecallGame extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _NumberRecallGame({required this.onClose});

  @override
  ConsumerState<_NumberRecallGame> createState() => _NumberRecallGameState();
}

class _NumberRecallGameState extends ConsumerState<_NumberRecallGame> {
  int _level = 1;
  String _targetNumber = '';
  final TextEditingController _inputController = TextEditingController();
  bool _showingNumber = false;
  bool _isPlaying = false;
  bool _isGameOver = false;

  void _generateNumber() {
    _inputController.clear();
    final r = Random();
    final sb = StringBuffer();
    // Digit count = level + 2
    final digitsCount = _level + 2;
    for (int i = 0; i < digitsCount; i++) {
      sb.write(r.nextInt(10));
    }
    _targetNumber = sb.toString();
    _showingNumber = true;
    setState(() {});

    // Duration scales with sequence length
    final displayTimeMs = 1500 + (digitsCount * 200);
    Timer(Duration(milliseconds: displayTimeMs), () {
      if (mounted) {
        setState(() {
          _showingNumber = false;
        });
      }
    });
  }

  void _submitRecall() {
    final input = _inputController.text.trim();
    if (input == _targetNumber) {
      // Correct
      setState(() {
        _level++;
      });
      _generateNumber();
    } else {
      // Incorrect -> Game Over
      _endGame();
    }
  }

  void _endGame() {
    setState(() {
      _isGameOver = true;
    });
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null) {
      // Score represents final successfully recalled digit count
      final finalDigits = _level + 1;
      ref.read(brainGamesRepositoryProvider).recordGamePlay(user.uid, 'number_recall', finalDigits.toDouble());
    }
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _isPlaying = true;
      _isGameOver = false;
    });
    _generateNumber();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Recall'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlaying && !_isGameOver) ...[
                const Icon(Icons.pin_rounded, size: 72, color: Colors.purpleAccent),
                const SizedBox(height: 20),
                const Text('Number Recall', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'Memorize and type back numbers that grow longer each round.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Start Game', style: TextStyle(color: Colors.white)),
                ),
              ] else if (_isGameOver) ...[
                const Icon(Icons.mood_bad_rounded, size: 72, color: Colors.purple),
                const SizedBox(height: 20),
                const Text('Game Over!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Correct digits recalled: ${_level + 1}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text('The number was: $_targetNumber', style: TextStyle(fontSize: 13, color: theme.hintColor)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _resetGame,
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ] else ...[
                // Playing
                Text('Round: $_level', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                if (_showingNumber) ...[
                  Text(
                    _targetNumber,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Memorize the digits...', style: TextStyle(color: Colors.purpleAccent)),
                ] else ...[
                  const Text('What was the number?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _inputController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Type numbers...',
                      ),
                      onSubmitted: (_) => _submitRecall(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitRecall,
                    child: const Text('Submit'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. REACTION SPEED GAME
// ─────────────────────────────────────────────────────────────────────────────
class _ReactionSpeedGame extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _ReactionSpeedGame({required this.onClose});

  @override
  ConsumerState<_ReactionSpeedGame> createState() => _ReactionSpeedGameState();
}

class _ReactionSpeedGameState extends ConsumerState<_ReactionSpeedGame> {
  String _gameState = 'idle'; // 'idle', 'waiting', 'ready', 'result', 'early'
  int? _reactionTime;
  DateTime? _greenStartTime;
  Timer? _triggerTimer;

  void _startWaiting() {
    _triggerTimer?.cancel();
    setState(() {
      _gameState = 'waiting';
      _reactionTime = null;
    });

    final delay = 2000 + Random().nextInt(3000); // 2 to 5 seconds delay
    _triggerTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() {
          _gameState = 'ready';
          _greenStartTime = DateTime.now();
        });
      }
    });
  }

  void _handleTap() {
    if (_gameState == 'waiting') {
      _triggerTimer?.cancel();
      setState(() {
        _gameState = 'early';
      });
    } else if (_gameState == 'ready') {
      final now = DateTime.now();
      final difference = now.difference(_greenStartTime!).inMilliseconds;
      setState(() {
        _reactionTime = difference;
        _gameState = 'result';
      });
      final user = ref.read(firebaseAuthStateProvider).valueOrNull;
      if (user != null) {
        ref.read(brainGamesRepositoryProvider).recordGamePlay(user.uid, 'reaction_speed', difference.toDouble());
      }
    }
  }

  @override
  void dispose() {
    _triggerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Widget content = const SizedBox.shrink();

    if (_gameState == 'idle') {
      bgColor = Theme.of(context).cardColor;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on_rounded, size: 72, color: Colors.amberAccent),
          const SizedBox(height: 20),
          const Text('Reaction Speed Test', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Click anywhere as soon as the screen turns green.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _startWaiting,
            child: const Text('Start'),
          ),
        ],
      );
    } else if (_gameState == 'waiting') {
      bgColor = Colors.redAccent.withValues(alpha: 0.8);
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WAIT FOR GREEN...',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            'Tap when it turns green',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    } else if (_gameState == 'ready') {
      bgColor = Colors.green.withValues(alpha: 0.9);
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TAP NOW!',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      );
    } else if (_gameState == 'early') {
      bgColor = Colors.orangeAccent.withValues(alpha: 0.8);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 20),
          const Text('Too Early!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('Tap only when the screen is green.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _startWaiting,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: const Text('Try Again'),
          ),
        ],
      );
    } else if (_gameState == 'result') {
      bgColor = Theme.of(context).cardColor;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_rounded, size: 72, color: Colors.green),
          const SizedBox(height: 20),
          Text('$_reactionTime ms', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('Great reaction speed!', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startWaiting,
                child: const Text('Try Again'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: widget.onClose,
                child: const Text('Exit'),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Reaction Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: content,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SEQUENCE MEMORY GAME (Simon Says)
// ─────────────────────────────────────────────────────────────────────────────
class _SequenceMemoryGame extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _SequenceMemoryGame({required this.onClose});

  @override
  ConsumerState<_SequenceMemoryGame> createState() => _SequenceMemoryGameState();
}

class _SequenceMemoryGameState extends ConsumerState<_SequenceMemoryGame> {
  int _score = 0;
  final List<int> _sequence = [];
  final List<int> _userSequence = [];
  bool _showingSequence = false;
  bool _isPlaying = false;
  bool _isGameOver = false;
  int? _flashingIndex;

  void _nextLevel() {
    _userSequence.clear();
    final nextColor = Random().nextInt(4); // 4 pads
    _sequence.add(nextColor);
    _playSequence();
  }

  void _playSequence() async {
    setState(() {
      _showingSequence = true;
    });

    for (int i = 0; i < _sequence.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _flashingIndex = _sequence[i];
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _flashingIndex = null;
      });
    }

    if (mounted) {
      setState(() {
        _showingSequence = false;
      });
    }
  }

  void _handlePadTap(int index) {
    if (_showingSequence || _isGameOver || !_isPlaying) return;

    setState(() {
      _flashingIndex = index;
    });
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _flashingIndex = null;
        });
      }
    });

    _userSequence.add(index);
    final currentStep = _userSequence.length - 1;

    if (_userSequence[currentStep] != _sequence[currentStep]) {
      // Fail
      _endGame();
    } else if (_userSequence.length == _sequence.length) {
      // Completed level
      setState(() {
        _score++;
      });
      Timer(const Duration(milliseconds: 600), _nextLevel);
    }
  }

  void _endGame() {
    setState(() {
      _isGameOver = true;
    });
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null) {
      ref.read(brainGamesRepositoryProvider).recordGamePlay(user.uid, 'sequence_memory', _score.toDouble());
    }
  }

  void _resetGame() {
    _sequence.clear();
    setState(() {
      _score = 0;
      _isPlaying = true;
      _isGameOver = false;
    });
    _nextLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequence Memory'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlaying && !_isGameOver) ...[
                const Icon(Icons.repeat_rounded, size: 72, color: Colors.tealAccent),
                const SizedBox(height: 20),
                const Text('Sequence Memory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'Repeat the flashing block sequence correctly to advance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Start Game', style: TextStyle(color: Colors.white)),
                ),
              ] else if (_isGameOver) ...[
                const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
                const SizedBox(height: 20),
                const Text('Game Over!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Score: $_score points', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _resetGame,
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ] else ...[
                // Playing
                Text('Score: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(_showingSequence ? 'Watch the sequence!' : 'Your turn to repeat!', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSimonPad(0, Colors.redAccent, Colors.red),
                      _buildSimonPad(1, Colors.blueAccent, Colors.blue),
                      _buildSimonPad(2, Colors.greenAccent, Colors.green),
                      _buildSimonPad(3, Colors.amberAccent, Colors.amber),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimonPad(int index, Color brightColor, Color dimColor) {
    final isFlashing = _flashingIndex == index;
    return Material(
      color: isFlashing ? brightColor : dimColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _handlePadTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFlashing ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. MENTAL MATH GAME
// ─────────────────────────────────────────────────────────────────────────────
class _MentalMathGame extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _MentalMathGame({required this.onClose});

  @override
  ConsumerState<_MentalMathGame> createState() => _MentalMathGameState();
}

class _MentalMathGameState extends ConsumerState<_MentalMathGame> {
  int _score = 0;
  int _timeLeft = 30;
  Timer? _countdownTimer;

  String _currentQuestion = '';
  int _correctAnswer = 0;
  final List<int> _options = [];

  void _generateQuestion() {
    final r = Random();
    final type = r.nextInt(3); // + , - , *
    
    int val1 = 0;
    int val2 = 0;
    
    if (type == 0) {
      val1 = 5 + r.nextInt(50);
      val2 = 5 + r.nextInt(50);
      _correctAnswer = val1 + val2;
      _currentQuestion = '$val1 + $val2';
    } else if (type == 1) {
      val1 = 15 + r.nextInt(60);
      val2 = 5 + r.nextInt(val1 - 5);
      _correctAnswer = val1 - val2;
      _currentQuestion = '$val1 - $val2';
    } else {
      val1 = 2 + r.nextInt(10);
      val2 = 3 + r.nextInt(10);
      _correctAnswer = val1 * val2;
      _currentQuestion = '$val1 × $val2';
    }

    _options.clear();
    _options.add(_correctAnswer);
    while (_options.length < 4) {
      final offset = -10 + r.nextInt(20);
      final fake = _correctAnswer + offset;
      if (fake != _correctAnswer && fake >= 0 && !_options.contains(fake)) {
        _options.add(fake);
      }
    }
    _options.shuffle();
    setState(() {});
  }

  void _handleOptionSelect(int option) {
    if (_timeLeft <= 0) return;

    if (option == _correctAnswer) {
      setState(() {
        _score++;
      });
    }
    _generateQuestion();
  }

  void _startTimer() {
    _generateQuestion();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft <= 0) {
          timer.cancel();
          _endGame();
        }
      }
    });
  }

  void _endGame() {
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null) {
      ref.read(brainGamesRepositoryProvider).recordGamePlay(user.uid, 'mental_math', _score.toDouble());
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGameOver = _timeLeft <= 0;
    final isPlaying = _countdownTimer?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Math'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPlaying && !isGameOver) ...[
                const Icon(Icons.calculate_rounded, size: 72, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text('Mental Math', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'Solve arithmetic questions correctly under a 30 second limit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Start Game', style: TextStyle(color: Colors.white)),
                ),
              ] else if (isGameOver) ...[
                const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
                const SizedBox(height: 20),
                const Text('Time\'s Up!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Score: $_score correct answers!', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _resetGame,
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ] else ...[
                // Playing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Score: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _timeLeft <= 5 ? Colors.redAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Time Left: $_timeLeft s',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft <= 5 ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Text(
                  _currentQuestion,
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 50),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final option = _options[index];
                      return ElevatedButton(
                        onPressed: () => _handleOptionSelect(option),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('$option', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
