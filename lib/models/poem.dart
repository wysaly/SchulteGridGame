/// 诗词模型类
class Poem {
  final int id;
  final String text;

  Poem({required this.id, required this.text});

  /// 从Map构造Poem对象
  factory Poem.fromMap(Map<String, dynamic> map) {
    return Poem(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      text: map['text']?.toString() ?? '',
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text};
  }
}
