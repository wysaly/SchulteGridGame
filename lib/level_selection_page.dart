import 'package:flutter/material.dart';
import 'game_page.dart'; // 导入 GamePage 用于导航

class LevelSelectionPage extends StatelessWidget {
  const LevelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择关卡')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 16, // 调整按钮之间的间距
              runSpacing: 16,
              alignment: WrapAlignment.center, // 使按钮居中显示
              children: List.generate(
                4, // 假设有4个关卡，根据你的设计图调整
                (index) => SizedBox(
                  width: 80, // 设置按钮宽度
                  height: 80, // 设置按钮高度，使其呈方形
                  child: ElevatedButton(
                    onPressed: () {
                      // 导航到 GamePage 并传入选择的关卡号
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GamePage(
                            gameMode: GameMode.training,
                            initialLevel: index + 1,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // 按钮背景颜色为白色
                      shape: RoundedRectangleBorder(
                        // 圆角
                        borderRadius: BorderRadius.circular(12), // 调整圆角大小
                      ),
                      elevation: 2, // 添加一些阴影效果
                    ),
                    child: Text(
                      '${index + 1}', // 只显示数字
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ), // 调整字体颜色和大小
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
