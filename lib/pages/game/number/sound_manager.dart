import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final List<AudioPlayer> _clickPlayers = [];
  AudioPlayer? _successPlayer;
  bool _isInitialized = false;
  int _currentPlayerIndex = 0;
  final int _poolSize = 3;

  Future<bool> initialize({int retryCount = 0}) async {
    try {
      debugPrint('开始初始化音效系统...');

      // 确保先释放现有资源
      dispose();

      // 初始化点击音效池
      for (int i = 0; i < _poolSize; i++) {
        final player =
            AudioPlayer()
              ..setReleaseMode(ReleaseMode.stop) // 改为stop模式防止资源释放
              ..setPlayerMode(PlayerMode.lowLatency);

        // 添加超时和重试机制
        try {
          await player
              .setSource(AssetSource('sounds/click.mp3'))
              .timeout(const Duration(seconds: 5));
          _clickPlayers.add(player);
          debugPrint('点击播放器$i 初始化完成');
        } catch (e) {
          debugPrint('点击播放器$i 初始化失败: $e');
          player.dispose();
          if (retryCount < 2) {
            debugPrint('正在重试初始化点击播放器$i...');
            return await initialize(retryCount: retryCount + 1);
          }
          throw e;
        }
      }

      // 初始化成功音效
      _successPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.release);
      await _successPlayer!
          .setSource(AssetSource('sounds/success.mp3'))
          .timeout(const Duration(seconds: 5));
      debugPrint('成功音效播放器初始化完成');

      _isInitialized = true;
      debugPrint('音效系统初始化成功');
      return true;
    } catch (e) {
      debugPrint('音效初始化失败: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> playClick() async {
    if (!_isInitialized) return;
    try {
      // 轮换使用音效池中的播放器
      final player = _clickPlayers[_currentPlayerIndex];
      await player.stop(); // 确保完全停止
      await player.seek(Duration.zero); // 重置播放位置
      await player.resume();
      debugPrint('播放点击音效，使用播放器$_currentPlayerIndex');
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize; // 更新索引
    } catch (e) {
      debugPrint('播放点击音效失败: $e');
      // 尝试重新初始化
      if (e.toString().contains('disposed')) {
        await initialize();
      }
    }
  }

  Future<void> reset() async {
    try {
      debugPrint('正在重置音效系统...');

      // 如果未初始化则重新初始化
      if (!_isInitialized) {
        debugPrint('音效系统未初始化，正在初始化...');
        await initialize();
        return;
      }

      // 测试第一个播放器是否有效
      try {
        await _clickPlayers.first.seek(Duration.zero);
      } catch (e) {
        debugPrint('检测到播放器失效，重新初始化...');
        await initialize();
        return;
      }

      // 正常重置逻辑
      for (final player in _clickPlayers) {
        await player.seek(Duration.zero);
        debugPrint('点击播放器${_clickPlayers.indexOf(player)}已重置');
      }
      await _successPlayer?.stop();
      debugPrint('音效系统重置完成');
    } catch (e) {
      debugPrint('重置音效失败: $e');
      // 失败时尝试完全重新初始化
      await initialize();
    }
  }

  Future<void> playSuccess() async {
    if (!_isInitialized) return;
    try {
      await _successPlayer!.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('播放成功音效失败: $e');
    }
  }

  Future<void> preloadSounds() async {
    if (_clickPlayers.isEmpty) return;
    try {
      await _clickPlayers.first.play(AssetSource('sounds/click.mp3'));
      await _clickPlayers.first.stop();
      await _successPlayer?.play(AssetSource('sounds/success.mp3'));
      await _successPlayer?.stop();
    } catch (e) {
      debugPrint('预加载音效失败: $e');
    }
  }

  void dispose() {
    // 不实际释放播放器，只重置状态
    for (final player in _clickPlayers) {
      player.stop();
    }
    _successPlayer?.stop();
    _isInitialized = false;
  }
}
