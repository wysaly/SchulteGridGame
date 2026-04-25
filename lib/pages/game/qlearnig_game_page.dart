import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_level.dart';
import '../../models/qlearnig_session.dart';
import '../db_connect_user.dart';
import 'number/sound_manager.dart' as NumberSoundManager;
import 'poem/sound_manager.dart' as PoemSoundManager;

class QLearnigGamePage extends StatefulWidget {
  const QLearnigGamePage({super.key});

  @override
  State<QLearnigGamePage> createState() => _QLearnigGamePageState();
}

class _QLearnigGamePageState extends State<QLearnigGamePage> {
  late QLearnigSession _session;
  late Map<String, double> _qTable;

  late GameLevel currentLevel;
  int currentLevelIndex = 2; // 从第2关开始（索引1）

  late List<dynamic> gridItems;
  late int gridSize;
  late String originalSequence;
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

  // Q-Learning特有的状态
  int currentState = 0; // 当前状态
  int selectedAction = 1; // 选中的动作（默认保持）
  int reward = 0; // 当前关卡的奖励
  final int maxRecords = 10; // 最多10条记录

  @override
  void initState() {
    super.initState();
    _session = QLearnigSession(userId: DBService.currentUserId ?? 0);
    _qTable = {};
    _loadQTableAndStart();
  }

  Future<void> _loadQTableAndStart() async {
    _qTable = await DBService.getQTable();
    _loadLevel(currentLevelIndex);
  }

