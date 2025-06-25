import 'package:flutter/material.dart';

import 'number/mode_selection_page.dart'; // 导入模式选择页面

class GameMainPage extends StatelessWidget {
  const GameMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('游戏关卡')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModeSelectionPage(),
                    ),
                  );
                },
                child: const Text('数字方格', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModeSelectionPage(),
                    ),
                  );
                },
                child: const Text('古诗词方格', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
