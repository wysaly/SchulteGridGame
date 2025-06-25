# SchulteGridGame - 注意力训练游戏

## 项目简介
一个基于Flutter开发的注意力训练游戏应用，包含数字和古诗挑战两种游戏模式，旨在帮助用户提升专注力和反应速度。

## 主要功能
- 数字网格挑战：快速寻找并点击数字
- 古诗挑战：记忆并还原古诗
- 用户系统：登录、个人资料管理
- 挑战记录：保存和查看历史成绩
- 难度分级：多种难度级别选择

## 技术栈
- Flutter 3.x
- Dart 3.x
- MySQL (TiDB Cloud)
- 状态管理：Provider

## 安装与运行
1. 确保已安装Flutter SDK
2. 克隆本项目：
   ```bash
   git clone https://github.com/your-repo/SchulteGridGame.git
   ```
3. 安装依赖：
   ```bash
   flutter pub get
   ```
4. 运行项目：
   ```bash
   flutter run
   ```

## 数据库配置
1. 创建TiDB Cloud账号
2. 导入`database.sql`初始化表结构
3. 在`lib/pages/db_connect_user.dart`中配置连接信息

## 项目结构
```
lib/
├── main.dart          # 应用入口
├── pages/
│   ├── game/          # 游戏相关页面
│   ├── login_page.dart # 登录页面
│   └── profile_page.dart # 个人中心
└── utils/             # 工具类
```

## 贡献指南
欢迎提交Pull Request，请确保：
- 代码符合Dart风格指南
- 新功能附带测试用例
- 更新相关文档

## 分支简介
由于小组分工完成
本项目有多个分支，项目完成之前的总分支为dev，
其他分支作部分功能推送（通过分支名能推断功能）
项目完成后推送到main分支

## 致谢
感谢组员的付出与努力，虽然有时努力没有成果，但最终会是好的答案！
