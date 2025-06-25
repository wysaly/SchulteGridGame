import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_connect_test.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _securityAnswerController =
      TextEditingController();

  int _selectedQuestion = 1;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _questions = [
    {'id': 1, 'text': '你的出生地是？'},
    {'id': 2, 'text': '你的母亲名字是？'},
    {'id': 3, 'text': '你最喜欢的动物是？'},
  ];

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _register() async {
    String account = _accountController.text.trim();
    String password = _passwordController.text;
    String confirm = _confirmController.text;
    String securityAnswer = _securityAnswerController.text.trim();

    if (account.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        securityAnswer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写完整信息')));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两次密码不一致')));
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
      // 检查手机号是否已存在
      var check = await conn.execute(
        "SELECT COUNT(*) as cnt FROM users WHERE phone = :phone",
        {"phone": account},
      );
      if (check.rows.first.colByName('cnt') != '0') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('手机号已存在')));
        return;
      }
      // 插入新用户
      await conn.execute(
        "INSERT INTO users (phone, password, security_question, security_answer) VALUES (:phone, :password, :question, :answer)",
        {
          "phone": account,
          "password": password,
          "question": _selectedQuestion,
          "answer": securityAnswer,
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('注册成功')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('注册失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedQuestion,
                decoration: const InputDecoration(
                  labelText: '密保问题',
                  border: OutlineInputBorder(),
                ),
                items:
                    _questions
                        .map(
                          (q) => DropdownMenuItem<int>(
                            value: q['id'],
                            child: Text(q['text']),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQuestion = value ?? 1;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _securityAnswerController,
                decoration: const InputDecoration(
                  labelText: '密保答案',
                  prefixIcon: Icon(Icons.question_answer),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('注册'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
