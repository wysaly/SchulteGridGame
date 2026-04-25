/// 阈值挑战会话，记录经历的关卡及其成绩
class ThresholdChallengeSession {
  final int userId;

  // 记录经历的关卡id、时间、错误数
  final List<int> levelIds = [];
  final List<double> times = []; // 精确到两位小数
  final List<int> errorCounts = [];

  double totalTime = 0.0;
  int totalErrorCount = 0;

  ThresholdChallengeSession({required this.userId});

  /// 添加一个关卡的成绩
  void addLevelRecord(int levelId, double time, int errorCount) {
    levelIds.add(levelId);
    times.add(_roundToTwoDecimals(time));
    errorCounts.add(errorCount);
    totalTime += times.last;
    totalErrorCount += errorCount;
  }

  /// 将小数精确到两位
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// 获取关卡记录的总数
  int getRecordCount() => levelIds.length;

  /// 转换为数据库插入所需的Map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'level_ids': levelIds.join(','),
      'times': times.map((t) => t.toStringAsFixed(2)).toList().join(','),
      'error_counts': errorCounts.join(','),
      'total_time': _roundToTwoDecimals(totalTime),
      'total_error_count': totalErrorCount,
    };
  }
}
