/// 固定挑战会话，缓存10个关卡的数据
class ChallengeSession {
  final int userId;

  // 缓存每个关卡的时间和错误数 (key: levelId, value: [time(double), errorCount(int)])
  final Map<int, List<dynamic>> levelData = {};

  double totalTime = 0.0;
  int totalErrorCount = 0;

  ChallengeSession({required this.userId});

  /// 更新某个关卡的数据
  void updateLevel(int levelId, double time, int errorCount) {
    final roundedTime = (time * 100).round() / 100.0; // 精确到两位小数
    levelData[levelId] = [roundedTime, errorCount];
    totalTime += roundedTime;
    totalErrorCount += errorCount;
  }

  /// 检查是否完成所有10关
  bool isComplete() => levelData.length == 10;

  /// 获取关卡的用时
  double getLevelTime(int levelId) =>
      (levelData[levelId]?[0] as double?) ?? 0.0;

  /// 获取关卡的错误数
  int getLevelErrorCount(int levelId) => (levelData[levelId]?[1] as int?) ?? 0;

  /// 转换为数据库插入所需的Map（使用逗号分割的字符串格式）
  Map<String, dynamic> toMap() {
    // 提取所有关卡ID（1-10）
    final levelIds = List.generate(10, (i) => i + 1);

    // 提取所有关卡的时间数据，精确到两位小数
    final times = levelIds
        .map((id) {
          final time = getLevelTime(id);
          return (time * 100).round() / 100.0;
        })
        .join(',');

    // 提取所有关卡的错误数
    final errorCounts = levelIds
        .map((id) => getLevelErrorCount(id).toString())
        .join(',');

    return {
      'user_id': userId,
      'level_ids': levelIds.join(','),
      'times': times,
      'error_counts': errorCounts,
      'total_time': (totalTime * 100).round() / 100.0, // 精确到两位小数
      'total_error_count': totalErrorCount,
    };
  }
}
