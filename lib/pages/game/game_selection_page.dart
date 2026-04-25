import 'package:flutter/material.dart';

import 'fixed_challenge_page.dart';
import 'level_training_page.dart';
import 'qlearnig_page.dart';
import 'threshold_challenge_page.dart';

class GameSelectionPage extends StatelessWidget {
  const GameSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('游戏模式'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 自由训练
              _buildModeButton(
                context,
                icon: Icons.school,
                title: '自由训练',
                subtitle: '随意选择关卡，测试基准时间',
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LevelTrainingPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // 固定挑战
              _buildModeButton(
                context,
                icon: Icons.gamepad,
                title: '固定挑战',
                subtitle: '按顺序挑战1-10关，记录成绩',
                color: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FixedChallengePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // 阈值挑战
              _buildModeButton(
                context,
                icon: Icons.trending_up,
                title: '阈值挑战',
                subtitle: '自适应调整难度，匹配你的水平',
                color: Colors.purple,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThresholdChallengePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Q-Learning挑战
              _buildModeButton(
                context,
                icon: Icons.psychology,
                title: 'Q-Learning挑战',
                subtitle: 'AI学习你的风格，精准推荐难度',
                color: Colors.teal,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QLearnigPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.4),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
