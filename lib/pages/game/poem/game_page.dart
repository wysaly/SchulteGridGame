import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../db_connect_user.dart';
import '../number/game_page.dart' as NumberMode; // 添加前缀导入
import '../number/sound_manager.dart';

enum GameMode { training, challenge }

class GamePage extends StatefulWidget {
  final GameMode gameMode;
  final int? initialLevel;

  const GamePage({super.key, required this.gameMode, this.initialLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late List<String> poemChars; // 古诗字符列表
  late int gridSize;
  late int currentLevel;
  String? currentPoem; // 当前显示的古诗
  String? originalPoem; // 原始古诗(无标点)
  int nextChar = 1; // 下一个应点击的字符索引
  bool isGameActive = false;
  bool isPunishmentActive = false;
  DateTime? startTime;
  Duration gameDuration = Duration.zero;
  Timer? gameTimer;
  Duration totalTime = Duration.zero;
  static int bestTime = 0;
  String? _lastClickedWronglyChar; // 最近一次错误点击的字符
  int? _currentCorrectIndex; // 当前正确的字符索引
  final Set<int> _correctlyClickedIndices = {}; // 已正确点击的字符索引
  final SoundManager _soundManager = SoundManager();
  bool _isInitialized = false;
  int _countdown = 3;
  bool _isCountingDown = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.initialLevel ?? 1;
    gridSize = currentLevel + 1;

    // 初始化poemChars为空列表以避免LateInitializationError
    poemChars = [];
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      print("❌ 数据库未连接");
      // 如果数据库连接失败，使用默认古诗
      currentPoem = '床前明月光，疑是地上霜。'; // 默认古诗
      originalPoem = currentPoem!.replaceAll(
        RegExp(r'[\W_]+', unicode: true),
        '',
      );

      // 初始化音效
      final bool soundInitialized = await _soundManager.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = soundInitialized;
          // 确保即使数据库连接失败也能正确初始化网格
          poemChars = _generatePoemGrid(originalPoem!);
          if (_isInitialized) {
            startNewGame();
          }
        });
      }
      return;
    }

    try {
      // 查询game_management数据库中的poems表
      final results = await conn.execute(
        'SELECT text FROM poems ORDER BY RAND() LIMIT 1', // 已移除数据库名前缀
      );

      if (results.rows.isNotEmpty) {
        final text = results.rows.first.typedColAt(0);
        if (text is String) {
          currentPoem = text;
          originalPoem = currentPoem!.replaceAll(
            RegExp(r'[\W_]+', unicode: true),
            '',
          );
        }
      }
      // 如果没有找到古诗，使用默认值
      if (currentPoem == null) {
        currentPoem = '床前明月光，疑是地上霜。'; // 默认古诗
        originalPoem = currentPoem!.replaceAll(
          RegExp(r'[\W_]+', unicode: true),
          '',
        );
      }

      // 确保poemChars被正确初始化
      poemChars = _generatePoemGrid(originalPoem!);

      // 初始化音效
      final bool soundInitialized = await _soundManager.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = soundInitialized;
          if (_isInitialized) {
            startNewGame();
          }
        });
      }
    } catch (e) {
      print("❌ 获取古诗失败: $e");
      // 如果数据库查询失败，使用默认古诗并确保poemChars被正确初始化
      currentPoem = '床前明月光，疑是地上霜。'; // 默认古诗
      originalPoem = currentPoem!.replaceAll(
        RegExp(r'[\W_]+', unicode: true),
        '',
      );
      poemChars = _generatePoemGrid(originalPoem!);

      // 初始化音效
      final bool soundInitialized = await _soundManager.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = soundInitialized;
          if (_isInitialized) {
            startNewGame();
          }
        });
      }
    }
  }

  void startNewGame() {
    if (!_isInitialized || currentPoem == null) return;

    setState(() {
      isGameActive = false;
      _isCountingDown = true;
      _countdown = 3;
      gridSize = currentLevel + 1;

      // 确保originalPoem不为空
      originalPoem = currentPoem; // 保留原始古诗包括标点

      // 重新生成古诗字符网格
      _correctlyClickedIndices.clear();
      poemChars = _generatePoemGrid(
        originalPoem!.replaceAll(RegExp(r'[\s]'), ''),
      );
      nextChar = 1;

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

  List<String> _generatePoemGrid(String poem) {
    // 将古诗拆分为字符列表
    List<String> chars = poem.split('');

    // 确保网格大小正确
    final int expectedSize = _getGridSizeFromLevel(currentLevel);
    if (chars.length < expectedSize) {
      // 如果字符不够，添加空字符
      chars.addAll(List.filled(expectedSize - chars.length, ''));
    } else if (chars.length > expectedSize) {
      // 如果字符太多，截断
      chars = chars.sublist(0, expectedSize);
    }

    // 打乱字符顺序增加游戏性
    chars.shuffle(Random());

    return chars;
  }

  int _getGridSizeFromLevel(int level) {
    // 古诗模式固定使用4x4(16格)布局
    return 16;
  }

  void handleCharClick(int index) {
    if (!isGameActive || isPunishmentActive) return;

    final clickedChar = poemChars[index];
    final expectedChar = originalPoem![nextChar - 1];

    if (clickedChar == expectedChar) {
      _soundManager.playClick();
      setState(() {
        _currentCorrectIndex = index;
        _correctlyClickedIndices.add(index);
        nextChar++;
        if (nextChar > originalPoem!.length) {
          isGameActive = false;
          gameTimer?.cancel();
          if (widget.gameMode == GameMode.challenge) {
            totalTime += gameDuration;
          }
          _soundManager.playSuccess();
          showGameCompleteDialog();
        }
      });
    } else {
      setState(() {
        isPunishmentActive = true;
        _lastClickedWronglyChar = clickedChar;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _lastClickedWronglyChar = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF66D7B4),
      appBar: AppBar(
        title: const Text('训练模式', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (originalPoem != null && originalPoem!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: Text(
                    '目标诗句: $originalPoem',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '请按顺序点击以下文字',
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
              // 倒计时显示在时间显示位置
              if (_isCountingDown)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              if (!_isCountingDown)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '用时:',
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
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${gameDuration.inSeconds}秒',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.gameMode == NumberMode.GameMode.challenge)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '总用时:',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${totalTime.inSeconds}秒',
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
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 固定4列
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    itemCount: poemChars.length,
                    itemBuilder: (context, index) {
                      final char = poemChars[index];

                      Color tileColor = const Color(0xFF5ED8CC);
                      if (_lastClickedWronglyChar == char) {
                        tileColor = Colors.red;
                      } else if (_correctlyClickedIndices.contains(index)) {
                        tileColor = const Color(0xFFAFE6D3);
                      } else if (index == _currentCorrectIndex) {
                        tileColor = const Color(0xFFAFE6D3);
                      }

                      return GestureDetector(
                        onTap: () => handleCharClick(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              char,
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
              ),
              if (!_isCountingDown &&
                  widget.gameMode == NumberMode.GameMode.training)
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
                          border: Border.all(color: Colors.white),
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
              if (widget.gameMode == NumberMode.GameMode.challenge &&
                  !_isCountingDown)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('总用时:', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${totalTime.inSeconds}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isCountingDown) // 倒计时覆盖层
            Container(
              color: Colors.black54, // 半透明黑色背景
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

  void showGameCompleteDialog() {
    // 挑战模式保存记录到数据库
    if (widget.gameMode == GameMode.challenge) {
      DBService.insertChallengeRecord(
        gameDuration.inSeconds,
        1, // 1表示古诗模式
      ).catchError((e) {
        print('保存挑战记录失败: $e');
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('恭喜！'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你完成了第 $currentLevel 关！'),
                const SizedBox(height: 8),
                Text('用时: ${gameDuration.inSeconds}秒'),
                if (widget.gameMode == NumberMode.GameMode.challenge &&
                    currentLevel == 4) ...[
                  const SizedBox(height: 16),
                  Text('历史最佳成绩: ${bestTime}秒'),
                  const SizedBox(height: 4),
                  Text('当前总用时: ${totalTime.inSeconds}秒'),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('返回'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (widget.gameMode == NumberMode.GameMode.training ||
                widget.gameMode == NumberMode.GameMode.challenge)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (currentLevel < 4) {
                    if (mounted) {
                      setState(() {
                        currentLevel++;
                      });
                    }
                    startNewGame();
                  } else {
                    if (widget.gameMode == NumberMode.GameMode.challenge) {
                      bestTime = min(bestTime, totalTime.inSeconds);
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('下一关'),
              ),
            if (widget.gameMode == NumberMode.GameMode.training)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('选择关卡'),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _countdownTimer?.cancel();
    _soundManager.dispose();
    super.dispose();
  }
}
