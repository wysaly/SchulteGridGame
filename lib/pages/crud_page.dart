import 'package:flutter/material.dart';
import '../models/poem.dart';
import '../services/db_service.dart';

/// 诗词管理页面
class CrudPage extends StatefulWidget {
  const CrudPage({Key? key}) : super(key: key);

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  List<Poem> _poems = [];
  final TextEditingController _addController = TextEditingController();
  final Map<int, TextEditingController> _editControllers = {};
  final Set<int> _editingIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPoems();
  }

  /// 加载诗词列表
  Future<void> _loadPoems() async {
    setState(() => _isLoading = true);

    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await conn.execute("SELECT * FROM poems");
      setState(() {
        _poems = results.rows.map((row) => Poem.fromMap(row.assoc())).toList();
        _isLoading = false;
      });
    } catch (e) {
      _showError("加载失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 添加诗词
  Future<void> _addPoem() async {
    if (_addController.text.isEmpty) {
      _showError("请输入诗句");
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
      // 查询当前最大 id
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
        "text": _addController.text,
      });
      _addController.clear();
      await _loadPoems();
      _showSuccess("添加成功");
    } catch (e) {
      _showError("添加失败: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 开始编辑诗词
  void _startEditing(Poem poem) {
    setState(() {
      // 只允许一个正在编辑
      for (var id in _editingIds) {
        _editControllers[id]?.dispose();
      }
      _editingIds.clear();
      _editControllers.clear();

      _editingIds.add(poem.id);
      _editControllers[poem.id] = TextEditingController(text: poem.text);
    });
  }

  /// 保存编辑的诗词
  Future<void> _saveEditing(int id) async {
    final controller = _editControllers[id];
    if (controller == null || controller.text.isEmpty) {
      _showError("请输入有效的诗句内容");
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
      await conn.execute("UPDATE poems SET text = :text WHERE id = :id", {
        "text": controller.text,
        "id": id.toString(),
      });
      setState(() {
        _editingIds.remove(id);
        // 释放并移除controller，防止内存泄漏和重复创建
        _editControllers[id]?.dispose();
        _editControllers.remove(id);
      });
      await _loadPoems();
      _showSuccess("更新成功");
    } catch (e) {
      _showError("更新失败: $e");
      setState(() => _isLoading = false);
    }
  }

  // 可选：如果你有取消编辑的功能，也要释放controller
  void _cancelEditing(int id) {
    setState(() {
      _editingIds.remove(id);
      _editControllers[id]?.dispose();
      _editControllers.remove(id);
    });
  }

  /// 删除诗词
  Future<void> _deletePoem(int id) async {
    setState(() => _isLoading = true);
    final conn = await DBService.connectIfNotConnected();
    if (conn == null) {
      _showError("数据库连接失败");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await conn.execute("DELETE FROM poems WHERE id = :id", {
        "id": id.toString(),
      });
      await _loadPoems();
      _showSuccess("删除成功");
    } catch (e) {
      _showError("删除失败: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('诗词管理'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPoems),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 添加诗词表单
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addController,
                            decoration: const InputDecoration(
                              labelText: "新增诗句",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addPoem,
                          child: const Text("添加"),
                        ),
                      ],
                    ),
                  ),
                  // 诗词列表
                  Expanded(
                    child: ListView.builder(
                      itemCount: _poems.length,
                      itemBuilder: (context, index) {
                        final poem = _poems[index];
                        final isEditing = _editingIds.contains(poem.id);

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(poem.id.toString()),
                          ),
                          title:
                              isEditing
                                  ? TextField(
                                    controller: _editControllers[poem.id],
                                    autofocus: true, // 自动聚焦
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  )
                                  : Text(poem.text),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEditing)
                                IconButton(
                                  icon: const Icon(
                                    Icons.save,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _saveEditing(poem.id),
                                )
                              else
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _startEditing(poem),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePoem(poem.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    // 释放所有编辑controller
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
