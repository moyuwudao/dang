import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/record_model.dart';
import '../../data/repositories/record_repository.dart';
import '../models/ai_model_config.dart';
import '../models/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService(
    ref.watch(apiServiceProvider),
    ref.watch(recordRepositoryProvider),
  );
});

class TranscriptionService {
  final ApiService _apiService;
  final RecordRepository _recordRepository;

  TranscriptionService(this._apiService, this._recordRepository);

  Future<void> _ensureApiConfigured() async {
    if (_apiService.isConfigured) return;

    debugPrint('API not configured, loading from storage...');
    final config = await StorageService.getApiConfig();
    if (config == null) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final providerConfig = AiModelConfig.getConfigByName(config.provider);
    if (providerConfig == null) {
      throw Exception('未知的API提供商: ${config.provider}');
    }

    _apiService.configure(
      apiKey: config.apiKey,
      config: providerConfig,
      customBaseUrl: config.baseUrl,
    );
    debugPrint('API configured from storage: ${_apiService.configInfo}');
  }

  /// 为指定功能类型配置API（支持多API配置）
  Future<void> _ensureApiConfiguredForFunction(ApiFunctionType functionType) async {
    // 先检查是否已配置
    if (_apiService.isConfigured) {
      // 检查当前配置是否支持该功能
      final currentConfig = _apiService.currentConfig;
      if (currentConfig != null) {
        final supportsFunction = switch (functionType) {
          ApiFunctionType.text => currentConfig.supportsTextAnalysis,
          ApiFunctionType.voice => currentConfig.supportsTranscription,
          ApiFunctionType.voiceRealtime => currentConfig.supportsRealtimeTranscription,
          ApiFunctionType.image => currentConfig.supportsOCR,
        };
        if (supportsFunction) return;
      }
    }

    debugPrint('Loading API config for function: $functionType');

    // 尝试从多API配置中查找
    final multiConfig = await StorageService.getMultiApiConfig();
    if (multiConfig.hasAnyConfig) {
      final functionConfig = multiConfig.getConfigForFunction(functionType);
      if (functionConfig != null) {
        final providerConfig = AiModelConfig.getConfig(functionConfig.provider);
        _apiService.configure(
          apiKey: functionConfig.apiKey,
          config: providerConfig,
          customBaseUrl: functionConfig.baseUrl,
          appId: functionConfig.appId,
        );
        debugPrint('API configured from multi-config for $functionType: ${_apiService.configInfo}');
        return;
      }
    }

    // 回退到单一配置
    await _ensureApiConfigured();
  }

  Future<String> _getConfiguredModel() async {
    final config = await StorageService.getApiConfig();
    return config?.model ?? 'whisper-1';
  }

  String _getTranscriptionModel(AiModelConfig config) {
    // For providers with dedicated ASR models, use the ASR model
    if (config.asrModel.isNotEmpty) {
      return config.asrModel;
    }
    // Otherwise fall back to the configured chat model
    return config.defaultModel;
  }

  Future<void> transcribeRecord(
    int recordId, {
    String? model,
    void Function(String step, String detail)? onProgress,
  }) async {
    try {
      await _ensureApiConfigured();

      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.processing,
      );

      final record = await _recordRepository.getRecordById(recordId);
      if (record == null) {
        throw Exception('记录不存在');
      }

      if (record.audioPath == null) {
        throw Exception('音频文件不存在');
      }

      // Use provided model, or get the appropriate transcription model for the provider
      String useModel;
      if (model != null && model.isNotEmpty) {
        useModel = model;
      } else {
        final providerConfig = _apiService.currentConfig;
        useModel = providerConfig != null
            ? _getTranscriptionModel(providerConfig)
            : await _getConfiguredModel();
      }

      debugPrint(
          'Starting transcription: recordId=$recordId, model=$useModel, audioPath=${record.audioPath}');

      final text = await _apiService.transcribeAudio(
        record.audioPath!,
        model: useModel,
        onProgress: onProgress,
      );

      if (text.isEmpty) {
        throw Exception('转写返回空结果');
      }

      await _recordRepository.updateRecordContent(recordId, text);
      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.success,
      );

