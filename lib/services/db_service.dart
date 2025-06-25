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

  /// 获取数据库连接
  /// 如果连接不存在或已断开，则创建新连接
  static Future<MySQLConnection?> connectIfNotConnected() async {
    if (_conn != null && await isConnected(_conn!)) {
      print("✅ 使用已有数据库连接");
      return _conn;
    }

    try {
      _conn = await MySQLConnection.createConnection(
        host: _config['host'],
        port: _config['port'],
        userName: _config['userName'],
        password: _config['password'],
        databaseName: _config['databaseName'],
        secure: _config['secure'],
      );

      await _conn!.connect();
      print("✅ 数据库已连接");
      return _conn;
    } catch (e) {
      print("❌ 数据库连接失败: $e");
      return null;
    }
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
}
