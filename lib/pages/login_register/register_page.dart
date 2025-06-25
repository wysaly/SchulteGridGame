import 'dart:math';

import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String? phone;
  String? password;
  String? selectedQuestion;
  String? answer;
  String? assignedAccount;

  final List<String> questions = ['你的小学叫什么？', '你最喜欢的明星是？', '你的工作是？'];

  String generateAccount() {
    // 简单生成一个随机账号
    return 'user${Random().nextInt(1000000)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('注册')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: '手机号'),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val,
                validator:
                    (val) => val == null || val.isEmpty ? '请输入手机号' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: '密码'),
                obscureText: true,
                onSaved: (val) => password = val,
                validator: (val) => val == null || val.isEmpty ? '请输入密码' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: '密保问题'),
                items:
                    questions
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                onChanged: (val) => setState(() => selectedQuestion = val),
                validator: (val) => val == null ? '请选择密保问题' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: '密保答案'),
                onSaved: (val) => answer = val,
                validator:
                    (val) => val == null || val.isEmpty ? '请输入密保答案' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    setState(() {
                      assignedAccount = generateAccount();
                    });
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('注册成功'),
                            content: Text('您的账号为：$assignedAccount\n请妥善保存。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('确定'),
                              ),
                            ],
                          ),
                    );
                  }
                },
                child: Text('注册'),
              ),
              if (assignedAccount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    '分配的账号：$assignedAccount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