      debugPrint('Transcription success: ${text.length} chars');
    } catch (e) {
      debugPrint('Transcription failed: $e');

      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.failed,
        error: e.toString(),
      );

      rethrow;
    }
  }

  Future<void> retryTranscription(
    int recordId, {
    String? model,
    void Function(String step, String detail)? onProgress,
  }) async {
    await _recordRepository.updateRecordContent(recordId, '');
    await transcribeRecord(recordId, model: model, onProgress: onProgress);
  }

  Future<List<AudioChunkInfo>> getAudioChunks(int recordId) async {
    final record = await _recordRepository.getRecordById(recordId);
    if (record == null) {
      throw Exception('记录不存在');
    }
    if (record.audioPath == null) {
      throw Exception('音频文件不存在');
    }
    return await _apiService.getAudioChunks(record.audioPath!);
  }

  Future<String> retranscribeChunks(
    int recordId, {
    required List<int> chunkIndices,
    String? model,
    void Function(String step, String detail)? onProgress,
  }) async {
    await _ensureApiConfigured();

    final record = await _recordRepository.getRecordById(recordId);
    if (record == null) {
      throw Exception('记录不存在');
    }
    if (record.audioPath == null) {
      throw Exception('音频文件不存在');
    }

    String useModel;
    if (model != null && model.isNotEmpty) {
      useModel = model;
    } else {
      final providerConfig = _apiService.currentConfig;
      useModel = providerConfig != null
          ? _getTranscriptionModel(providerConfig)
          : await _getConfiguredModel();
    }

    return await _apiService.retranscribeChunks(
      record.audioPath!,
      chunkIndices: chunkIndices,
      model: useModel,
      onProgress: onProgress,
    );
  }

  Future<void> retryAllFailed() async {
    final records = await _recordRepository.getAllRecords();
    final failedRecords = records
        .where((r) => r.transcriptionStatus == TranscriptionStatus.failed)
        .toList();

    for (final record in failedRecords) {
      try {
        await transcribeRecord(record.id);
      } catch (e) {
        debugPrint('重试转写失败 ID=${record.id}: $e');
      }
    }
  }

  Future<List<RecordModel>> getPendingRecords() async {
    final records = await _recordRepository.getAllRecords();
    return records
        .where((r) => r.transcriptionStatus == TranscriptionStatus.pending)
        .toList();
  }

  Future<List<RecordModel>> getFailedRecords() async {
    final records = await _recordRepository.getAllRecords();
    return records
        .where((r) => r.transcriptionStatus == TranscriptionStatus.failed)
        .toList();
  }

  // ==================== 实时语音转写 ====================

  /// 开始实时语音转写
  ///
  /// 返回一个 Stream，每次收到增量转写结果时会 emit 一个 [RealtimeTranscriptionResult]
  ///
  /// 使用方式：
  /// ```dart
  /// final stream = transcriptionService.startRealtimeTranscription(
  ///   audioStream: microphoneStream,
  /// );
  /// await for (final result in stream) {
  ///   if (result.isFinal) {
  ///     print('最终文本: ${result.text}');
  ///   } else {
  ///     print('临时文本: ${result.text}');
  ///   }
  /// }
  /// ```
  Stream<RealtimeTranscriptionResult> startRealtimeTranscription({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    await _ensureApiConfiguredForFunction(ApiFunctionType.voiceRealtime);

    debugPrint('Starting realtime transcription...');

    yield* _apiService.transcribeRealtime(
      audioStream: audioStream,
      onStatusChange: onStatusChange,
      language: language,
    );
  }

  /// 实时转写并保存到记录
  ///
  /// 适用于边录音边转写的场景
  Stream<RealtimeTranscriptionResult> startRealtimeTranscriptionForRecord({
    required int recordId,
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    await _ensureApiConfiguredForFunction(ApiFunctionType.voiceRealtime);

    // 初始化记录状态为处理中
    await _recordRepository.updateTranscriptionStatus(
      recordId,
      TranscriptionStatus.processing,
    );

    final buffer = StringBuffer();

    try {
      await for (final result in _apiService.transcribeRealtime(
        audioStream: audioStream,
        onStatusChange: onStatusChange,
        language: language,
      )) {
        yield result;

        // 累积最终文本到缓冲区
        if (result.isFinal) {
          buffer.write(result.text);
          buffer.write(' ');

          // 实时保存到数据库（可选，根据性能需求决定）
          await _recordRepository.updateRecordContent(
            recordId,
            buffer.toString().trim(),
          );
        }
      }

      // 转写完成，更新状态
      final finalText = buffer.toString().trim();
      if (finalText.isNotEmpty) {
        await _recordRepository.updateRecordContent(recordId, finalText);
        await _recordRepository.updateTranscriptionStatus(
          recordId,
          TranscriptionStatus.success,
        );
        debugPrint('Realtime transcription saved: ${finalText.length} chars');
      } else {
        await _recordRepository.updateTranscriptionStatus(
          recordId,
          TranscriptionStatus.failed,
          error: '实时转写结果为空',
        );
      }
    } catch (e) {
      debugPrint('Realtime transcription failed: $e');
      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.failed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ==================== 文本分析 ====================

  Future<String> analyzeText(String text,
      {String? prompt, String? systemPrompt}) async {
    await _ensureApiConfigured();

    final analysisPrompt = prompt ?? '请分析以下文本，提取关键信息、行动项和要点总结。';
    final fullPrompt = '$analysisPrompt\n\n文本内容：\n$text';

    // If system prompt is provided, use it as system message
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      return await _apiService.chatCompletionWithSystem(
        fullPrompt,
        systemPrompt: systemPrompt,
        toolId: 'transcription',
      );
    }

    return await _apiService.chatCompletion(fullPrompt,
        toolId: 'transcription');
  }

  /// 转写补充内容中的音频或图片
  Future<SupplementItem> transcribeSupplement(SupplementItem supplement) async {
    await _ensureApiConfigured();

    if (supplement.type == 'text') {
      // 文本类型无需转写
      return supplement;
    }

    if (supplement.type == 'audio') {
      // 转写音频补充
      debugPrint('Transcribing supplement audio: ${supplement.content}');
      final providerConfig = _apiService.currentConfig;
      final useModel = providerConfig != null
          ? _getTranscriptionModel(providerConfig)
          : await _getConfiguredModel();

      final text = await _apiService.transcribeAudio(
        supplement.content,
        model: useModel,
      );

      debugPrint('Supplement audio transcribed: ${text.length} chars');
      return supplement.copyWith(transcribedContent: text);
    }

    if (supplement.type == 'image') {
      // 使用 AI 多模态模型进行图片 OCR
      debugPrint('OCR for supplement image: ${supplement.content}');
      final text = await _apiService.recognizeImage(supplement.content);
      debugPrint('Supplement image OCR result: ${text.length} chars');
      return supplement.copyWith(transcribedContent: text);
    }

    return supplement;
  }

  /// 转写记录中所有未转写的补充内容
  Future<List<SupplementItem>> transcribeAllSupplements(int recordId) async {
    final record = await _recordRepository.getRecordById(recordId);
    if (record == null) {
      throw Exception('记录不存在');
    }

    final updatedSupplements = <SupplementItem>[];
    for (final supplement in record.supplements) {
      if (supplement.type != 'text' &&
          (supplement.transcribedContent == null ||
              supplement.transcribedContent!.isEmpty)) {
        try {
          final transcribed = await transcribeSupplement(supplement);
          updatedSupplements.add(transcribed);
        } catch (e) {
          debugPrint('Failed to transcribe supplement ${supplement.id}: $e');
          updatedSupplements.add(supplement);
        }
      } else {
        updatedSupplements.add(supplement);
      }
    }

    // 保存更新后的补充内容
    await _recordRepository.updateSupplements(recordId, updatedSupplements);
    return updatedSupplements;
  }
}
