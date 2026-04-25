import 'package:flutter/material.dart';

import '../../models/game_level.dart';
import '../game/level_game_page.dart';

class LevelTrainingPage extends StatelessWidget {
  const LevelTrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自由训练')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allLevels.length,
        itemBuilder: (context, index) {
          final level = allLevels[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${level.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                level.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(level.description ?? ''),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => LevelGamePage(
                          level: level,
                          isTraining: true, // 标记为训练模式
                        ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
