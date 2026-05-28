import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/services/realtime_transcription_service.dart';
import '../../../core/services/transcription_queue_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_client.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../records/providers/record_provider.dart';

final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

final recordingRealtimeServiceProvider = Provider<RealtimeTranscriptionService>((ref) {
  final sharedClient = ref.watch(sharedHttpClientProvider);
  return RealtimeTranscriptionService(httpClient: sharedClient);
});

final recordingStateProvider = AsyncNotifierProvider<RecordingStateNotifier, RecordingState>(() {
  return RecordingStateNotifier();
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
  final List<String> realtimeSentences; // 累积所有转写句子
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
    this.realtimeSentences = const [],
    this.isRealtimeAvailable = false,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? duration,
    List<double>? amplitudes,
    String? currentRecordingPath,
    bool clearCurrentRecordingPath = false,
    String? error,
    bool clearError = false,
    bool? isTranscribing,
    String? transcriptionProgress,
    bool clearTranscriptionProgress = false,
    bool? isRealtimeEnabled,
    String? realtimeText,
    bool clearRealtimeText = false,
    List<String>? realtimeSentences,
    bool? isRealtimeAvailable,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      duration: duration ?? this.duration,
      amplitudes: amplitudes ?? this.amplitudes,
      currentRecordingPath: clearCurrentRecordingPath ? null : (currentRecordingPath ?? this.currentRecordingPath),
      error: clearError ? null : (error ?? this.error),
      isTranscribing: isTranscribing ?? this.isTranscribing,
      transcriptionProgress: clearTranscriptionProgress ? null : (transcriptionProgress ?? this.transcriptionProgress),
      isRealtimeEnabled: isRealtimeEnabled ?? this.isRealtimeEnabled,
      realtimeText: clearRealtimeText ? null : (realtimeText ?? this.realtimeText),
      realtimeSentences: realtimeSentences ?? this.realtimeSentences,
      isRealtimeAvailable: isRealtimeAvailable ?? this.isRealtimeAvailable,
    );
  }
}

class RecordingStateNotifier extends AsyncNotifier<RecordingState> {
  RecordingService get _recordingService => ref.read(recordingServiceProvider);
  RecordRepository get _recordRepository => ref.read(recordRepositoryProvider);
  TranscriptionService get _transcriptionService => ref.read(transcriptionServiceProvider);
  TranscriptionQueueService get _transcriptionQueue => ref.read(transcriptionQueueProvider);
  HttpClient get _httpClient => ref.read(sharedHttpClientProvider);
  RealtimeTranscriptionService get _realtimeService => ref.read(recordingRealtimeServiceProvider);

  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _realtimeSubscription;

  @override
  Future<RecordingState> build() async {
    return const RecordingState();
  }

  /// 检查是否有可用的实时转写配置
  Future<bool> checkRealtimeAvailability() async {
    try {
      AppLogger().i('Realtime', '=== CHECKING REAL TIME AVAILABILITY ===');
      
      // 检查多API配置
      final multiConfig = await StorageService.getMultiApiConfig();
      AppLogger().i('Realtime', 'Multi config hasAnyConfig: ${multiConfig.hasAnyConfig}');
      AppLogger().d('Realtime', 'All configs: ${multiConfig.configs}');
      
      if (multiConfig.hasAnyConfig) {
        final realtimeConfig = multiConfig.getConfigForFunction(ApiFunctionType.voiceRealtime);
        AppLogger().i('Realtime', 'Realtime config from multi: ${realtimeConfig != null ? "FOUND" : "null"}');
        
        if (realtimeConfig != null) {
          AppLogger().i('Realtime', 'YES! Found multi-config for voiceRealtime!');
          
          // 配置 HttpClient 用于实时转写
          final providerConfig = AiModelConfig.getConfig(realtimeConfig.provider);
          AppLogger().i('Realtime', 'Provider: ${realtimeConfig.provider.name}');
          AppLogger().i('Realtime', 'supportsRealtimeTranscription: ${providerConfig.supportsRealtimeTranscription}');
          
          _httpClient.configure(
            apiKey: realtimeConfig.apiKey,
            config: providerConfig,
            customBaseUrl: realtimeConfig.baseUrl,
            appId: realtimeConfig.appId,
            accessKeySecret: realtimeConfig.accessKeySecret,
          );
          AppLogger().i('Realtime', 'HttpClient configured for realtime from multi config');
          state = AsyncData(state.valueOrNull!.copyWith(isRealtimeAvailable: true, clearError: true));
          AppLogger().i('Realtime', 'isRealtimeAvailable set to TRUE');
          return true;
        }
      }

      // 检查单一配置
      AppLogger().i('Realtime', 'Now checking single config...');
      final singleConfig = await StorageService.getApiConfig();
      AppLogger().i('Realtime', 'Single config provider: ${singleConfig?.provider}');
      AppLogger().i('Realtime', 'Single config has API key: ${singleConfig?.apiKey.isNotEmpty}');

      if (singleConfig != null && singleConfig.apiKey.isNotEmpty) {
        try {
          AppLogger().i('Realtime', 'Single config not null and has key');
          final provider = AiProvider.values.firstWhere(
            (p) => p.name.toLowerCase() == singleConfig.provider.toLowerCase(),
            orElse: () => AiProvider.openAI,
          );
          AppLogger().i('Realtime', 'Matched provider: ${provider.name}');

          final providerConfig = AiModelConfig.getConfig(provider);
          AppLogger().i('Realtime', 'Provider supportsRealtimeTranscription: ${providerConfig.supportsRealtimeTranscription}');

          if (providerConfig.supportsRealtimeTranscription) {
            // 配置 HttpClient 用于实时转写
            _httpClient.configure(
              apiKey: singleConfig.apiKey,
              config: providerConfig,
              customBaseUrl: singleConfig.baseUrl,
              appId: singleConfig.appId,
              accessKeySecret: singleConfig.accessKeySecret,
            );
            AppLogger().i('Realtime', 'HttpClient configured for realtime from single config');
            state = AsyncData(state.valueOrNull!.copyWith(isRealtimeAvailable: true, clearError: true));
            AppLogger().i('Realtime', 'isRealtimeAvailable set to TRUE');
            return true;
          }
        } catch (e) {
          AppLogger().e('Realtime', 'Provider conversion error: $e');
        }
      }
      
      AppLogger().w('Realtime', 'NO CONFIG FOUND! Setting isRealtimeAvailable to FALSE');
      state = AsyncData(state.valueOrNull!.copyWith(isRealtimeAvailable: false));
      return false;
    } catch (e) {
      AppLogger().e('Realtime', 'Error checking availability: $e');
      state = AsyncData(state.valueOrNull!.copyWith(isRealtimeAvailable: false));
      return false;
    }
  }

