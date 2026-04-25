/// Q-Learning 训练会话
class QLearnigSession {
  final int userId;

  // 训练数据
  final List<int> levelIds = [];
  final List<double> times = [];
  final List<int> errorCounts = [];
  final List<int> states = [];
  final List<int> actions = [];
  final List<int> rewards = [];

  double totalTime = 0.0;
  int totalErrorCount = 0;
  double epsilon = 0.1; // 初始探索率

  QLearnigSession({required this.userId});

  /// 添加一个关卡的训练记录
  void addLevelRecord({
    required int levelId,
    required double time,
    required int errorCount,
    required int state,
    required int action,
    required int reward,
  }) {
    levelIds.add(levelId);
    times.add(_roundToTwoDecimals(time));
    errorCounts.add(errorCount);
    states.add(state);
    actions.add(action);
    rewards.add(reward);

    totalTime += times.last;
    totalErrorCount += errorCount;
  }

  /// 精确到两位小数
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// 获取记录数
  int getRecordCount() => levelIds.length;

  /// 转换为数据库插入所需的Map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'level_ids': levelIds.join(','),
      'times': times.map((t) => t.toStringAsFixed(2)).toList().join(','),
      'error_counts': errorCounts.join(','),
      'states': states.join(','),
      'actions': actions.join(','),
      'rewards': rewards.join(','),
      'total_time': _roundToTwoDecimals(totalTime),
      'total_error_count': totalErrorCount,
      'epsilon': epsilon,
    };
  }
}

/// 状态计算工具
class StateCalculator {
  /// 计算时间等级（0=快, 1=中, 2=慢）
  static int getTimeLevel(double timeSpent, int standardTime) {
    if (timeSpent <= 0.95 * standardTime) {
      return 0; // 快
    } else if (timeSpent <= 1.5 * standardTime) {
      return 1; // 中
    } else {
      return 2; // 慢
    }
  }

  /// 计算错误等级（0=低, 1=中, 2=高）
  static int getErrorLevel(int errorCount, int gridSize) {
    final n = gridSize * gridSize;
    final errorRate = errorCount / n;

    if (errorRate < 0.15) {
      return 0; // 低
    } else if (errorRate < 0.25) {
      return 1; // 中
    } else {
      return 2; // 高
    }
  }

  /// 计算状态（0-8）
  static int getState(
    double timeSpent,
    int standardTime,
    int errorCount,
    int gridSize,
  ) {
    final timeLevel = getTimeLevel(timeSpent, standardTime);
    final errorLevel = getErrorLevel(errorCount, gridSize);
    return timeLevel * 3 + errorLevel;
  }

  /// 计算奖励
  /// 快速且低错误 -> 升级，给予高奖励
  /// 表现适中 -> 维持难度，给予正奖励
  /// 太难或太慢 -> 降低难度，给予低奖励
  static int getReward(int state) {
    // state = timeLevel * 3 + errorLevel
    // timeLevel: 0=快, 1=中, 2=慢
    // errorLevel: 0=低, 1=中, 2=高

    // state 0 = (快, 低错误) -> 理想状态，需要升级 -> +2
    if (state == 0) return 2;

    // state 1 = (快, 中错误) -> 还可以，鼓励升级 -> +1
    if (state == 1) return 1;

    // state 3 = (中, 低错误) -> 表现刚好 -> +1
    // state 4 = (中, 中错误) -> 表现刚好 -> +1
    if (state == 3 || state == 4) return 1;

    // state 7 = (慢, 中错误) -> 有些吃力，给予正奖励但不鼓励 -> 0
    if (state == 7) return 0;

    // state 2 = (快, 高错误) -> 太难 -> -1
    // state 5 = (中, 高错误) -> 有难度 -> -1
    // state 6 = (慢, 低错误) -> 太简单且太慢？不对，这不太合理 -> -1
    // state 8 = (慢, 高错误) -> 太难 -> -2
    if (state == 2 || state == 5 || state == 6) return -1;
    if (state == 8) return -2;

    return 0;
  }

  /// 获取状态的描述文本
  static String getStateDescription(int state) {
    final timeLevel = state ~/ 3;
    final errorLevel = state % 3;

    final timeDesc = ['快', '中', '慢'][timeLevel];
    final errorDesc = ['低错误', '中错误', '高错误'][errorLevel];

    return '$timeDesc - $errorDesc';
  }

  /// 获取动作的描述文本
  static String getActionDescription(int action) {
    return ['降低难度', '保持难度', '升高难度'][action];
  }
}
