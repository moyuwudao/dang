import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/services/transcription_queue_service.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

final recordingStateProvider = StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(
    ref.watch(recordingServiceProvider),
    ref.watch(recordRepositoryProvider),
    ref.watch(transcriptionServiceProvider),
    ref.watch(transcriptionQueueProvider),
  );
});

class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration duration;
  final List<double> amplitudes;
  final String? currentRecordingPath;
  final String? error;
  final bool isTranscribing;
  final String? transcriptionProgress;

  const RecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.duration = Duration.zero,
    this.amplitudes = const [],
    this.currentRecordingPath,
    this.error,
    this.isTranscribing = false,
    this.transcriptionProgress,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? duration,
    List<double>? amplitudes,
    String? currentRecordingPath,
    String? error,
    bool? isTranscribing,
    String? transcriptionProgress,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      duration: duration ?? this.duration,
      amplitudes: amplitudes ?? this.amplitudes,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      error: error ?? this.error,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      transcriptionProgress: transcriptionProgress ?? this.transcriptionProgress,
    );
  }
}

class RecordingStateNotifier extends StateNotifier<RecordingState> {
  final RecordingService _recordingService;
  final RecordRepository _recordRepository;
  final TranscriptionService _transcriptionService;
  final TranscriptionQueueService _transcriptionQueue;
  
  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _durationSubscription;

  RecordingStateNotifier(
    this._recordingService,
    this._recordRepository,
    this._transcriptionService,
    this._transcriptionQueue,
  ) : super(const RecordingState());

  Future<void> startRecording() async {
    try {
      final hasPermission = await _recordingService.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: '需要麦克风权限');
        return;
      }

      final path = await _recordingService.startRecording();
      
      state = state.copyWith(
        isRecording: true,
        isPaused: false,
        duration: Duration.zero,
        amplitudes: const [],
        currentRecordingPath: path,
        error: null,
        isTranscribing: false,
        transcriptionProgress: null,
      );

      // 监听振幅
      _amplitudeSubscription = _recordingService.amplitudeStream.listen((amplitudes) {
        state = state.copyWith(amplitudes: amplitudes);
      });

      // 监听时长
      _durationSubscription = _recordingService.durationStream.listen((duration) {
        state = state.copyWith(duration: duration);
      });
    } catch (e) {
      state = state.copyWith(error: '开始录音失败: $e');
    }
  }

  Future<void> stopRecording({List<String> tags = const []}) async {
    try {
      _amplitudeSubscription?.cancel();
      _durationSubscription?.cancel();

      final path = await _recordingService.stopRecording();
      
      if (path != null) {
        state = state.copyWith(
          isRecording: false,
          isPaused: false,
          currentRecordingPath: null,
          isTranscribing: false,
          transcriptionProgress: '录音已保存',
        );

        // 保存记录到数据库（状态为pending，等待后台转写）
        final recordId = await _recordRepository.createRecord(
          type: RecordType.audio,
          audioPath: path,
          tags: tags,
        );

        debugPrint('Record saved with ID: $recordId, tags: $tags, added to transcription queue');

        // 添加到后台转写队列
        _transcriptionQueue.addToQueue(recordId);
        
        // 状态更新为等待转写
        state = state.copyWith(
          isTranscribing: false,
          transcriptionProgress: '等待转写中...',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        isTranscribing: false,
        error: '停止录音失败: $e',
      );
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _recordingService.pauseRecording();
      state = state.copyWith(isPaused: true);
    } catch (e) {
      state = state.copyWith(error: '暂停录音失败: $e');
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recordingService.resumeRecording();
      state = state.copyWith(isPaused: false);
    } catch (e) {
      state = state.copyWith(error: '恢复录音失败: $e');
    }
  }

  Future<void> cancelRecording() async {
    try {
      _amplitudeSubscription?.cancel();
      _durationSubscription?.cancel();

      final path = state.currentRecordingPath;
      await _recordingService.cancelRecording();
      
      // 删除录音文件
      if (path != null) {
        await _recordingService.deleteRecording(path);
      }

      state = const RecordingState();
    } catch (e) {
      state = state.copyWith(error: '取消录音失败: $e');
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _recordingService.dispose();
    super.dispose();
  }
}