  /// 切换实时转写开关
  void toggleRealtime(bool enabled) {
    final currentState = state.valueOrNull ?? const RecordingState();
    if (enabled && !currentState.isRealtimeAvailable) {
      state = AsyncData(currentState.copyWith(
        error: '未配置实时转写API，请先前往设置配置',
        isRealtimeEnabled: false,
      ));
      return;
    }
    state = AsyncData(currentState.copyWith(
      isRealtimeEnabled: enabled,
      clearError: enabled,
    ));
  }

  Future<void> startRecording() async {
    try {
      AppLogger().i('Realtime', '=== START RECORDING CALLED ===');

      final hasPermission = await _recordingService.hasPermission();
      if (!hasPermission) {
        state = AsyncData(state.valueOrNull!.copyWith(error: '需要麦克风权限'));
        return;
      }

      // 【关键】重新检查实时转写配置
      AppLogger().i('Realtime', '正在检查实时转写配置...');
      final realtimeAvailable = await checkRealtimeAvailability();
      AppLogger().i('Realtime', 'checkRealtimeAvailability 结果: $realtimeAvailable');
      AppLogger().i('Realtime', '当前状态: isRealtimeAvailable=${state.valueOrNull!.isRealtimeAvailable}, isRealtimeEnabled=${state.valueOrNull!.isRealtimeEnabled}');

      final path = await _recordingService.startRecording();

      state = AsyncData(state.valueOrNull!.copyWith(
        isRecording: true,
        isPaused: false,
        duration: Duration.zero,
        amplitudes: const [],
        currentRecordingPath: path,
        clearError: true,
        isTranscribing: false,
        clearTranscriptionProgress: true,
        clearRealtimeText: true,
        realtimeSentences: const [],
      ));

      // 监听振幅（先取消旧订阅，防止快速连续调用导致泄漏）
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recordingService.amplitudeStream.listen((amplitudes) {
        state = AsyncData(state.valueOrNull!.copyWith(amplitudes: amplitudes));
      });

      // 监听时长
      _durationSubscription?.cancel();
      _durationSubscription = _recordingService.durationStream.listen((duration) {
        state = AsyncData(state.valueOrNull!.copyWith(duration: duration));
      });

      // 如果用户已开启实时转写，则启动
      if (state.valueOrNull!.isRealtimeEnabled) {
        AppLogger().i('Realtime', '用户已开启实时转写，启动...');
        _startRealtimeTranscription();
      } else {
        AppLogger().i('Realtime', '实时转写未开启，跳过');
      }
    } catch (e) {
      AppLogger().e('Realtime', '录音开始失败: $e');
      state = AsyncData(state.valueOrNull!.copyWith(error: '开始录音失败: $e'));
    }
  }

