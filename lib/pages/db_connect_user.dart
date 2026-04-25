import 'package:mysql_client/mysql_client.dart';

/// 数据库服务类
/// 负责管理数据库连接的生命周期和基础操作
class DBService {
  static MySQLConnection? _conn;

  /// 数据库连接配置
  static final Map<String, dynamic> _config = {
    'host': "gateway01.ap-southeast-1.prod.aws.tidbcloud.com",
    'port': 4000,
    'userName': "dinUYBHKXo6XmCm.root",
    'password': "40SCheAfyxOJjfNc",
    'databaseName': "game_management",
    'secure': true,
  };

  /// 获取数据库连接(带重试机制)
  /// 如果连接不存在或已断开，则创建新连接
  static Future<MySQLConnection?> connectIfNotConnected({
    int retryCount = 2,
  }) async {
    // 检查现有连接是否可用
    if (_conn != null) {
      try {
        if (await isConnected(_conn!)) {
          print("✅ 使用已有数据库连接");
          return _conn;
        }
      } catch (e) {
        print("⚠️ 连接检查失败: $e");
        _conn = null;
      }
    }

    // 带重试的新建连接逻辑
    for (int i = 0; i <= retryCount; i++) {
      try {
        print("🔄 尝试连接数据库 (尝试 ${i + 1}/$retryCount)");
        _conn = await MySQLConnection.createConnection(
          host: _config['host'],
          port: _config['port'],
          userName: _config['userName'],
          password: _config['password'],
          databaseName: _config['databaseName'],
          secure: _config['secure'],
        );

        await _conn!.connect();
        await _conn!.execute("SET NAMES utf8mb4");
        print("✅ 数据库连接成功 (字符集: utf8mb4)");
        return _conn;
      } catch (e) {
        print("❌ 连接失败: $e");
        if (i == retryCount) {
          print("⚠️ 达到最大重试次数");
          return null;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  /// 检查连接是否有效
  static Future<bool> isConnected(MySQLConnection conn) async {
    try {
      final result = await conn.execute("SELECT 1");
      return result.affectedRows > BigInt.from(0);
    } catch (e) {
      return false;
    }
  }

  /// 关闭数据库连接
  static int? currentUserId; // 当前登录用户ID

  static Future<void> insertChallengeRecord(
    int timeTaken,
    int challengeType, // 0=数字网格, 1=其他类型
  ) async {
    if (currentUserId == null) return;

    final conn = await connectIfNotConnected();
    if (conn == null) return;

    try {
      final now = DateTime.now();
      await conn.execute(
        'INSERT INTO challenge_records (user_id, completion_time, challenge_type, insert_time) '
        'VALUES (:user_id, :completion_time, :challenge_type, :insert_time)',
        {
          'user_id': currentUserId,
          'completion_time': timeTaken,
          'challenge_type': challengeType,
          'insert_time': now,
        },
      );
    } finally {
      await conn.close();
    }
  }

  /// 随机获取一首古诗
  static Future<String?> getRandomPoem() async {
    final conn = await connectIfNotConnected();
    if (conn == null) return null;

    try {
      final result = await conn.execute(
        'SELECT text FROM poems ORDER BY RAND() LIMIT 1',
      );

      if (result.rows.isNotEmpty) {
        return result.rows.first.typedColByName('text') as String;
      }
      return null;
    } catch (e) {
      print('获取古诗失败: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  /// 根据范围随机获取一句古诗或句子及其详情
  static Future<Map<String, String>?> getRandomSentence(
    int minId,
    int maxId,
  ) async {
    final conn = await connectIfNotConnected();
    if (conn == null) return null;

    try {
      final result = await conn.execute(
        'SELECT text, detail FROM sentences WHERE id BETWEEN :minId AND :maxId ORDER BY RAND() LIMIT 1',
        {'minId': minId, 'maxId': maxId},
      );

      if (result.rows.isNotEmpty) {
        final text = result.rows.first.typedColByName('text') as String?;
        final detail = result.rows.first.typedColByName('detail') as String?;
        return {'text': text ?? '', 'detail': detail ?? ''};
      }
      return null;
    } catch (e) {
      print('获取句子失败: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  /// 保存固定挑战记录到fix_challenge_records表
  static Future<bool> saveFixedChallengeRecord(
    Map<String, dynamic> recordData,
  ) async {
    if (currentUserId == null) return false;

    final conn = await connectIfNotConnected();
    if (conn == null) return false;

    try {
      // 添加当前时间戳（使用本地时间）
      final now = DateTime.now();
      recordData['insert_time'] = now;

      await conn.execute(
        'INSERT INTO fix_challenge_records ('
        'user_id, level_ids, times, error_counts, total_time, total_error_count, insert_time) '
        'VALUES (:user_id, :level_ids, :times, :error_counts, :total_time, :total_error_count, :insert_time)',
        recordData,
      );
      print("✅ 固定挑战记录保存成功");
      return true;
    } catch (e) {
      print("❌ 保存固定挑战记录失败: $e");
      return false;
    } finally {
      await conn.close();
    }
  }

  static Future<void> closeConnection() async {
    if (_conn != null) {
      try {
        await _conn!.close();
        print("🔌 数据库连接已关闭");
      } catch (e) {
        print("⚠️ 关闭连接时出错: $e");
      } finally {
        _conn = null;
      }
    }
  }

  /// 获取全局Q表（所有状态-动作对的Q值）
  static Future<Map<String, double>> getQTable() async {
    final conn = await connectIfNotConnected();
    if (conn == null) return {};

    try {
      final result = await conn.execute(
        'SELECT state, action, q_value FROM q_learning_q_table',
      );

      final qTable = <String, double>{};
      for (final row in result.rows) {
        final state = row.typedColByName('state') as int;
        final action = row.typedColByName('action') as int;
        final qValue = row.typedColByName('q_value') as double;
        qTable['$state-$action'] = qValue;
      }

      return qTable;
    } catch (e) {
      print('获取Q表失败: $e');
      return {};
    } finally {
      await conn.close();
    }
  }

  /// 更新全局Q表中的一个Q值
  static Future<bool> updateQValue(
    int state,
    int action,
    double newQValue,
  ) async {
    final conn = await connectIfNotConnected();
    if (conn == null) return false;

    try {
      await conn.execute(
        'INSERT INTO q_learning_q_table (state, action, q_value, update_count) '
        'VALUES (:state, :action, :q_value, 1) '
        'ON DUPLICATE KEY UPDATE '
        'q_value = :q_value, update_count = update_count + 1',
        {'state': state, 'action': action, 'q_value': newQValue},
      );
      return true;
    } catch (e) {
      print('更新Q值失败: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  /// 保存Q-Learning训练记录
  static Future<bool> saveQLearningTrainingRecord(
    Map<String, dynamic> recordData,
  ) async {
    if (currentUserId == null) return false;

    final conn = await connectIfNotConnected();
    if (conn == null) return false;

    try {
      // 添加当前时间戳（使用本地时间）
      final now = DateTime.now();
      recordData['insert_time'] = now;

      await conn.execute(
        'INSERT INTO qlearning_training_records ('
        'user_id, level_ids, times, error_counts, states, actions, rewards, '
        'total_time, total_error_count, epsilon, insert_time) '
        'VALUES ('
        ':user_id, :level_ids, :times, :error_counts, :states, :actions, :rewards, '
        ':total_time, :total_error_count, :epsilon, :insert_time)',
        recordData,
      );
      print('✅ Q-Learning训练记录保存成功');
      return true;
    } catch (e) {
      print('❌ 保存Q-Learning训练记录失败: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  /// 保存阈值挑战记录到threshold_challenge_records表
  static Future<bool> saveThresholdChallengeRecord(
    Map<String, dynamic> recordData,
  ) async {
    if (currentUserId == null) return false;

    final conn = await connectIfNotConnected();
    if (conn == null) return false;

    try {
      // 添加当前时间戳（使用本地时间）
      final now = DateTime.now();
      recordData['insert_time'] = now;

      await conn.execute(
        'INSERT INTO threshold_challenge_records ('
        'user_id, level_ids, times, error_counts, total_time, total_error_count, insert_time) '
        'VALUES (:user_id, :level_ids, :times, :error_counts, :total_time, :total_error_count, :insert_time)',
        recordData,
      );
      print("✅ 阈值挑战记录保存成功");
      return true;
    } catch (e) {
      print("❌ 保存阈值挑战记录失败: $e");
      return false;
    } finally {
      await conn.close();
    }
  }

  /// 获取用户挑战记录
  static Future<List<Map<String, dynamic>>> getChallengeRecords({
    int? challengeType,
  }) async {
    if (currentUserId == null) return [];

    final conn = await connectIfNotConnected();
    if (conn == null) return [];

    try {
      final whereClause =
          challengeType != null
              ? 'WHERE user_id = :user_id AND challenge_type = :challenge_type'
              : 'WHERE user_id = :user_id';

      final params =
          challengeType != null
              ? {'user_id': currentUserId, 'challenge_type': challengeType}
              : {'user_id': currentUserId};

      final result = await conn.execute(
        'SELECT insert_time, challenge_type, completion_time '
        'FROM challenge_records '
        '$whereClause '
        'ORDER BY insert_time DESC',
        params,
      );

      return result.rows.map((row) {
        return {
          'timestamp': row.typedColByName('insert_time'),
          'type': row.typedColByName('challenge_type'),
          'time': row.typedColByName('completion_time'),
        };
      }).toList();
    } catch (e) {
      print('查询挑战记录失败: $e');
      return [];
    } finally {
      await conn.close();
    }
  }
}
