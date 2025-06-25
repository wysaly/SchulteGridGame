import 'package:flutter/material.dart';
import 'database_service.dart';

enum GameMode { training, challenge }

class GamePage extends StatefulWidget {
  final GameMode gameMode;
  final int initialLevel;

  const GamePage({Key? key, required this.gameMode, required this.initialLevel}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late Future<List<Map<String, dynamic>>> gameData;

  @override
  void initState() {
    super.initState();
    // 从数据库获取游戏数据
    gameData = fetchGameData();
  }

  Future<List<Map<String, dynamic>>> fetchGameData() async {
    final dbService = DatabaseService(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '123456',
      database: 'schulte_grid_game',
    );
    return await dbService.fetchGameData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gameMode == GameMode.training ? '训练模式' : '挑战模式')), 
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: gameData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('没有游戏数据可显示'));
          } else {
            // 显示游戏数据
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(data[index]['description']),
                  subtitle: Text('难度: ${data[index]['difficulty']}'),
                );
              },
            );
          }
        },
      ),
    );
  }
} 