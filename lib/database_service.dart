import 'package:mysql1/mysql1.dart';

class DatabaseService {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  DatabaseService({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: database,
    );
    return await MySqlConnection.connect(settings);
  }

  Future<List<Map<String, dynamic>>> fetchGameData() async {
    final conn = await connect();
    var results = await conn.query('SELECT * FROM game_data'); // 假设有一个名为 game_data 的表
    List<Map<String, dynamic>> data = [];
    for (var row in results) {
      data.add(row.fields);
    }
    await conn.close();
    return data;
  }
} 