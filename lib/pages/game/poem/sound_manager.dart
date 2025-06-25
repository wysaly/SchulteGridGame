import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  bool _isInitialized = false;

  Future<bool> initialize() async {
    // 音效功能已禁用，直接返回成功
    _isInitialized = true;
    debugPrint('古诗方格音效已禁用 (初始化成功)');
    return true;
  }

  Future<void> playClick() async {
    debugPrint('古诗方格点击音效 (已禁用)');
  }

  Future<void> playSuccess() async {
    debugPrint('古诗方格成功音效 (已禁用)');
  }

  void dispose() {
    _isInitialized = false;
  }
}
