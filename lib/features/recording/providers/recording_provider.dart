import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/services/transcription_queue_service.dart';
import '../../../core/services/storage_service.dart';
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
  final bool isRealtimeEnabled;
  final String? realtimeText;
  final bool isRealtimeAvailable;

  const RecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.duration = Duration.zero,
    this.amplitudes = const [],
    this.currentRecordingPath,
    this.error,
    this.isTranscribing = false,
    this.transcriptionProgress,
    this.isRealtimeEnabled = false,
    this.realtimeText,
    this.isRealtimeAvailable = false,
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
    bool? isRealtimeEnabled,
    String? realtimeText,
    bool? isRealtimeAvailable,
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
      isRealtimeEnabled: isRealtimeEnabled ?? this.isRealtimeEnabled,
      realtimeText: realtimeText ?? this.realtimeText,
      isRealtimeAvailable: isRealtimeAvailable ?? this.isRealtimeAvailable,
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
  StreamSubscription? _realtimeSubscription;

  RecordingStateNotifier(
    this._recordingService,
    this._recordRepository,
    this._transcriptionService,
    this._transcriptionQueue,
  ) : super(const RecordingState());

  /// 检查是否有可用的实时转写配置
  Future<bool> checkRealtimeAvailability() async {
    try {
      debugPrint('Checking realtime availability...');
      // 检查多API配置
      final multiConfig = await StorageService.getMultiApiConfig();
      debugPrint('Multi config hasAnyConfig: ${multiConfig.hasAnyConfig}');
      if (multiConfig.hasAnyConfig) {
        final realtimeConfig = multiConfig.getConfigForFunction(ApiFunctionType.voiceRealtime);
        debugPrint('Realtime config from multi: $realtimeConfig');
        if (realtimeConfig != null) {
          state = state.copyWith(isRealtimeAvailable: true);
          debugPrint('Realtime available from multi config');
          return true;
        }
      }
      // 检查单一配置
      final singleConfig = await StorageService.getApiConfig();
      debugPrint('Single config: ${singleConfig?.provider}, key: ${singleConfig?.apiKey != null ? 'has key' : 'no key'}');
      if (singleConfig != null && singleConfig.apiKey.isNotEmpty) {
        // 将 provider key 转换为 AiProvider 枚举
        try {
          final provider = AiProvider.values.firstWhere(
            (p) => p.name.toLowerCase() == singleConfig.provider.toLowerCase(),
            orElse: () => AiProvider.openAI,
          );
          debugPrint('Matched provider: ${provider.name}');
          final providerConfig = AiModelConfig.getConfig(provider);
          debugPrint('Provider supportsRealtimeTranscription: ${providerConfig.supportsRealtimeTranscription}');
          if (providerConfig.supportsRealtimeTranscription) {
            state = state.copyWith(isRealtimeAvailable: true);
            debugPrint('Realtime available from single config');
            return true;
          }
        } catch (e) {
          debugPrint('Provider conversion error: $e');
        }
      }
      state = state.copyWith(isRealtimeAvailable: false);
      debugPrint('Realtime not available');
      return false;
    } catch (e) {
      debugPrint('Check realtime availability error: $e');
      state = state.copyWith(isRealtimeAvailable: false);
      return false;
    }
  }

  /// 切换实时转写开关
  void toggleRealtime(bool enabled) {
    if (enabled && !state.isRealtimeAvailable) {
      state = state.copyWith(
        error: '未配置实时转写API，请先前往设置配置',
        isRealtimeEnabled: false,
      );
      return;
    }
    state = state.copyWith(
      isRealtimeEnabled: enabled,
      error: null,
    );
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _recordingService.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: '需要麦克风权限');
        return;
      }

      // 检查实时转写可用性
      await checkRealtimeAvailability();

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
        realtimeText: null,
      );

      // 监听振幅
      _amplitudeSubscription = _recordingService.amplitudeStream.listen((amplitudes) {
        state = state.copyWith(amplitudes: amplitudes);
      });

      // 监听时长
      _durationSubscription = _recordingService.durationStream.listen((duration) {
        state = state.copyWith(duration: duration);
      });

      // 如果开启了实时转写，启动实时转写流
      if (state.isRealtimeEnabled) {
        _startRealtimeTranscription();
      }
    } catch (e) {
      state = state.copyWith(error: '开始录音失败: $e');
    }
  }

  void _startRealtimeTranscription() {
    try {
      // 获取音频流并启动实时转写
      final audioStream = _recordingService.audioStream;
      if (audioStream == null) return;

      final realtimeStream = _transcriptionService.startRealtimeTranscription(
        audioStream: audioStream.map((data) => data.toList()),
        onStatusChange: (status, detail) {
          debugPrint('Realtime status: $status - $detail');
          if (status == 'error') {
            state = state.copyWith(error: '实时转写错误: $detail');
          }
        },
      );

      final buffer = StringBuffer();
      _realtimeSubscription = realtimeStream.listen(
        (result) {
          if (result.isFinal) {
            buffer.write(result.text);
            state = state.copyWith(realtimeText: buffer.toString());
          } else {
            // 显示临时结果
            state = state.copyWith(
              realtimeText: buffer.toString() + result.text,
            );
          }
        },
        onError: (e) {
          debugPrint('Realtime transcription error: $e');
          state = state.copyWith(error: '实时转写失败: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to start realtime transcription: $e');
      state = state.copyWith(error: '启动实时转写失败: $e');
    }
  }

  Future<void> stopRecording({List<String> tags = const []}) async {
    try {
      _amplitudeSubscription?.cancel();
      _durationSubscription?.cancel();
      _realtimeSubscription?.cancel();

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
          isRealtime: state.isRealtimeEnabled,
        );

        debugPrint('Record saved with ID: $recordId, tags: $tags, isRealtime: ${state.isRealtimeEnabled}, added to transcription queue');

        // 如果开启了实时转写，保存实时转写结果到记录
        if (state.isRealtimeEnabled && state.realtimeText != null && state.realtimeText!.isNotEmpty) {
          await _recordRepository.updateRecordContent(recordId, state.realtimeText!);
          await _recordRepository.updateTranscriptionStatus(recordId, TranscriptionStatus.success);
        } else {
          // 添加到后台转写队列
          _transcriptionQueue.addToQueue(recordId);
        }
        
        // 状态更新为等待转写
        state = state.copyWith(
          isTranscribing: false,
          transcriptionProgress: '等待转写中...',
          isRealtimeEnabled: false,
          realtimeText: null,
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
      _realtimeSubscription?.cancel();

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
    _realtimeSubscription?.cancel();
    _recordingService.dispose();
    super.dispose();
  }
}