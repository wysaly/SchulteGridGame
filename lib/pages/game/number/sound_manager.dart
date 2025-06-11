import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  AudioPlayer? _clickPlayer;
  AudioPlayer? _successPlayer;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    // if (_isInitialized && _clickPlayer != null && _successPlayer != null) return true; // 如果已初始化，直接返回 true
    // 暂时禁用实际的音效加载，直接返回成功，以便测试其他部分
    _isInitialized = true;
    debugPrint('音效已禁用 (初始化成功)');
    return true;

    // try {
    //   debugPrint('正在初始化音效...');
    //   _clickPlayer?.dispose();
    //   _successPlayer?.dispose();

    //   _clickPlayer = AudioPlayer();
    //   _successPlayer = AudioPlayer();

    //   await _clickPlayer!.setSource(AssetSource('sounds/click.mp3'));
    //   await _successPlayer!.setSource(AssetSource('sounds/success.mp3'));
    //   await _clickPlayer!.setReleaseMode(ReleaseMode.stop);
    //   await _successPlayer!.setReleaseMode(ReleaseMode.stop);
    //   _isInitialized = true;
    //   debugPrint('音效初始化成功！');
    //   return true; // 成功初始化返回 true
    // } catch (e) {
    //   debugPrint('音效初始化失败: $e');
    //   _isInitialized = false; // 初始化失败
    //   return false; // 失败返回 false
    // }
  }

  Future<void> playClick() async {
    // try {
    //   if (!_isInitialized || _clickPlayer == null) {
    //     await initialize();
    //   }
    //   if (_isInitialized) { // 只有在初始化成功后才尝试播放
    //     debugPrint('播放点击音效');
    //     await _clickPlayer!.stop();
    //     await _clickPlayer!.play(AssetSource('sounds/click.mp3'));
    //   }
    // } catch (e) {
    //   debugPrint('播放点击音效失败: $e');
    // }
    debugPrint('点击音效 (已禁用)');
  }

  Future<void> playSuccess() async {
    // try {
    //   if (!_isInitialized || _successPlayer == null) {
    //     await initialize();
    //   }
    //   if (_isInitialized) { // 只有在初始化成功后才尝试播放
    //     debugPrint('播放成功音效');
    //     await _successPlayer!.stop();
    //     await _successPlayer!.play(AssetSource('sounds/success.mp3'));
    //   }
    // } catch (e) {
    //   debugPrint('播放成功音效失败: $e');
    // }
    debugPrint('成功音效 (已禁用)');
  }

  void dispose() {
    _clickPlayer?.dispose();
    _successPlayer?.dispose();
    _isInitialized = false; // Reset initialization state on dispose
    _clickPlayer = null;
    _successPlayer = null;
  }
}
