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

final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

final recordingRealtimeServiceProvider = Provider<RealtimeTranscriptionService>((ref) {
  final sharedClient = ref.watch(sharedHttpClientProvider);
  return RealtimeTranscriptionService(httpClient: sharedClient);
});

final recordingStateProvider = StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(
    ref.watch(recordingServiceProvider),
    ref.watch(recordRepositoryProvider),
    ref.watch(transcriptionServiceProvider),
    ref.watch(transcriptionQueueProvider),
    ref.watch(sharedHttpClientProvider),
    ref.watch(recordingRealtimeServiceProvider),
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
  final HttpClient _httpClient;
  final RealtimeTranscriptionService _realtimeService;

  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _realtimeSubscription;

  RecordingStateNotifier(
    this._recordingService,
    this._recordRepository,
    this._transcriptionService,
    this._transcriptionQueue,
    this._httpClient,
    this._realtimeService,
  ) : super(const RecordingState());

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
          state = state.copyWith(isRealtimeAvailable: true, error: null);
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
            state = state.copyWith(isRealtimeAvailable: true, error: null);
            AppLogger().i('Realtime', 'isRealtimeAvailable set to TRUE');
            return true;
          }
        } catch (e) {
          AppLogger().e('Realtime', 'Provider conversion error: $e');
        }
      }
      
      AppLogger().w('Realtime', 'NO CONFIG FOUND! Setting isRealtimeAvailable to FALSE');
      state = state.copyWith(isRealtimeAvailable: false);
      return false;
    } catch (e) {
      AppLogger().e('Realtime', 'Error checking availability: $e');
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
      error: enabled ? null : state.error,
    );
  }

  Future<void> startRecording() async {
    try {
      AppLogger().i('Realtime', '=== START RECORDING CALLED ===');

      final hasPermission = await _recordingService.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: '需要麦克风权限');
        return;
      }

      // 【关键】重新检查实时转写配置
      AppLogger().i('Realtime', '正在检查实时转写配置...');
      final realtimeAvailable = await checkRealtimeAvailability();
      AppLogger().i('Realtime', 'checkRealtimeAvailability 结果: $realtimeAvailable');
      AppLogger().i('Realtime', '当前状态: isRealtimeAvailable=${state.isRealtimeAvailable}, isRealtimeEnabled=${state.isRealtimeEnabled}');

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

      // 如果用户已开启实时转写，则启动
      if (state.isRealtimeEnabled) {
        AppLogger().i('Realtime', '用户已开启实时转写，启动...');
        _startRealtimeTranscription();
      } else {
        AppLogger().i('Realtime', '实时转写未开启，跳过');
      }
    } catch (e) {
      AppLogger().e('Realtime', '录音开始失败: $e');
      state = state.copyWith(error: '开始录音失败: $e');
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
            state = state.copyWith(error: '实时转写不可用，录音完成后将自动转写');
          }
        },
      );

      _realtimeSubscription = realtimeStream.listen(
        (result) {
          AppLogger().i('Realtime', 'Result: "${result.text}", isFinal: ${result.isFinal}');
          // result.text 已经是完整文本（包含所有历史句子）
          // 直接更新状态，不需要额外缓冲
          state = state.copyWith(realtimeText: result.text);
        },
        onError: (e) {
          AppLogger().e('Realtime', 'Realtime transcription error: $e');
          state = state.copyWith(
            isRealtimeEnabled: false,
            error: '实时转写不可用，录音完成后将自动转写',
          );
        },
      );
    } catch (e) {
      AppLogger().e('Realtime', 'Failed to start realtime transcription: $e');
      state = state.copyWith(
        isRealtimeEnabled: false,
        error: '实时转写不可用，录音完成后将自动转写',
      );
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
        final recordId = await _recordRepository.createRecordFromFields(
          type: RecordType.audio,
          audioPath: path,
          tags: tags,
          isRealtime: state.isRealtimeEnabled,
        );

        debugPrint('Record saved with ID: $recordId, tags: $tags, isRealtime: ${state.isRealtimeEnabled}, added to transcription queue');

        // 如果开启了实时转写，保存实时转写结果到记录
        if (state.isRealtimeEnabled && state.realtimeText != null && state.realtimeText!.isNotEmpty) {
          await _recordRepository.updateRecordContent(recordId, state.realtimeText!);
          await _recordRepository.updateTranscriptionStatus(recordId, TranscriptionStatus.success, null);
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