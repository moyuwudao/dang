import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'app_logger.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<AudioPlayerState> _stateController = StreamController<AudioPlayerState>.broadcast();

  StreamSubscription<PlayerState>? _playerStateSub;

  Stream<AudioPlayerState> get playerStateStream => _stateController.stream;
  AudioPlayer get audioPlayer => _audioPlayer;

  Duration? get duration => _audioPlayer.duration;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<PlayerState> get rawPlayerStateStream => _audioPlayer.playerStateStream;

  Future<void> initialize(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
      _listenToPlayerState();
    } catch (e) {
      AppLogger().e('AudioPlayer', '初始化音频播放器失败: $e');
      throw Exception('无法加载音频文件');
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      AppLogger().e('AudioPlayer', '播放失败: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      AppLogger().e('AudioPlayer', '暂停失败: $e');
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      AppLogger().e('AudioPlayer', '拖动进度失败: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      AppLogger().e('AudioPlayer', '停止失败: $e');
      rethrow;
    }
  }

  void _listenToPlayerState() {
    _playerStateSub?.cancel();
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      AudioPlayerState state;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        state = AudioPlayerState.loading;
      } else if (!isPlaying) {
        state = AudioPlayerState.paused;
      } else if (processingState != ProcessingState.completed) {
        state = AudioPlayerState.playing;
      } else {
        state = AudioPlayerState.completed;
      }

      _stateController.add(state);
    });
  }

  Future<void> dispose() async {
    _playerStateSub?.cancel();
    await _audioPlayer.dispose();
    await _stateController.close();
  }
}

enum AudioPlayerState {
  loading,
  playing,
  paused,
  completed,
}