  Future<void> _loadLevel(int levelIndex) async {
    // 检查边界
    if (levelIndex < 0) {
      currentLevelIndex = 0;
    } else if (levelIndex >= allLevels.length) {
      currentLevelIndex = allLevels.length - 1;
    } else {
      currentLevelIndex = levelIndex;
    }

    currentLevel = allLevels[currentLevelIndex];
    gridSize = currentLevel.gridSize;
    gridItems = [];
    originalSequence = '';
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

  /// 使用ε-greedy策略选择动作
  int _selectActionEpsilonGreedy(int state) {
    final random = Random();
    if (random.nextDouble() < _session.epsilon) {
      // 探索：随机选择动作
      return random.nextInt(3);
    } else {
      // 利用：选择最优动作
      double maxQ = -double.infinity;
      int bestAction = 1; // 默认保持

      for (int action = 0; action < 3; action++) {
        final qValue = _qTable['$state-$action'] ?? 0.0;
        if (qValue > maxQ) {
          maxQ = qValue;
          bestAction = action;
        }
      }

      return bestAction;
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

    // 计算状态和奖励
    currentState = StateCalculator.getState(
      timeTaken,
      currentLevel.standardTime,
      levelErrorCount,
      gridSize,
    );
    reward = StateCalculator.getReward(currentState);

    // 使用ε-greedy选择动作
    selectedAction = _selectActionEpsilonGreedy(currentState);

    // 计算下一个关卡
    int nextLevelIndex = currentLevelIndex;
    if (selectedAction == 0 && currentLevelIndex > 0) {
      nextLevelIndex = currentLevelIndex - 1;
    } else if (selectedAction == 2 &&
        currentLevelIndex < allLevels.length - 1) {
      nextLevelIndex = currentLevelIndex + 1;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('关卡完成！'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关卡: ${currentLevel.name}'),
                  const SizedBox(height: 12),
                  Text(
                    '用时: ${timeTaken.toStringAsFixed(2)}s (标准: ${currentLevel.standardTime}s)',
                  ),
                  const SizedBox(height: 8),
                  Text('错误: $levelErrorCount 次'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 当前状态: ${StateCalculator.getStateDescription(currentState)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⭐ 奖励: ${reward > 0 ? '+' : ''}$reward',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: reward > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '🎯 下一步: ${StateCalculator.getActionDescription(selectedAction)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '→ 进入: ${allLevels[nextLevelIndex].name}',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '已完成: ${_session.getRecordCount() + 1}/$maxRecords',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // 返回主页
                },
                child: const Text('放弃'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _proceedWithQLearning(nextLevelIndex);
                },
                child: const Text('继续'),
              ),
            ],
          ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// 根据Q-Learning更新并进行下一步
  Future<void> _proceedWithQLearning(int nextLevelIndex) async {
    final timeTaken =
        gameDuration.inSeconds + (gameDuration.inMilliseconds % 1000) / 1000.0;

    // 计算最终奖励：基础奖励 + 动作奖励
    int finalReward = reward;

    // 升级时额外奖励
    if (selectedAction == 2 && nextLevelIndex > currentLevelIndex) {
      finalReward += 2; // 升级奖励（更强化升级）
    }
    // 降级时惩罚（防止AI一直停留在简单关卡）
    else if (selectedAction == 0 && nextLevelIndex < currentLevelIndex) {
      finalReward -= 1; // 降级惩罚
    }

    // 记录此次训练数据
    _session.addLevelRecord(
      levelId: currentLevel.id,
      time: timeTaken,
      errorCount: levelErrorCount,
      state: currentState,
      action: selectedAction,
      reward: finalReward, // 使用最终奖励
    );

    // 更新Q值（Q-Learning更新）
    // 先加载当前Q值
    final currentQValue = _qTable['$currentState-$selectedAction'] ?? 0.0;

    // 计算下一个状态（如果能加载下一关的话）
    final nextLevel = allLevels[nextLevelIndex];
    final alpha = 0.1; // 学习率
    final gamma = 0.9; // 折扣因子

    // 假设下一个状态需要在下一关完成后才能知道，这里我们用一个临时的估计
    // 为了简化，我们可以用当前状态作为参考，计算最大Q值
    double maxNextQ = -double.infinity;
    for (int action = 0; action < 3; action++) {
      final nextQValue = _qTable['$currentState-$action'] ?? 0.0;
      if (nextQValue > maxNextQ) {
        maxNextQ = nextQValue;
      }
    }

    // Q-Learning公式: Q(s,a) = Q(s,a) + α * (r + γ * max(Q(s',a')) - Q(s,a))
    final newQValue =
        currentQValue +
        alpha * (finalReward + gamma * maxNextQ - currentQValue);

    // 更新Q表
    await DBService.updateQValue(currentState, selectedAction, newQValue);
    _qTable['$currentState-$selectedAction'] = newQValue;

    // 检查是否完成10个关卡
    if (_session.getRecordCount() >= maxRecords) {
      // 衰减ε
      _session.epsilon = max(0.01, _session.epsilon - 0.01);

      _saveAndReturn();
      return;
    }

    // 加载下一关
    _loadLevel(nextLevelIndex);
  }

  /// 保存到数据库并返回
  Future<void> _saveAndReturn() async {
    final success = await DBService.saveQLearningTrainingRecord(
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
            title: const Text('🎉 训练完成！'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('完成关卡数: ${_session.getRecordCount()}'),
                  const SizedBox(height: 8),
                  Text('总用时: ${_session.totalTime.toStringAsFixed(2)} 秒'),
                  const SizedBox(height: 8),
                  Text('总错误数: ${_session.totalErrorCount} 次'),
                  const SizedBox(height: 8),
                  Text('最终ε: ${_session.epsilon.toStringAsFixed(4)}'),
                  const SizedBox(height: 16),
                  const Text(
                    '关卡序列:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_session.levelIds.join(' → ')),
                ],
              ),
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
            content: const Text('训练记录保存失败，请检查网络连接'),
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
        appBar: AppBar(title: const Text('Q-Learning 挑战')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Q-Learning 训练 - ${_session.getRecordCount()}/10'),
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
                        '${gameDuration.inSeconds}s',
                        style: const TextStyle(
                          fontSize: 18,
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
                      if (nextItem > 1) {
                        final clickedPart = originalSequence.substring(
                          0,
                          nextItem - 1,
                        );
                        if (clickedPart.contains(item)) {
                          tileColor = const Color(0xFFAFE6D3);
                        }
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
