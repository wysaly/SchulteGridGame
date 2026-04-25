import 'package:flutter/material.dart';

import 'db_connect_user.dart';
import 'home_page.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool isLogin = true;
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题图标
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 标题
                  const Text(
                    '忘记密码',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 分隔线
                  Container(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  // 提示文本
                  const Text(
                    '请联系管理员处理',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // 微信号
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wechat,
                          color: const Color(0xFF09B981),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'WeChat: 15572636950',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 确定按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '确定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _onSubmit() async {
    String account = _accountController.text.trim();
    String password = _passwordController.text;
    String confirm = _confirmController.text;

    if (account.isEmpty || password.isEmpty || (!isLogin && confirm.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写所有必填项')));
      return;
    }

    if (!isLogin && password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }

    if (isLogin) {
      bool accountExists = await _checkAccountExists(account);
      if (!accountExists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('账号不存在')));
        return;
      }

      bool passwordCorrect = await _verifyPassword(account, password);
      if (passwordCorrect) {
        // 登录成功后获取用户ID
        final userId = await _getUserId(account);
        if (userId != null) {
          DBService.currentUserId = userId; // 保存用户ID到DBService
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码错误')));
      }
    } else {
      bool accountExists = await _checkAccountExists(account);
      if (accountExists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('账号已存在')));
        return;
      }

      bool success = await _registerUser(account, password);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('注册成功，请登录')));
        setState(() => isLogin = true);
        _passwordController.clear();
        _confirmController.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('注册失败，请重试')));
      }
    }
  }

  // 检查账号是否存在
  Future<bool> _checkAccountExists(String account) async {
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      print("❌ 数据库未连接");
      return false;
    }

    try {
      print("🔍 查询账号: $account");
      final results = await conn.execute(
        'SELECT id FROM users WHERE account = :account',
        {'account': account},
      );
      return results.rows.isNotEmpty;
    } catch (e) {
      print("❌ 查询账号失败: $e");
      return false;
    }
  }

  // 获取用户ID
  Future<int?> _getUserId(String account) async {
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      print("❌ 数据库未连接");
      return null;
    }

    try {
      final results = await conn.execute(
        'SELECT id FROM users WHERE account = :account',
        {'account': account},
      );
      if (results.rows.isNotEmpty) {
        final id = results.rows.first.typedColAt(0);
        if (id is int) {
          return id;
        } else if (id is String) {
          return int.tryParse(id);
        }
        return null;
      }
      return null;
    } catch (e) {
      print("❌ 获取用户ID失败: $e");
      return null;
    }
  }

  // 验证密码是否正确
  Future<bool> _verifyPassword(String account, String password) async {
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      print("❌ 数据库未连接");
      return false;
    }

    try {
      print(
        "🔍 验证密码: account=$account, password=${password.isNotEmpty ? '***' : '空'}",
      );
      final results = await conn.execute(
        'SELECT id FROM users WHERE account = :account AND password = :password',
        {'account': account, 'password': password},
      );
      return results.rows.isNotEmpty;
    } catch (e) {
      print("❌ 验证密码失败: $e");
      return false;
    }
  }

  // 注册新用户
  Future<bool> _registerUser(String account, String password) async {
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      print("❌ 数据库未连接");
      return false;
    }

    try {
      final result = await conn.execute(
        'INSERT INTO users (account, password) VALUES (:account, :password)',
        {'account': account, 'password': password},
      );
      return result.affectedRows > BigInt.from(0);
    } catch (e) {
      print("❌ 注册用户失败: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // logo
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                '舒尔特方格游戏',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 登录/注册切换
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() => isLogin = true);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  isLogin
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('登录'),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() => isLogin = false);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  !isLogin
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('注册'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 账号
                      TextField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          labelText: '账号',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 密码
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
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        // 确认密码
                        TextField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: '确认密码',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirm,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('忘记密码？'),
                          ),
                          // 右侧占位
                          const SizedBox(width: 1),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('完成'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
