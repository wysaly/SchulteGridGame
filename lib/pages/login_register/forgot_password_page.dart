import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String? account;
  String? phone;
  String? selectedQuestion;
  String? answer;
  String? newPassword;

  final List<String> questions = ['你的小学叫什么？', '你最喜欢的明星是？', '你的工作是？'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('找回密码')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: '账号'),
                onSaved: (val) => account = val,
                validator: (val) => val == null || val.isEmpty ? '请输入账号' : null,
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
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: '手机号'),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val,
                validator:
                    (val) => val == null || val.isEmpty ? '请输入手机号' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: '新密码'),
                obscureText: true,
                onSaved: (val) => newPassword = val,
                validator:
                    (val) => val == null || val.isEmpty ? '请输入新密码' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // 这里处理找回密码逻辑
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('密码已重置')));
                  }
                },
                child: Text('重置密码'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
