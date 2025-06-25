import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'sound_manager.dart';

enum GameMode { training, challenge }

class GamePage extends StatefulWidget {
  final GameMode gameMode;
  final int? initialLevel;

  const GamePage({super.key, required this.gameMode, this.initialLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late List<int> numbers;
  late int gridSize;
  late int currentLevel;
  int nextNumber = 1;
  bool isGameActive = false;
  bool isPunishmentActive = false;
  DateTime? startTime;
  Duration gameDuration = Duration.zero;
  Timer? gameTimer;
  Duration totalTime = Duration.zero;
  static int bestTime = 0; // 使用静态变量存储最佳成绩
  final SoundManager _soundManager = SoundManager();
  bool _isInitialized = false;
  int _countdown = 3;
  bool _isCountingDown = false;
  int? _lastClickedWronglyNumber; // 存储最近一次错误点击的数字
  Timer? _countdownTimer; // 新增：倒计时计时器

  @override
  void initState() {
    super.initState();
    currentLevel = widget.initialLevel ?? 1;
    gridSize = currentLevel + 1;
    numbers = List.generate(gridSize * gridSize, (index) => index + 1);
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final bool soundInitialized = await _soundManager.initialize(); // 获取音效初始化结果
    if (mounted) {
      setState(() {
        _isInitialized = soundInitialized; // 根据音效初始化结果设置 _isInitialized
        if (_isInitialized) {
          // 只有在音效初始化成功时才开始新游戏
          startNewGame();
        }
      });
    }
  }

  void startNewGame() {
    if (!_isInitialized) return;

    setState(() {
      isGameActive = false; // 暂停游戏，等待倒计时
      _isCountingDown = true; // 开始倒计时
      _countdown = 3; // 重置倒计时
      gridSize = currentLevel + 1;
      numbers = List.generate(gridSize * gridSize, (index) => index + 1);
      numbers.shuffle(Random());
      nextNumber = 1;
      gameDuration = Duration.zero;
      gameTimer?.cancel(); // 取消任何之前的游戏计时器
      _countdownTimer?.cancel(); // 确保取消之前的倒计时计时器
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 将计时器赋值给 _countdownTimer
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel(); // 确保计时器在这里被取消
        if (mounted) {
          setState(() {
            _isCountingDown = false;
            isGameActive = true; // 倒计时结束后开始游戏
            startTime = DateTime.now();
            gameTimer = Timer.periodic(const Duration(milliseconds: 100), (
              timer,
            ) {
              if (isGameActive && mounted) {
                setState(() {
                  gameDuration = DateTime.now().difference(
                    startTime!,
                  ); // 更新游戏用时
                });
              }
            });
          });
        }
      }
    });
  }

  void saveBestTime(Duration time) {
    if (bestTime == 0 || time.inSeconds < bestTime) {
      bestTime = time.inSeconds;
    }
  }

  int getBestTime() {
    return bestTime;
  }

  void handleNumberClick(int number) {
    if (!isGameActive || isPunishmentActive) return;

    if (number == nextNumber) {
      _soundManager.playClick();
      setState(() {
        nextNumber++;
        if (nextNumber > gridSize * gridSize) {
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
        isPunishmentActive = true; // 游戏逻辑暂停1秒
        _lastClickedWronglyNumber = number; // 设置被错误点击的数字
      });
      // 短暂显示红色反馈
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _lastClickedWronglyNumber = null; // 清除错误点击的数字
          });
        }
      });
      // 1秒后解除游戏逻辑暂停
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            isPunishmentActive = false;
          });
        }
      });
    }
  }

  void showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('恭喜！'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 无论训练模式还是挑战模式，都显示当前关卡用时
                Text('你完成了第 $currentLevel 关！\n用时: ${gameDuration.inSeconds} 秒'),
                if (widget.gameMode == GameMode.challenge && currentLevel == 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '历史最佳成绩: ${getBestTime()} 秒\n当前总用时: ${totalTime.inSeconds} 秒',
                    ),
                  ),
              ],
            ),
            actions: [
              // 训练模式下同时显示"选择关卡"和"下一关"
              if (widget.gameMode == GameMode.training ||
                  widget.gameMode == GameMode.challenge) // 两个模式都需要"下一关"按钮
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
                      // 完成所有关卡
                      if (widget.gameMode == GameMode.challenge) {
                        saveBestTime(totalTime);
                      }
                      showGameOverDialog();
                    }
                  },
                  child: const Text('下一关'),
                ),
              if (widget.gameMode == GameMode.training) // 训练模式还需要"选择关卡"按钮
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭对话框
                    Navigator.of(context).pop(); // 返回到 LevelSelectionPage
                  },
                  child: const Text('选择关卡'),
                ),
            ],
          ),
    );
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('游戏完成！'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('恭喜你完成了所有关卡！'),
                if (widget.gameMode == GameMode.challenge)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '历史最佳成绩: ${getBestTime()} 秒\n当前总用时: ${totalTime.inSeconds} 秒',
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    setState(() {
                      currentLevel = 1;
                      totalTime = Duration.zero;
                    });
                    startNewGame();
                  }
                },
                child: const Text('重新开始'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF66D7B4), // 设置背景颜色为图片中的绿色
      appBar: AppBar(
        title: Text(widget.gameMode == GameMode.training ? '训练模式' : '挑战模式'),
        actions: [
          if (widget.gameMode == GameMode.training)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                // 在训练模式下，这里不应该再有选择关卡的按钮
                // 因为我们已经有了独立的 LevelSelectionPage
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0, top: 16.0), // 调整间距
                child: Text(
                  '请按顺序点击以下数字',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ), // 调整字体颜色和大小
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '时间:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ), // 调整字体颜色
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white, // 时间框背景颜色为白色
                        border: Border.all(color: Colors.white), // 边框颜色为白色
                        borderRadius: BorderRadius.circular(8), // 圆角
                      ),
                      child: Text(
                        '${gameDuration.inSeconds}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ), // 调整字体颜色
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.gameMode == GameMode.challenge) // 添加总用时显示
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
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    final number = numbers[index];

                    Color tileColor = const Color(0xFF5ED8CC); // 默认方块颜色（更深的绿色）

                    if (_lastClickedWronglyNumber == number) {
                      tileColor = Colors.red; // 错误点击显示红色
                    } else if (number < nextNumber) {
                      // 如果数字小于下一个要点击的数字，则表示已正确点击
                      tileColor = const Color(0xFFAFE6D3); // 正确点击显示绿色（更浅的绿色）
                    }

                    return GestureDetector(
                      onTap: () => handleNumberClick(number),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(15), // 调整圆角大小
                        ),
                        child: Center(
                          child: Text(
                            number.toString(),
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

  @override
  void dispose() {
    gameTimer?.cancel();
    _countdownTimer?.cancel(); // 明确取消倒计时计时器
    _soundManager.dispose();
    super.dispose();
  }
}
