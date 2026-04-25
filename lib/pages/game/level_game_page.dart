import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_level.dart';
import '../db_connect_user.dart';
import 'number/sound_manager.dart' as NumberSoundManager;
import 'poem/sound_manager.dart' as PoemSoundManager;

class LevelGamePage extends StatefulWidget {
  final GameLevel level;
  final bool isTraining; // 是否为训练模式（不保存数据库）
  final Function(int levelTime, int errorCount)? onLevelComplete; // 关卡完成回调

  const LevelGamePage({
    super.key,
    required this.level,
    this.isTraining = true,
    this.onLevelComplete,
  });

  @override
  State<LevelGamePage> createState() => _LevelGamePageState();
}

class _LevelGamePageState extends State<LevelGamePage> {
  late List<dynamic> gridItems; // 可以是数字或字符
  late int gridSize;
  late String originalSequence; // 原始顺序（用于古诗/句子的匹配）
  late String sourceDetail; // 来源信息（如《思乡》李白）
  late Set<int> correctlyClickedIndices; // 已正确点击的索引
  int nextItem = 1; // 下一个应该点击的项
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
  int _errorCount = 0; // 添加错误计数

  // 音效管理（根据游戏类型选择）
  late dynamic _soundManager;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    gridSize = widget.level.gridSize;
    gridItems = []; // 初始化为空列表，防止LateInitializationError
    originalSequence = '';
    sourceDetail = '';
    correctlyClickedIndices = {};
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // 根据游戏类型初始化音效和内容
      if (widget.level.type == GameType.number ||
          widget.level.type == GameType.numberFlipped) {
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
    switch (widget.level.type) {
      case GameType.number:
      case GameType.numberFlipped:
        gridItems = List.generate(gridSize * gridSize, (i) => i + 1);
        gridItems.shuffle(Random());
        originalSequence = '';
        sourceDetail = '';
        break;

      case GameType.poem:
        // gridSize=3：五言律诗（id 1-30）
        // gridSize=4：七言律诗（id 31-60）
        Map<String, String>? poemData;
        if (widget.level.gridSize == 3) {
          poemData = await DBService.getRandomSentence(1, 30);
        } else if (widget.level.gridSize == 4) {
          poemData = await DBService.getRandomSentence(31, 60);
        }

        if (poemData != null && poemData['text']!.isNotEmpty) {
          // 保存原始顺序和来源信息
          originalSequence = poemData['text']!;
          sourceDetail = poemData['detail'] ?? '';
          // 分割为字符列表，不进行任何过滤
          gridItems = originalSequence.split('');
        } else {
          gridItems = [];
          originalSequence = '';
          sourceDetail = '';
        }
        break;

      case GameType.sentence:
        // 关卡8：25字句子（id 61-79）
        Map<String, String>? sentenceData = await DBService.getRandomSentence(
          61,
          79,
        );
        if (sentenceData != null && sentenceData['text']!.isNotEmpty) {
          // 保存原始顺序和来源信息
          originalSequence = sentenceData['text']!;
          sourceDetail = sentenceData['detail'] ?? '';
          // 分割为字符列表，不进行任何过滤
          gridItems = originalSequence.split('');
        } else {
          gridItems = [];
          originalSequence = '';
          sourceDetail = '';
        }
        break;
    }

    // 对于非数字游戏，打乱字符顺序
    if (widget.level.type == GameType.poem ||
        widget.level.type == GameType.sentence) {
      gridItems.shuffle(Random());
    }
  }

  void startNewGame() async {
    await _soundManager.reset();

    setState(() {
      isGameActive = false;
      _isCountingDown = true;
      _countdown = 3;
      nextItem = 1;
      correctlyClickedIndices.clear();
      gameDuration = Duration.zero;
      _errorCount = 0; // 重置错误计数
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

    if (widget.level.type == GameType.number ||
        widget.level.type == GameType.numberFlipped) {
      // 数字游戏：点击的数字应该等于nextItem
      isCorrect = clickedItem == nextItem;
    } else if (widget.level.type == GameType.poem ||
        widget.level.type == GameType.sentence) {
      // 古诗/句子游戏：点击的字符应该等于originalSequence中的下一个字符
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
        // 判定游戏是否完成
        bool isComplete = false;
        if (widget.level.type == GameType.number ||
            widget.level.type == GameType.numberFlipped) {
          isComplete = nextItem > gridSize * gridSize;
        } else if (widget.level.type == GameType.poem ||
            widget.level.type == GameType.sentence) {
          isComplete = nextItem > originalSequence.length;
        }

        if (isComplete) {
          isGameActive = false;
          gameTimer?.cancel();
          showGameCompleteDialog();
        }
      });
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        isPunishmentActive = true;
        _lastClickedWronglyItem = clickedItem;
        _errorCount++; // 增加错误计数
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
    final T = widget.level.standardTime;
    final timeSpent =
        gameDuration.inSeconds + gameDuration.inMilliseconds / 1000.0;

    if (timeSpent <= 0.8 * T && _errorCount == 0) {
      return '你比我强'; // Easy
    } else if (timeSpent <= 1.5 * T && _errorCount <= 2) {
      return '和我差不多嘛'; // Good
    } else {
      return '竟然比我都慢'; // Hard
    }
  }

  void showGameCompleteDialog() {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    Future.delayed(const Duration(milliseconds: 100), () {
      _soundManager.playSuccess();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // 挑战模式的按钮
        if (widget.onLevelComplete != null) {
          return AlertDialog(
            title: const Text('恭喜！'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('用时: ${gameDuration.inSeconds} 秒'),
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
                  // 放弃挑战，返回 FixedChallengePage
                  Navigator.of(context).pop();
                },
                child: const Text('放弃'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 调用回调，FixedChallengePage 处理下一关
                  widget.onLevelComplete!(gameDuration.inSeconds, _errorCount);
                },
                child: const Text('下一关'),
              ),
            ],
          );
        }

        // 训练模式的按钮
        return AlertDialog(
          title: const Text('恭喜！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('用时: ${gameDuration.inSeconds} 秒'),
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
                startNewGame();
              },
              child: const Text('再来一次'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('返回'),
            ),
          ],
        );
      },
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _countdownTimer?.cancel();
    _soundManager.dispose();
    correctlyClickedIndices.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.level.name)),
      backgroundColor: const Color(0xFF66D7B4),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.level.type == GameType.number ||
                          widget.level.type == GameType.numberFlipped
                      ? '请按顺序点击数字'
                      : '请按顺序点击文字',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 显示目标诗句和来源（仅古诗和句子）
              if (widget.level.type == GameType.poem ||
                  widget.level.type == GameType.sentence)
                if (originalSequence.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      '目标诗句：$originalSequence',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (sourceDetail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        '来源：$sourceDetail',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
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
                    } else if (correctlyClickedIndices.contains(index)) {
                      // 已正确点击的方块显示灰色
                      tileColor = const Color(0xFFAFE6D3);
                    } else if (widget.level.type == GameType.number ||
                        widget.level.type == GameType.numberFlipped) {
                      // 只有数字游戏才能比较已点击的项
                      if (item is int && item < nextItem) {
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
                              widget.level.isFlipped
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
