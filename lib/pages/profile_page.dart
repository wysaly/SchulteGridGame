import 'package:flutter/material.dart';

import './challenge_records_page.dart';
import './db_connect_user.dart';
import './login_page.dart';

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

  void _showChallengeRecords() async {
    int? selectedType;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('选择挑战类型'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => selectedType = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType == 0 ? Colors.blue : null,
                      ),
                      child: const Text('数字方格挑战记录'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => selectedType = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType == 1 ? Colors.blue : null,
                      ),
                      child: const Text('古诗方格挑战记录'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedType != null) {
                        Navigator.pop(context);
                        _showRecordsByType(selectedType!);
                      }
                    },
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showRecordsByType(int challengeType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeRecordsPage(challengeType: challengeType),
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
                'assets/images/logo.png',
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
            const SizedBox(height: 16),
            // 退出登录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('退出登录', style: TextStyle(fontSize: 18)),
                onPressed: () {
                  DBService.currentUserId = null;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginRegisterPage(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
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
