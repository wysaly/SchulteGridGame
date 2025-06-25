/// 挑战记录模型类
class ChallengeRecord {
  final int recordId;
  final int userId;
  final int completionTime;
  final int challengeType;
  final DateTime insertTime;

  ChallengeRecord({
    required this.recordId,
    required this.userId,
    required this.completionTime,
    required this.challengeType,
    required this.insertTime,
  });

  /// 从Map构造ChallengeRecord对象
  factory ChallengeRecord.fromMap(Map<String, dynamic> map) {
    return ChallengeRecord(
      recordId: int.tryParse(map['record_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(map['user_id']?.toString() ?? '0') ?? 0,
      completionTime:
          int.tryParse(map['completion_time']?.toString() ?? '0') ?? 0,
      challengeType:
          int.tryParse(map['challenge_type']?.toString() ?? '0') ?? 0,
      insertTime: DateTime.parse(
        map['insert_time']?.toString() ?? DateTime.now().toString(),
      ),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'user_id': userId,
      'completion_time': completionTime,
      'challenge_type': challengeType,
      'insert_time': insertTime.toIso8601String(),
    };
  }
}
