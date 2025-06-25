import 'package:flutter/material.dart';
import 'db_connect_test.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});
  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    String phone = _phoneController.text.trim();
    String answer = _answerController.text.trim();
    String newPassword = _newPasswordController.text;

    if (phone.isEmpty || answer.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写完整信息')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final conn = await DBService.connectIfNotConnected();
      if (conn == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据库连接失败')));
        return;
      }
      var result = await conn.execute(
        "SELECT * FROM users WHERE phone = :phone AND security_answer = :answer",
        {"phone": phone, "answer": answer},
      );
      if (result.rows.isNotEmpty) {
        await conn.execute(
          "UPDATE users SET password = :password WHERE phone = :phone",
          {"password": newPassword, "phone": phone},
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码重置成功')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密保答案错误')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重置失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: '密保答案',
                prefixIcon: Icon(Icons.question_answer),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: '新密码',
                prefixIcon: Icon(Icons.lock_reset),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('重置密码'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
