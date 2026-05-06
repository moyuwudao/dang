import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<AudioPlayerState> _stateController = StreamController<AudioPlayerState>.broadcast();

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
      debugPrint('初始化音频播放器失败: $e');
      throw Exception('无法加载音频文件');
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('播放失败: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('暂停失败: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('拖动进度失败: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('停止失败: $e');
    }
  }

  void _listenToPlayerState() {
    _audioPlayer.playerStateStream.listen((playerState) {
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
