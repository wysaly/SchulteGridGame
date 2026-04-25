import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/challenge_session.dart';
import '../../models/game_level.dart';
import '../db_connect_user.dart';
import 'number/sound_manager.dart' as NumberSoundManager;
import 'poem/sound_manager.dart' as PoemSoundManager;

class FixedChallengeGamePage extends StatefulWidget {
  const FixedChallengeGamePage({super.key});

  @override
  State<FixedChallengeGamePage> createState() => _FixedChallengeGamePageState();
}

class _FixedChallengeGamePageState extends State<FixedChallengeGamePage> {
  late ChallengeSession _session;
  late GameLevel currentLevel;
  int currentLevelIndex = 0; // 0-9 对应10个关卡

  late List<dynamic> gridItems;
  late int gridSize;
  late String originalSequence;
  late Set<int> correctlyClickedIndices; // 已正确点击的位置索引
  int nextItem = 1;
  int levelErrorCount = 0; // 当前关卡的错误数
  bool isGameActive = false;
  bool isPunishmentActive = false;
  DateTime? startTime;
  Duration gameDuration = Duration.zero;
  Timer? gameTimer;
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _isCountingDown = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  dynamic _lastClickedWronglyItem;
  late dynamic _soundManager;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    _session = ChallengeSession(userId: DBService.currentUserId ?? 0);
    currentLevelIndex = 0;
    _loadLevel(0);
  }

  /// 加载指定关卡（0-9）
  Future<void> _loadLevel(int levelIndex) async {
    if (levelIndex >= allLevels.length) {
      _saveAndReturn();
      return;
    }

    currentLevelIndex = levelIndex;
    currentLevel = allLevels[levelIndex];
    gridSize = currentLevel.gridSize;
    gridItems = [];
    originalSequence = '';
    correctlyClickedIndices = {};
    levelErrorCount = 0;
    nextItem = 1;

    if (!_isInitialized) {
      _initializeGame();
    } else {
      _loadGameContent();
      startNewGame();
    }
  }

  Future<void> _initializeGame() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (currentLevel.type == GameType.number ||
          currentLevel.type == GameType.numberFlipped) {
        _soundManager = NumberSoundManager.SoundManager();
      } else {
        _soundManager = PoemSoundManager.SoundManager();
      }

      await _soundManager.preloadSounds();
      final bool soundInitialized = await _soundManager.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = soundInitialized;
          if (_isInitialized) {
            _loadGameContent();
            startNewGame();
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('初始化失败: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
        Future.delayed(const Duration(seconds: 1), _initializeGame);
      }
    }
  }

  Future<void> _loadGameContent() async {
    switch (currentLevel.type) {
      case GameType.number:
      case GameType.numberFlipped:
        gridItems = List.generate(gridSize * gridSize, (i) => i + 1);
        gridItems.shuffle(Random());
        originalSequence = '';
        break;

      case GameType.poem:
        Map<String, String>? poemData;
        if (currentLevel.gridSize == 3) {
          poemData = await DBService.getRandomSentence(1, 30);
        } else if (currentLevel.gridSize == 4) {
          poemData = await DBService.getRandomSentence(31, 60);
        }

        if (poemData != null && poemData['text']!.isNotEmpty) {
          originalSequence = poemData['text']!;
          gridItems = originalSequence.split('');
          gridItems.shuffle(Random());
        } else {
          gridItems = [];
          originalSequence = '';
        }
        break;

      case GameType.sentence:
        Map<String, String>? sentenceData = await DBService.getRandomSentence(
          61,
          79,
        );
        if (sentenceData != null && sentenceData['text']!.isNotEmpty) {
          originalSequence = sentenceData['text']!;
          gridItems = originalSequence.split('');
          gridItems.shuffle(Random());
        } else {
          gridItems = [];
          originalSequence = '';
        }
        break;
    }
  }

  void startNewGame() async {
    await _soundManager.reset();

    setState(() {
      isGameActive = false;
      _isCountingDown = true;
      _countdown = 3;
      nextItem = 1;
      levelErrorCount = 0;
      gameDuration = Duration.zero;
      gameTimer?.cancel();
      _countdownTimer?.cancel();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isCountingDown = false;
            isGameActive = true;
            startTime = DateTime.now();
            gameTimer = Timer.periodic(const Duration(milliseconds: 100), (
              timer,
            ) {
              if (isGameActive && mounted) {
                setState(() {
                  gameDuration = DateTime.now().difference(startTime!);
                });
              }
            });
          });
        }
      }
    });
  }

  void handleItemClick(int index) {
    if (!isGameActive || isPunishmentActive) return;

    final clickedItem = gridItems[index];
    bool isCorrect = false;

    if (currentLevel.type == GameType.number ||
        currentLevel.type == GameType.numberFlipped) {
      isCorrect = clickedItem == nextItem;
    } else if (currentLevel.type == GameType.poem ||
        currentLevel.type == GameType.sentence) {
      if (nextItem <= originalSequence.length) {
        final expectedChar = originalSequence[nextItem - 1];
        isCorrect = clickedItem == expectedChar;
      }
    }

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      _soundManager.playClick();
      setState(() {
        correctlyClickedIndices.add(index);
        nextItem++;
        bool isComplete = false;
        if (currentLevel.type == GameType.number ||
            currentLevel.type == GameType.numberFlipped) {
          isComplete = nextItem > gridSize * gridSize;
        } else if (currentLevel.type == GameType.poem ||
            currentLevel.type == GameType.sentence) {
          isComplete = nextItem > originalSequence.length;
        }

        if (isComplete) {
          isGameActive = false;
          gameTimer?.cancel();
          showLevelCompleteDialog();
        }
      });
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        isPunishmentActive = true;
        _lastClickedWronglyItem = clickedItem;
        levelErrorCount++;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _lastClickedWronglyItem = null;
          });
        }
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            isPunishmentActive = false;
          });
        }
      });
    }
  }

  /// 获取结算语
  String _getSettlementMessage() {
    final T = currentLevel.standardTime;
    final timeSpent =
        gameDuration.inSeconds + gameDuration.inMilliseconds / 1000.0;

    if (timeSpent <= 0.8 * T && levelErrorCount == 0) {
      return '你比我强'; // Easy
    } else if (timeSpent <= 1.5 * T && levelErrorCount <= 2) {
      return '和我差不多嘛'; // Good
    } else {
      return '竟然比我都慢'; // Hard
    }
  }

  void showLevelCompleteDialog() {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    Future.delayed(const Duration(milliseconds: 100), () {
      _soundManager.playSuccess();
    });

    final timeTaken =
        gameDuration.inSeconds + (gameDuration.inMilliseconds % 1000) / 1000.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('恭喜！'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('关卡 ${currentLevelIndex + 1}/10'),
                const SizedBox(height: 8),
                Text('用时: ${timeTaken.toStringAsFixed(2)} 秒'),
                const SizedBox(height: 12),
                Text(
                  _getSettlementMessage(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 放弃挑战，返回主页
                  Navigator.of(context).pop();
                },
                child: const Text('放弃'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _proceedToNextLevel();
                },
                child: const Text('下一关'),
              ),
            ],
          ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// 进行到下一个关卡
  void _proceedToNextLevel() {
    // 计算精确到两位小数的时间
    final timeTaken =
        gameDuration.inSeconds + (gameDuration.inMilliseconds % 1000) / 1000.0;

    // 保存当前关卡的数据
    _session.updateLevel(currentLevel.id, timeTaken, levelErrorCount);

    // 移动到下一关
    if (currentLevelIndex + 1 < allLevels.length) {
      _loadLevel(currentLevelIndex + 1);
    } else {
      // 完成所有10关，保存到数据库
      _saveAndReturn();
    }
  }

  /// 保存到数据库并返回
  Future<void> _saveAndReturn() async {
    if (!_session.isComplete()) {
      debugPrint('未完成所有关卡');
      return;
    }

    final success = await DBService.saveFixedChallengeRecord(_session.toMap());

    if (!mounted) return;

    if (success) {
      _showCompletionDialog();
    } else {
      _showSaveFailedDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('🎉 恭喜完成所有挑战！'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '总用时: ${_session.totalTime} 秒',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '总错误数: ${_session.totalErrorCount} 次',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '关卡明细:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        ..._buildLevelDetails(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('返回'),
              ),
            ],
          ),
    );
  }

  void _showSaveFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('保存失败'),
            content: const Text('挑战记录保存失败，请检查网络连接'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('返回'),
              ),
            ],
          ),
    );
  }

  List<Widget> _buildLevelDetails() {
    return List.generate(allLevels.length, (index) {
      final level = allLevels[index];
      final time = _session.getLevelTime(level.id);
      final errors = _session.getLevelErrorCount(level.id);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '关卡${index + 1}: ${time}秒, ${errors}次错误',
          style: const TextStyle(fontSize: 14),
        ),
      );
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _countdownTimer?.cancel();
    _soundManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('固定挑战')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('固定挑战 - 第 ${currentLevelIndex + 1}/10 关')),
      backgroundColor: const Color(0xFF66D7B4),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentLevel.type == GameType.number ||
                          currentLevel.type == GameType.numberFlipped
                      ? '请按顺序点击数字'
                      : '请按顺序点击文字',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (currentLevel.type == GameType.poem ||
                  currentLevel.type == GameType.sentence)
                if (originalSequence.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      '目标：$originalSequence',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '时间:',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${gameDuration.inSeconds}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: gridItems.length,
                  itemBuilder: (context, index) {
                    final item = gridItems[index];
                    Color tileColor = const Color(0xFF5ED8CC);

                    if (_lastClickedWronglyItem == item) {
                      tileColor = Colors.red;
                    } else if (currentLevel.type == GameType.number ||
                        currentLevel.type == GameType.numberFlipped) {
                      if (item is int && item < nextItem) {
                        tileColor = const Color(0xFFAFE6D3);
                      }
                    } else if (currentLevel.type == GameType.poem ||
                        currentLevel.type == GameType.sentence) {
                      // 检查这个位置是否已正确点击过
                      if (correctlyClickedIndices.contains(index)) {
                        tileColor = const Color(0xFFAFE6D3);
                      }
                    }

                    return GestureDetector(
                      onTap: () => handleItemClick(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child:
                              currentLevel.isFlipped
                                  ? Transform.rotate(
                                    angle: pi,
                                    child: Text(
                                      item.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    item.toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isCountingDown)
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 120,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
