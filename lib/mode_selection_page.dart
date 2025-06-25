import 'package:flutter/material.dart';
import 'game_page.dart';
import 'level_selection_page.dart';

class ModeSelectionPage extends StatelessWidget {
  const ModeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF66D7B4), // 设置背景颜色为图片中的绿色
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GamePage(gameMode: GameMode.challenge, initialLevel: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, // 挑战模式按钮颜色
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 25,
                ), // 调整按钮大小
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ), // 圆角
              ),
              child: const Text(
                '挑战',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ), // 调整字体颜色和大小
              ),
            ),
            const SizedBox(height: 30), // 按钮间距
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const LevelSelectionPage(), // 导航到独立的关卡选择页面
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5ED8CC), // 训练模式按钮颜色
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 25,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '训练',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ), // 调整字体颜色和大小
              ),
            ),
          ],
        ),
      ),
    );
  }
}
