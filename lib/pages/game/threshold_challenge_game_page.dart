import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_level.dart';
import '../../models/threshold_challenge_session.dart';
import '../db_connect_user.dart';
import 'number/sound_manager.dart' as NumberSoundManager;
import 'poem/sound_manager.dart' as PoemSoundManager;

enum ThresholdResult { easy, good, normal, hard }

class ThresholdChallengeGamePage extends StatefulWidget {
  const ThresholdChallengeGamePage({super.key});

  @override
  State<ThresholdChallengeGamePage> createState() =>
      _ThresholdChallengeGamePageState();
}

class _ThresholdChallengeGamePageState
    extends State<ThresholdChallengeGamePage> {
  late ThresholdChallengeSession _session;
  late GameLevel currentLevel;
  int currentLevelIndex = 0; // 当前关卡在allLevels中的索引

  late List<dynamic> gridItems;
  late int gridSize;
  late String originalSequence;
  late Set<int> correctlyClickedIndices; // 已正确点击的位置索引
  int nextItem = 1;
  int levelErrorCount = 0;
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

  // 阈值挑战特有的状态
  int consecutiveGoodCount = 0; // 连续good的次数
  final int maxRecords = 10; // 最多10条记录

  @override
  void initState() {
    super.initState();
    _session = ThresholdChallengeSession(userId: DBService.currentUserId ?? 0);
    currentLevelIndex = 0;
    _loadLevel(0);
  }

  /// 加载指定关卡
  Future<void> _loadLevel(int levelIndex) async {
    if (levelIndex >= allLevels.length) {
      // 回到第一关
      currentLevelIndex = 0;
      currentLevel = allLevels[0];
    } else {
      currentLevelIndex = levelIndex;
      currentLevel = allLevels[levelIndex];
    }

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

  /// 判定阈值结果
  ThresholdResult _evaluateThreshold() {
    final T = currentLevel.standardTime.toDouble();
    final timeSpent =
        gameDuration.inSeconds + gameDuration.inMilliseconds / 1000.0;
    final gridSize = currentLevel.gridSize * currentLevel.gridSize;

    // ===== 1. 动态错误容忍 =====
    final allowedErrors = ((0.12 * gridSize).ceil());

    // ===== 2. 时间评分（带宽容区）=====
    int timeScore;
    if (timeSpent <= 0.8 * T) {
      timeScore = 3; // 非常快
    } else if (timeSpent <= T + 2) {
      timeScore = 2; // 可接受（宽容区）
    } else if (timeSpent <= 1.5 * T) {
      timeScore = 1; // 略慢
    } else {
      timeScore = 0; // 很慢
    }

    // ===== 3. 错误评分（随难度变化）=====
    int errorScore;
    if (levelErrorCount == 0) {
      errorScore = 3; // 完美
    } else if (levelErrorCount <= allowedErrors) {
      errorScore = 2; // 可接受
    } else if (levelErrorCount <= allowedErrors + 2) {
      errorScore = 1; // 偏多
    } else {
      errorScore = 0; // 很多错误
    }

    // ===== 4. 综合评分 =====
    final totalScore = timeScore + errorScore;

    // ===== 5. 四分类决策 =====
    if (totalScore > 5) {
      return ThresholdResult.easy; // +2 难度
    } else if (totalScore >= 4) {
      return ThresholdResult.good; // +1 难度
    } else if (totalScore >= 2) {
      return ThresholdResult.normal; // 保持难度
    } else {
      return ThresholdResult.hard; // -1 难度
    }
  }

  void showLevelCompleteDialog() {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    Future.delayed(const Duration(milliseconds: 100), () {
      _soundManager.playSuccess();
    });

    final result = _evaluateThreshold();
    final resultText =
        result == ThresholdResult.easy
            ? '简单'
            : result == ThresholdResult.good
            ? '良好'
            : result == ThresholdResult.normal
            ? '正常'
            : '困难';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('关卡完成！'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('关卡 ${currentLevelIndex + 1}'),
                const SizedBox(height: 8),
                Text(
                  '用时: ${(gameDuration.inSeconds + (gameDuration.inMilliseconds % 1000) / 1000.0).toStringAsFixed(2)} 秒',
                ),
                const SizedBox(height: 8),
                Text('错误: $levelErrorCount 次'),
                const SizedBox(height: 8),
                Text(
                  '评定: $resultText',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        result == ThresholdResult.easy
                            ? Colors.green
                            : result == ThresholdResult.good
                            ? Colors.orange
                            : result == ThresholdResult.normal
                            ? Colors.yellow[700]
                            : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getSettlementMessage(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已记录: ${_session.getRecordCount()}/$maxRecords',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('放弃'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _proceedByThreshold(result);
                },
                child: const Text('继续'),
              ),
            ],
          ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// 根据阈值结果进行下一步
  void _proceedByThreshold(ThresholdResult result) {
    final timeTaken =
        gameDuration.inSeconds + (gameDuration.inMilliseconds % 1000) / 1000.0;

    // 记录此次成绩
    _session.addLevelRecord(currentLevel.id, timeTaken, levelErrorCount);

    // 检查是否达到10条记录
    if (_session.getRecordCount() >= maxRecords) {
      _saveAndReturn();
      return;
    }

    // 根据结果判定下一步
    switch (result) {
      case ThresholdResult.easy:
        // Easy：跳两关 (+2)
        consecutiveGoodCount = 0;
        _moveToNextLevelBySteps(2);
        break;

      case ThresholdResult.good:
        // Good：进入下一关 (+1)
        consecutiveGoodCount = 0;
        _moveToNextLevelBySteps(1);
        break;

      case ThresholdResult.normal:
        // Normal：保持难度 (0)
        consecutiveGoodCount = 0;
        _loadLevel(currentLevelIndex);
        break;

      case ThresholdResult.hard:
        // Hard：回退一关 (-1)
        consecutiveGoodCount = 0;
        _moveToPreviousLevelBySteps(1);
        break;
    }
  }

  /// 按步数向后移动关卡（含边界检查）
  void _moveToNextLevelBySteps(int steps) {
    int nextIndex = currentLevelIndex + steps;
    // 如果超出上界，保持在最后一关
    if (nextIndex >= allLevels.length) {
      nextIndex = allLevels.length - 1;
    }
    _loadLevel(nextIndex);
  }

  /// 按步数向前移动关卡（含边界检查）
  void _moveToPreviousLevelBySteps(int steps) {
    int previousIndex = currentLevelIndex - steps;
    // 如果超出下界，保持在第一关
    if (previousIndex < 0) {
      previousIndex = 0;
    }
    _loadLevel(previousIndex);
  }

  /// 保存到数据库并返回
  Future<void> _saveAndReturn() async {
    final success = await DBService.saveThresholdChallengeRecord(
      _session.toMap(),
    );

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
            title: const Text('🎉 挑战完成！'),
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
                          '经历关卡数: ${_session.getRecordCount()}',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '总用时: ${_session.totalTime.toStringAsFixed(2)} 秒',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '总错误数: ${_session.totalErrorCount} 次',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '关卡序列:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _session.levelIds.join(' → '),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
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
        appBar: AppBar(title: const Text('阈值挑战')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('阈值挑战 - ${_session.getRecordCount()}/$maxRecords'),
      ),
      backgroundColor: const Color(0xFF66D7B4),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      currentLevel.name,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLevel.type == GameType.number ||
                              currentLevel.type == GameType.numberFlipped
                          ? '请按顺序点击数字'
                          : '请按顺序点击文字',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
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
                        fontSize: 14,
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
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${gameDuration.inSeconds}s',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    item.toString(),
                                    style: const TextStyle(
                                      fontSize: 22,
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
