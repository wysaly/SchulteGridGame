import 'package:flutter/material.dart';

// import 'package:http/http.dart' as http; // 如需真实请求再取消注释
// import 'dart:convert';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    String account = _accountController.text.trim();
    String password = _passwordController.text;

    // ======= 模拟数据测试，无需后端 =======
    if (account.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账号和密码不能为空')));
      return;
    }
    // 假设账号为user，密码为123456时登录成功
    if (account == 'user' && password == '123456') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录成功（模拟）')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录失败（模拟）：账号或密码错误')));
    }
    // ======= 结束模拟 =======

    // 下面真实请求代码可以先注释掉
    /*
  var url = Uri.parse('http://localhost:8080/api/login');
  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'account': account, 'password': password}),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('登录成功')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('登录失败：${response.body}')),
    );
  }
  */
  }

  void _forgotPassword() {
    // 跳转到忘记密码页面
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
    );
  }

  void _register() {
    // 跳转到注册页面
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注意力小游戏'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: '邮箱或手机号',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _login, child: const Text('登录')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _forgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(
                      255,
                      62,
                      132,
                      229,
                    ), // 文字颜色
                  ),
                  child: const Text('忘记密码？'),
                ),
                TextButton(
                  onPressed: _register,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(
                      255,
                      62,
                      107,
                      229,
                    ), // 文字颜色
                  ),
                  child: const Text('注册账号'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
