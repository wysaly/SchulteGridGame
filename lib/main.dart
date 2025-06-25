import 'package:flutter/material.dart';
import 'pages/crud_page.dart';

/// 应用入口
void main() {
  runApp(const MyApp());
}

/// 主应用组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '诗歌后台管理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CrudPage(),
    );
  }
}
