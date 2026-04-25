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
      debugPrint('开始初始化古诗方格音效系统...');

      // 如果已经初始化且播放器有效，直接返回
      if (_isInitialized &&
          _clickPlayers.isNotEmpty &&
          !_clickPlayers.any((p) => p.state == PlayerState.stopped)) {
        debugPrint('古诗方格音效系统已初始化，跳过重复初始化');
        return true;
      }

      // 确保先释放现有资源
      dispose();

      // 初始化点击音效池
      for (int i = 0; i < _poolSize; i++) {
        final player =
            AudioPlayer()
              ..setReleaseMode(ReleaseMode.stop)
              ..setPlayerMode(PlayerMode.lowLatency);

        try {
          // 增加超时重试机制
          bool loaded = false;
          for (int attempt = 0; attempt < 3 && !loaded; attempt++) {
            try {
              await player
                  .setSource(AssetSource('sounds/click.mp3'))
                  .timeout(const Duration(seconds: 2));
              _clickPlayers.add(player);
              debugPrint('古诗方格点击播放器$i 初始化完成 (尝试${attempt + 1})');
              loaded = true;
            } catch (e) {
              if (attempt == 2) rethrow;
              debugPrint('古诗方格点击播放器$i 初始化失败(尝试${attempt + 1}): $e');
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        } catch (e) {
          debugPrint('古诗方格点击播放器$i 初始化失败: $e');
          player.dispose();
          if (retryCount < 2) {
            debugPrint('正在重试初始化古诗方格点击播放器$i...');
            return await initialize(retryCount: retryCount + 1);
          }
          throw e;
        }
      }

      // 初始化成功音效
      _successPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.release);
      // 增加成功音效加载重试
      bool loaded = false;
      for (int attempt = 0; attempt < 3 && !loaded; attempt++) {
        try {
          await _successPlayer!
              .setSource(AssetSource('sounds/success.mp3'))
              .timeout(const Duration(seconds: 2));
          loaded = true;
        } catch (e) {
          if (attempt == 2) rethrow;
          debugPrint('成功音效加载失败(尝试${attempt + 1}): $e');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      debugPrint('古诗方格成功音效播放器初始化完成');

      _isInitialized = true;
      debugPrint('古诗方格音效系统初始化成功');
      return true;
    } catch (e) {
      debugPrint('古诗方格音效初始化失败: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> playClick() async {
    if (!_isInitialized || _clickPlayers.isEmpty) {
      debugPrint('古诗方格音效未初始化，尝试重新初始化...');
      await initialize();
      if (!_isInitialized) return;
    }

    try {
      final player = _clickPlayers[_currentPlayerIndex];
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.seek(Duration.zero);
      await player.resume();
      debugPrint('播放古诗方格点击音效，使用播放器$_currentPlayerIndex');
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
    } catch (e) {
      debugPrint('播放古诗方格点击音效失败: $e');
      // 任何错误都尝试重新初始化
      await initialize();
    }
  }

  Future<void> reset() async {
    try {
      if (!_isInitialized) {
        await initialize();
        return;
      }

      try {
        await _clickPlayers.first.seek(Duration.zero);
      } catch (e) {
        debugPrint('检测到古诗方格播放器失效，重新初始化...');
        await initialize();
        return;
      }

      for (final player in _clickPlayers) {
        await player.seek(Duration.zero);
      }
      await _successPlayer?.stop();
    } catch (e) {
      debugPrint('重置古诗方格音效失败: $e');
      await initialize();
    }
  }

  Future<void> playSuccess() async {
    if (!_isInitialized) return;
    try {
      await _successPlayer!.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('播放古诗方格成功音效失败: $e');
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
}