  void _startRealtimeTranscription() {
    try {
      AppLogger().i('Realtime', '=== _startRealtimeTranscription CALLED ===');
      final audioStream = _recordingService.audioStream;
      if (audioStream == null) {
        AppLogger().w('Realtime', 'Audio stream is null');
        return;
      }

      AppLogger().i('Realtime', 'Calling _realtimeService.transcribeRealtime...');
      AppLogger().i('Realtime', 'Audio stream available: ${audioStream != null}');
      final realtimeStream = _realtimeService.transcribeRealtime(
        audioStream: audioStream,
        onStatusChange: (status, detail) {
          AppLogger().i('Realtime', 'Status: $status - $detail');
          if (status == 'error') {
            state = AsyncData(state.valueOrNull!.copyWith(error: '实时转写不可用，录音完成后将自动转写'));
          }
        },
      );

      _realtimeSubscription = realtimeStream.listen(
        (result) {
          AppLogger().i('Realtime', 'Result: "${result.text}", isFinal: ${result.isFinal}');
          
          if (result.isFinal) {
            // 如果是最终结果，添加到句子列表
            final newSentences = [...state.valueOrNull!.realtimeSentences, result.text];
            state = AsyncData(state.valueOrNull!.copyWith(
              realtimeSentences: newSentences,
              realtimeText: newSentences.join('\n'),
            ));
          } else {
            // 如果是中间结果，显示当前正在识别的文本
            final currentText = state.valueOrNull!.realtimeSentences.isNotEmpty
                ? '${state.valueOrNull!.realtimeSentences.join('\n')}\n${result.text}'
                : result.text;
            state = AsyncData(state.valueOrNull!.copyWith(realtimeText: currentText));
          }
        },
        onError: (e) {
          AppLogger().e('Realtime', 'Realtime transcription error: $e');
          state = AsyncData(state.valueOrNull!.copyWith(
            isRealtimeEnabled: false,
            error: '实时转写不可用，录音完成后将自动转写',
          ));
        },
      );
    } catch (e) {
      AppLogger().e('Realtime', 'Failed to start realtime transcription: $e');
      state = AsyncData(state.valueOrNull!.copyWith(
        isRealtimeEnabled: false,
        error: '实时转写不可用，录音完成后将自动转写',
      ));
    }
  }

  Future<void> stopRecording({List<String> tags = const []}) async {
    try {
      await _amplitudeSubscription?.cancel();
      await _durationSubscription?.cancel();
      await _realtimeSubscription?.cancel();

      final path = await _recordingService.stopRecording();
      
      if (path != null) {
        state = AsyncData(state.valueOrNull!.copyWith(
          isRecording: false,
          isPaused: false,
          clearCurrentRecordingPath: true,
          isTranscribing: false,
          transcriptionProgress: '录音已保存',
        ));

        // 保存记录到数据库（状态为pending，等待后台转写）
        final recordId = await _recordRepository.createRecordFromFields(
          type: RecordType.audio,
          audioPath: path,
          tags: tags,
          isRealtime: state.valueOrNull!.isRealtimeEnabled,
        );

        AppLogger().i('Recording', 'Record saved with ID: $recordId, added to transcription queue');

        // 刷新首页列表
        ref.invalidate(paginatedRecordsProvider);

        // 如果开启了实时转写，保存实时转写结果到记录
        if (state.valueOrNull!.isRealtimeEnabled && state.valueOrNull!.realtimeText != null && state.valueOrNull!.realtimeText!.isNotEmpty) {
          await _recordRepository.updateRecordContent(recordId, state.valueOrNull!.realtimeText!);
          await _recordRepository.updateTranscriptionStatus(recordId, TranscriptionStatus.success, null);
        } else {
          // 添加到后台转写队列
          _transcriptionQueue.addToQueue(recordId);
        }
        
        // 状态更新为等待转写
        state = AsyncData(state.valueOrNull!.copyWith(
          isTranscribing: false,
          transcriptionProgress: '等待转写中...',
          isRealtimeEnabled: false,
          clearRealtimeText: true,
          realtimeSentences: const [],
        ));
      }
    } catch (e) {
      state = AsyncData(state.valueOrNull!.copyWith(
        isRecording: false,
        isTranscribing: false,
        error: '停止录音失败: $e',
      ));
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _recordingService.pauseRecording();
      state = AsyncData(state.valueOrNull!.copyWith(isPaused: true));
    } catch (e) {
      state = AsyncData(state.valueOrNull!.copyWith(error: '暂停录音失败: $e'));
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recordingService.resumeRecording();
      state = AsyncData(state.valueOrNull!.copyWith(isPaused: false));
    } catch (e) {
      state = AsyncData(state.valueOrNull!.copyWith(error: '恢复录音失败: $e'));
    }
  }

  Future<void> cancelRecording() async {
    try {
      _amplitudeSubscription?.cancel();
      _durationSubscription?.cancel();
      _realtimeSubscription?.cancel();

      final path = state.valueOrNull!.currentRecordingPath;
      await _recordingService.cancelRecording();
      
      // 删除录音文件
      if (path != null) {
        await _recordingService.deleteRecording(path);
      }

      state = const AsyncData(RecordingState());
    } catch (e) {
      state = AsyncData(state.valueOrNull!.copyWith(error: '取消录音失败: $e'));
    }
  }

  @override
  Future<void> dispose() async {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _realtimeSubscription?.cancel();
    _recordingService.dispose();
  }
}
