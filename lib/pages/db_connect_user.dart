import 'package:mysql_client/mysql_client.dart';

/// 数据库服务类
/// 负责管理数据库连接的生命周期和基础操作
class DBService {
  static MySQLConnection? _conn;

  /// 数据库连接配置
  static final Map<String, dynamic> _config = {
    'host': "gateway01.ap-southeast-1.prod.aws.tidbcloud.com",
    'port': 4000,
    'userName': "3JGJ6GdKHkJKyUS.root",
    'password': "KAYqzxI9gUP8BoTe",
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
      await conn.execute(
        'INSERT INTO challenge_records (user_id, completion_time, challenge_type) '
        'VALUES (:user_id, :completion_time, :challenge_type)',
        {
          'user_id': currentUserId,
          'completion_time': timeTaken,
          'challenge_type': challengeType,
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
