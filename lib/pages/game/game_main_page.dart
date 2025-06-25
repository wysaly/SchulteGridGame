// 游戏主页面，切换数字关卡和古诗词关卡
import 'package:flutter/material.dart';

import 'number_level_page.dart';
import 'poem_level_page.dart';

class GameMainPage extends StatefulWidget {
  @override
  State<GameMainPage> createState() => _GameMainPageState();
}

class _GameMainPageState extends State<GameMainPage> {
  int _tabIndex = 0;
  final List<Widget> _tabs = [NumberLevelPage(), PoemLevelPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('游戏关卡')),
      body: _tabs[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.filter_1), label: '数字关卡'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '古诗词关卡'),
        ],
      ),
    );
  }
}
