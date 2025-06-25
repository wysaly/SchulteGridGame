import 'package:mysql1/mysql1.dart';

class DataService {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  DataService({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  Future<List<Map<String, dynamic>>> fetchGameData() async {
    final settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: database,
    );
    final conn = await MySqlConnection.connect(settings);
    var results = await conn.query('SELECT * FROM game_data');
    List<Map<String, dynamic>> data = [];
    for (var row in results) {
      data.add(row.fields);
    }
    await conn.close();
    return data;
  }
} 