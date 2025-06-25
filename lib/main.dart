import 'package:flutter/material.dart';
import 'pages/login_register/login_page.dart';
import 'pages/login_register/register_page.dart';
import 'pages/login_register/forgot_password_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '注意力小游戏',
      theme: ThemeData(primarySwatch: Colors.blue),
      // 设置初始页面为登录页
      home: LoginPage(),
      // 可选：配置命名路由，方便跳转
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/forgot_password': (context) => ForgetPage(),
      },
    );
  }
}
