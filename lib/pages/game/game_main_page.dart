import 'package:flutter/material.dart';

import 'number/mode_selection_page.dart' as NumberMode;
import 'poem/mode_selection_page.dart' as PoemMode;

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
                  // 导航到数字模式选择页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NumberMode.ModeSelectionPage(),
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
                  // 导航到古诗模式选择页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PoemMode.ModeSelectionPage(),
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
