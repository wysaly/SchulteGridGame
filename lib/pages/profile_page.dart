import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nickname = '未设置昵称';

  void _editNickname() async {
    final controller = TextEditingController(text: _nickname);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('修改昵称'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '请输入新昵称'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.of(context).pop(controller.text.trim());
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => _nickname = newName);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('昵称已更新为: $newName')));
    }
  }

  void _showChallengeRecords() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('挑战记录'),
            content: const Text('这里展示你的挑战记录（静态内容占位）。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 头像
            CircleAvatar(
              radius: 48,
              backgroundImage: const AssetImage(
                'D:/flutter_workplace/SchulteGridGame/schultegridgame/assets/images/logo.png',
              ), // 请确保有此图片
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 24),
            // 昵称
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _nickname,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editNickname,
                  tooltip: '修改昵称',
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 挑战记录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('挑战记录', style: TextStyle(fontSize: 18)),
                onPressed: _showChallengeRecords,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
