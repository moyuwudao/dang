import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/record_model.dart';
import '../../data/repositories/record_repository.dart';
import '../models/ai_model_config.dart';
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
        useModel = providerConfig != null ? _getTranscriptionModel(providerConfig) : await _getConfiguredModel();
      }

      debugPrint('Starting transcription: recordId=$recordId, model=$useModel, audioPath=${record.audioPath}');

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
    await transcribeRecord(recordId, model: model, onProgress: onProgress);
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

  Future<String> analyzeText(String text, {String? prompt, String? systemPrompt}) async {
    await _ensureApiConfigured();

    final analysisPrompt = prompt ?? '请分析以下文本，提取关键信息、行动项和要点总结。';
    final fullPrompt = '$analysisPrompt\n\n文本内容：\n$text';

    // If system prompt is provided, use it as system message
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      return await _apiService.chatCompletionWithSystem(
        fullPrompt,
        systemPrompt: systemPrompt,
      );
    }

    return await _apiService.chatCompletion(fullPrompt);
  }
}
