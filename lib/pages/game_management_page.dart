import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/challenge_record.dart';
import '../models/poem.dart';
import '../services/db_service.dart';

/// 游戏管理页面 - 支持多表CRUD操作
class GameManagementPage extends StatefulWidget {
  const GameManagementPage({Key? key}) : super(key: key);

  @override
  State<GameManagementPage> createState() => _GameManagementPageState();
}

class _GameManagementPageState extends State<GameManagementPage> {
  // 当前选择的表
  String _selectedTable = 'users';

  // 数据列表
  List<dynamic> _items = [];

  // 控制器
  final Map<String, TextEditingController> _addControllers = {};
  final Map<int, Map<String, TextEditingController>> _editControllers = {};
  final Set<int> _editingIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化添加控制器
    _initAddControllers();
    _loadItems();
  }

  void _initAddControllers() {
    _addControllers.clear();
    switch (_selectedTable) {
      case 'users':
        _addControllers['account'] = TextEditingController();
        _addControllers['password'] = TextEditingController();
        break;
      case 'challenge_records':
        _addControllers['user_id'] = TextEditingController();
        _addControllers['completion_time'] = TextEditingController();
        _addControllers['challenge_type'] = TextEditingController();
        break;
      case 'poems':
        _addControllers['text'] = TextEditingController();
        break;
    }
  }

  /// 加载当前表的数据
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    _editControllers.clear();
    _editingIds.clear();

    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await conn.execute("SELECT * FROM $_selectedTable");
      setState(() {
        _items =
            results.rows.map((row) {
              final map = row.assoc();
              switch (_selectedTable) {
                case 'users':
                  return User.fromMap(map);
                case 'challenge_records':
                  return ChallengeRecord.fromMap(map);
                case 'poems':
                  return Poem.fromMap(map);
                default:
                  return map;
              }
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      _showError("加载失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 显示错误消息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 显示成功消息
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// 添加用户
  Future<void> _addUser() async {
    final account = _addControllers['account']?.text;
    final password = _addControllers['password']?.text;

    if (account == null ||
        account.isEmpty ||
        password == null ||
        password.isEmpty) {
      _showError("请输入账号和密码");
      return;
    }

    setState(() => _isLoading = true);
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await conn.execute(
        "INSERT INTO users (account, password) VALUES (:account, :password)",
        {"account": account, "password": password},
      );
      _addControllers['account']?.clear();
      _addControllers['password']?.clear();
      await _loadItems();
      _showSuccess("用户添加成功");
    } catch (e) {
      _showError("添加失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 构建编辑字段
  Widget _buildEditFields(int id, BuildContext context) {
    final controllers = _editControllers[id];
    if (controllers == null) return const SizedBox();

    return Column(
      children:
          controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// 构建项目列表
  Widget _buildItemList() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isEditing = _editingIds.contains(
          item is User
              ? item.id
              : item is ChallengeRecord
              ? item.recordId
              : item is Poem
              ? item.id
              : 0,
        );

        final id =
            item is User
                ? item.id
                : item is ChallengeRecord
                ? item.recordId
                : item is Poem
                ? item.id
                : 0;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing)
                    _buildEditFields(id, context)
                  else ...[
                    Text(
                      _getItemTitle(item),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getItemSubtitle(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isEditing ? Icons.save : Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed:
                              () =>
                                  isEditing
                                      ? _saveItem(item)
                                      : _startEditing(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () => _deleteItem(item),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getItemTitle(dynamic item) {
    if (item is User) return item.account;
    if (item is ChallengeRecord) return "记录ID: ${item.recordId}";
    if (item is Poem) return item.text;
    return item.toString();
  }

  String _getItemSubtitle(dynamic item) {
    if (item is User) return "ID: ${item.id}";
    if (item is ChallengeRecord)
      return "用户ID: ${item.userId}, 耗时: ${item.completionTime}s";
    if (item is Poem) return "ID: ${item.id}";
    return "";
  }

  /// 开始编辑项目
  void _startEditing(dynamic item) {
    setState(() {
      // 清除现有编辑状态
      for (var id in _editingIds) {
        _editControllers[id]?.values.forEach((c) => c.dispose());
      }
      _editingIds.clear();
      _editControllers.clear();

      // 设置新编辑状态
      if (item is User) {
        _editingIds.add(item.id);
        _editControllers[item.id] = {
          'account': TextEditingController(text: item.account),
          'password': TextEditingController(text: item.password),
        };
      } else if (item is ChallengeRecord) {
        _editingIds.add(item.recordId);
        _editControllers[item.recordId] = {
          'user_id': TextEditingController(text: item.userId.toString()),
          'completion_time': TextEditingController(
            text: item.completionTime.toString(),
          ),
          'challenge_type': TextEditingController(
            text: item.challengeType.toString(),
          ),
        };
      } else if (item is Poem) {
        _editingIds.add(item.id);
        _editControllers[item.id] = {
          'text': TextEditingController(text: item.text),
        };
      }
    });
  }

  /// 保存编辑的项目
  Future<void> _saveItem(dynamic item) async {
    final id =
        item is User
            ? item.id
            : item is ChallengeRecord
            ? item.recordId
            : item is Poem
            ? item.id
            : 0;
    final controllers = _editControllers[id];
    if (controllers == null) return;

    setState(() => _isLoading = true);
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      switch (_selectedTable) {
        case 'users':
          await conn.execute(
            "UPDATE users SET account = :account, password = :password WHERE id = :id",
            {
              "account": controllers['account']?.text ?? '',
              "password": controllers['password']?.text ?? '',
              "id": id.toString(),
            },
          );
          break;
        case 'challenge_records':
          await conn.execute(
            "UPDATE challenge_records SET user_id = :user_id, completion_time = :completion_time, challenge_type = :challenge_type WHERE record_id = :record_id",
            {
              "user_id": controllers['user_id']?.text ?? '0',
              "completion_time": controllers['completion_time']?.text ?? '0',
              "challenge_type": controllers['challenge_type']?.text ?? '0',
              "record_id": id.toString(),
            },
          );
          break;
        case 'poems':
          await conn.execute("UPDATE poems SET text = :text WHERE id = :id", {
            "text": controllers['text']?.text ?? '',
            "id": id.toString(),
          });
          break;
      }

      setState(() {
        _editingIds.remove(id);
        controllers.values.forEach((c) => c.dispose());
        _editControllers.remove(id);
      });
      await _loadItems();
      _showSuccess("更新成功");
    } catch (e) {
      _showError("更新失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 删除项目
  Future<void> _deleteItem(dynamic item) async {
    final id =
        item is User
            ? item.id
            : item is ChallengeRecord
            ? item.recordId
            : item is Poem
            ? item.id
            : 0;
    final idField = item is ChallengeRecord ? 'record_id' : 'id';

    setState(() => _isLoading = true);
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await conn.execute("DELETE FROM $_selectedTable WHERE $idField = :id", {
        "id": id.toString(),
      });
      await _loadItems();
      _showSuccess("删除成功");
    } catch (e) {
      _showError("删除失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 构建挑战记录添加表单
  Widget _buildChallengeAddForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _addControllers['user_id'],
            decoration: const InputDecoration(labelText: "用户ID"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _addControllers['completion_time'],
            decoration: const InputDecoration(labelText: "完成时间(秒)"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _addControllers['challenge_type'],
            decoration: const InputDecoration(labelText: "挑战类型(0或1)"),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: _addChallengeRecord,
            child: const Text("添加记录"),
          ),
        ],
      ),
    );
  }

  /// 构建诗词添加表单
  Widget _buildPoemAddForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addControllers['text'],
              decoration: const InputDecoration(labelText: "诗词内容"),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: _addPoem, child: const Text("添加")),
        ],
      ),
    );
  }

  /// 添加挑战记录
  Future<void> _addChallengeRecord() async {
    final userId = _addControllers['user_id']?.text;
    final completionTime = _addControllers['completion_time']?.text;
    final challengeType = _addControllers['challenge_type']?.text;

    if (userId == null ||
        userId.isEmpty ||
        completionTime == null ||
        completionTime.isEmpty ||
        challengeType == null ||
        challengeType.isEmpty) {
      _showError("请填写所有字段");
      return;
    }

    setState(() => _isLoading = true);
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await conn.execute(
        "INSERT INTO challenge_records (user_id, completion_time, challenge_type) VALUES (:user_id, :completion_time, :challenge_type)",
        {
          "user_id": userId,
          "completion_time": completionTime,
          "challenge_type": challengeType,
        },
      );
      _addControllers['user_id']?.clear();
      _addControllers['completion_time']?.clear();
      _addControllers['challenge_type']?.clear();
      await _loadItems();
      _showSuccess("记录添加成功");
    } catch (e) {
      _showError("添加失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 添加诗词
  Future<void> _addPoem() async {
    final text = _addControllers['text']?.text;
    if (text == null || text.isEmpty) {
      _showError("请输入诗词内容");
      return;
    }

    setState(() => _isLoading = true);
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 查询当前最大id
      final maxIdResult = await conn.execute(
        "SELECT MAX(id) as max_id FROM poems",
      );
      int newId = 1;
      if (maxIdResult.rows.isNotEmpty) {
        final row = maxIdResult.rows.first.assoc();
        final maxIdStr = row['max_id']?.toString();
        if (maxIdStr != null && maxIdStr.isNotEmpty) {
          final maxId = int.tryParse(maxIdStr) ?? 0;
          newId = maxId + 1;
        }
      }
      await conn.execute("INSERT INTO poems (id, text) VALUES (:id, :text)", {
        "id": newId.toString(),
        "text": text,
      });
      _addControllers['text']?.clear();
      await _loadItems();
      _showSuccess("诗词添加成功");
    } catch (e) {
      _showError("添加失败: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '游戏数据管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _selectedTable,
              dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
              items: const [
                DropdownMenuItem(value: 'users', child: Text('用户管理')),
                DropdownMenuItem(
                  value: 'challenge_records',
                  child: Text('挑战记录'),
                ),
                DropdownMenuItem(value: 'poems', child: Text('诗词管理')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTable = value;
                    _initAddControllers();
                  });
                  _loadItems();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildAddForm(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Card(elevation: 2, child: _buildItemList()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    // 根据表显示不同的添加表单
    switch (_selectedTable) {
      case 'users':
        return _buildUserAddForm();
      case 'challenge_records':
        return _buildChallengeAddForm();
      case 'poems':
        return _buildPoemAddForm();
      default:
        return Container();
    }
  }

  Widget _buildUserAddForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _addControllers['account'],
            decoration: const InputDecoration(labelText: "账号"),
          ),
          TextField(
            controller: _addControllers['password'],
            decoration: const InputDecoration(labelText: "密码"),
            obscureText: true,
          ),
          ElevatedButton(onPressed: _addUser, child: const Text("添加用户")),
        ],
      ),
    );
  }

  // 其他构建方法...

  @override
  void dispose() {
    // 清理所有控制器
    for (var controller in _addControllers.values) {
      controller.dispose();
    }
    for (var controllers in _editControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}
