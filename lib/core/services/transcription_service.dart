import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../data/database/app_database.dart';
import '../../data/models/record_model.dart';
import '../../data/repositories/record_repository.dart';
import '../models/ai_model_config.dart';
import '../models/realtime_transcription_result.dart';
import 'audio_processor.dart';
import 'http_client.dart';
import 'api_service.dart';
import 'stats_service.dart';
import 'storage_service.dart';
import 'app_logger.dart';
import 'realtime_transcription_service.dart';
import 'tingwu_service.dart';

final realtimeTranscriptionServiceProvider = Provider<RealtimeTranscriptionService>((ref) {
  final sharedClient = ref.read(sharedHttpClientProvider);
  return RealtimeTranscriptionService(httpClient: sharedClient);
});

final tingwuServiceProvider = Provider<TingwuService>((ref) {
  final sharedClient = ref.read(sharedHttpClientProvider);
  return TingwuService(httpClient: sharedClient);
});

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final sharedClient = ref.read(sharedHttpClientProvider);
  final statsService = ref.read(statsServiceProvider);
  final realtimeService = ref.read(realtimeTranscriptionServiceProvider);
  final tingwuService = ref.read(tingwuServiceProvider);
  return TranscriptionService(
    httpClient: sharedClient, 
    statsService: statsService,
    realtimeTranscriptionService: realtimeService,
    tingwuService: tingwuService,
  );
});

class TranscriptionService {
  final HttpClient _httpClient;
  final AudioProcessor _audioProcessor;
  final StatsService? _statsService;
  final RealtimeTranscriptionService _realtimeTranscriptionService;
  TingwuService? _tingwuService;

  final AppLogger _logger = AppLogger();

  Future<void> _ensureTingwuService() async {
    if (_tingwuService != null) return;

    final config = await StorageService.getApiConfig();
    if (config != null) {
      final providerConfig = AiModelConfig.getConfigByName(config.provider);
      if (providerConfig != null) {
        _httpClient.configure(
          apiKey: config.apiKey,
          config: providerConfig,
          customBaseUrl: config.baseUrl,
          appId: config.appId,
          accessKeySecret: config.accessKeySecret,
        );
      }
    }

    _tingwuService = TingwuService(httpClient: _httpClient);
  }

  TranscriptionService({
    HttpClient? httpClient,
    AudioProcessor? audioProcessor,
    StatsService? statsService,
    RealtimeTranscriptionService? realtimeTranscriptionService,
    TingwuService? tingwuService,
  })  : _httpClient = httpClient ?? HttpClient(),
        _audioProcessor = audioProcessor ?? AudioProcessor(),
        _statsService = statsService,
        _realtimeTranscriptionService = realtimeTranscriptionService ?? RealtimeTranscriptionService(httpClient: httpClient ?? HttpClient()),
        _tingwuService = tingwuService;

  bool get isConfigured => _httpClient.isConfigured;

  void _log(String message) {
    _logger.i('Transcription', message);
  }

  Future<String> transcribeAudio(
    String audioFilePath, {
    String? model,
    void Function(String step, String detail)? onProgress,
    bool useChunking = true,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = _httpClient.currentConfig!;
    final effectiveModel = model ?? config.asrModel;
    _log(
        'TranscribeAudio: provider=${config.name}, model=$effectiveModel');

    if (!config.supportsTranscription) {
      throw Exception(
          '${config.displayName} 不支持语音转写。请使用 OpenAI、Gemini 或 Qwen 进行转写。');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / 1024 / 1024;
    _log('=== Transcription Start ===');
    _log('Provider: ${config.name}');
    _log('AudioFile: $audioFilePath');
    _log('FileSize: ${fileSizeMB.toStringAsFixed(1)}MB');

    onProgress?.call('read', '读取音频文件 (${fileSizeMB.toStringAsFixed(1)}MB)');

    try {
      String result;

      final needsChunk = useChunking && _needsChunking(audioFilePath);

      if (needsChunk) {
        onProgress?.call('split', '音频文件较大，开始分片处理');
        result = await _transcribeWithChunking(audioFilePath,
            model: effectiveModel, onProgress: onProgress);
      } else {
        switch (config.transcriptionMethod) {
          case TranscriptionMethod.whisperApi:
            onProgress?.call('upload', '上传音频到OpenAI Whisper');
            result =
                await _transcribeWhisper(audioFilePath, model: effectiveModel);
            break;
          case TranscriptionMethod.audioUpload:
            onProgress?.call('upload', '上传音频文件');
            result = await _transcribeAudioUpload(audioFilePath,
                model: effectiveModel);
            break;
          case TranscriptionMethod.nativeAsr:
          case TranscriptionMethod.asyncAsr:
            onProgress?.call('process', '进行语音转写');
            result = await _transcribeNativeAsr(audioFilePath,
                model: effectiveModel, onProgress: onProgress);
            break;
          case TranscriptionMethod.realtimeWebSocket:
            throw Exception(
                'Realtime WebSocket does not support file transcription. Use transcribeRealtime() instead.');
        }
      }

      _statsService?.apiVoiceCallCompleted(true);
      return result;
    } catch (e) {
      _statsService?.apiVoiceCallCompleted(false);
      rethrow;
    }
  }

  bool _needsChunking(String audioFilePath) {
    final file = File(audioFilePath);
    final fileSize = file.lengthSync();

    if (!audioFilePath.toLowerCase().endsWith('.wav')) {
      _logger.d('Transcription',
          'Chunking check: non-WAV file, cannot split compressed audio');
      return false;
    }

    final config = _httpClient.currentConfig!;
    switch (config.provider) {
      case AiProvider.qwen:
        const qwenSyncLimit = 5 * 1024 * 1024;
        _logger.d('Transcription',
            'Chunking check (Qwen): fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=5MB, needsChunk=${fileSize > qwenSyncLimit}');
        return fileSize > qwenSyncLimit;
      case AiProvider.openAI:
        const openAILimit = 20 * 1024 * 1024;
        _logger.d('Transcription',
            'Chunking check (OpenAI): fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=20MB, needsChunk=${fileSize > openAILimit}');
        return fileSize > openAILimit;
      case AiProvider.gemini:
        const geminiLimit = 16 * 1024 * 1024;
        _logger.d('Transcription',
            'Chunking check (Gemini): fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=16MB, needsChunk=${fileSize > geminiLimit}');
        return fileSize > geminiLimit;
      case AiProvider.tingwu:
        // 通义听悟通过服务端处理，不需要本地分片
        return false;
      default:
        if (config.transcriptionLimit != null) {
          final maxSizeBytes =
              config.transcriptionLimit!.maxFileSizeMB * 1024 * 1024;
          final effectiveMaxSize = (maxSizeBytes * 0.7).toInt();
          _logger.d('Transcription',
              'Chunking check: fileSize=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, max=${(effectiveMaxSize / 1024 / 1024).toStringAsFixed(1)}MB, needsChunk=${fileSize > effectiveMaxSize}');
          return fileSize > effectiveMaxSize;
        }
        return false;
    }
  }

  Future<String> _transcribeWithChunking(
    String audioFilePath, {
    required String model,
    void Function(String step, String detail)? onProgress,
  }) async {
    _logger.i('Transcription', '=== Chunked Transcription Start ===');

    final file = File(audioFilePath);
    final audioBytes = await file.readAsBytes();
    final mimeType = _audioProcessor.getMimeType(audioFilePath);

    List<Uint8List> chunks;
    if (audioFilePath.endsWith('.wav')) {
      final totalDuration = _audioProcessor.getWavDurationSeconds(audioBytes);
      _logger.d('Transcription', 'WAV file, total duration: ${totalDuration}s');
      chunks = _audioProcessor.splitWavFile(audioBytes);
    } else {
      chunks = _audioProcessor.splitAudioByBytes(audioBytes, mimeType);
    }

    if (chunks.isEmpty) {
      throw Exception('音频文件格式无效，无法分片');
    }

    _logger.i('Transcription', 'Split into ${chunks.length} chunks');
    onProgress?.call('split', '已分片为 ${chunks.length} 段，开始逐段转写');

    final results = <String>[];

    for (int i = 0; i < chunks.length; i++) {
      final chunkMsg =
          '转写第 ${i + 1}/${chunks.length} 段 (${(chunks[i].length / 1024).toStringAsFixed(0)}KB)...';
      _logger.i('Transcription', chunkMsg);
      onProgress?.call('upload', chunkMsg);

      String? chunkResult;
      int retries = 0;
      const maxRetries = 2;

      while (retries <= maxRetries && chunkResult == null) {
        try {
          final config = _httpClient.currentConfig!;
          switch (config.transcriptionMethod) {
            case TranscriptionMethod.whisperApi:
              chunkResult = await _transcribeWhisperChunk(chunks[i], mimeType,
                  model: model);
              break;
            case TranscriptionMethod.audioUpload:
              chunkResult = await _transcribeAudioUploadChunk(
                  chunks[i], mimeType,
                  model: model);
              break;
            case TranscriptionMethod.nativeAsr:
            case TranscriptionMethod.asyncAsr:
              chunkResult = await _transcribeNativeAsrChunk(
                  chunks[i], mimeType,
                  model: model);
              break;
            case TranscriptionMethod.realtimeWebSocket:
              throw Exception(
                  'Realtime WebSocket does not support chunk transcription');
          }

          if (chunkResult.isNotEmpty) {
            results.add(chunkResult);
            _logger.i('Transcription', 'Chunk ${i + 1} done: ${chunkResult.length} chars');
            onProgress?.call(
                'process', '第 ${i + 1}/${chunks.length} 段转写完成');
          }
        } catch (e) {
          retries++;
          _logger.w('Transcription', 'Chunk ${i + 1} attempt $retries failed: $e');
          onProgress?.call(
              'upload', '第 ${i + 1} 段转写失败，重试 $retries/$maxRetries...');
          if (retries <= maxRetries) {
            _logger.i('Transcription', 'Retrying chunk ${i + 1} in 3 seconds...');
            await Future.delayed(const Duration(seconds: 3));
          } else {
            _logger.e('Transcription', 'Chunk ${i + 1} failed after $maxRetries retries');
            results.add('[转写失败: 第${i + 1}段]');
            onProgress?.call('process', '第 ${i + 1} 段转写失败，跳过');
          }
        }
      }

      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    final combinedResult = results.join('\n');
    _logger.i('Transcription',
        '=== Chunked Transcription Done: ${combinedResult.length} chars from ${results.length} chunks ===');

    if (combinedResult.isEmpty || combinedResult == '[转写失败: 第1段]') {
      throw Exception('所有分片转写均失败');
    }

    await StorageService.incrementUsageStat(
      _httpClient.currentConfig!.name,
      'transcription',
      tokens: combinedResult.length,
    );

    return combinedResult;
  }

  Future<List<AudioChunkInfo>> getAudioChunks(String audioFilePath) async {
    return await _audioProcessor.getAudioChunks(audioFilePath);
  }

  Future<String> retranscribeChunks(
    String audioFilePath, {
    required List<int> chunkIndices,
    String? model,
    void Function(String step, String detail)? onProgress,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = _httpClient.currentConfig!;
    final effectiveModel = model ?? config.asrModel;
    _logger.i('Transcription',
        'RetranscribeChunks: indices=$chunkIndices, model=$effectiveModel');

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final audioBytes = await file.readAsBytes();
    final mimeType = _audioProcessor.getMimeType(audioFilePath);

    List<Uint8List> allChunks;
    if (audioFilePath.endsWith('.wav')) {
      allChunks = _audioProcessor.splitWavFile(audioBytes);
    } else {
      throw Exception('非WAV文件不支持段落选择转写');
    }

    if (allChunks.isEmpty) {
      throw Exception('音频文件格式无效，无法分片');
    }

    final results = <String>[];
    final totalChunks = chunkIndices.length;

    for (int i = 0; i < chunkIndices.length; i++) {
      final chunkIndex = chunkIndices[i];
      if (chunkIndex < 0 || chunkIndex >= allChunks.length) {
        _logger.w('Transcription',
            'Invalid chunk index: $chunkIndex, total: ${allChunks.length}');
        continue;
      }

      final chunkMsg =
          '转写第 ${chunkIndex + 1}/${allChunks.length} 段 (${i + 1}/$totalChunks 已选)...';
      _logger.i('Transcription', chunkMsg);
      onProgress?.call('upload', chunkMsg);

      try {
        String? chunkResult;
        switch (config.transcriptionMethod) {
          case TranscriptionMethod.whisperApi:
            chunkResult = await _transcribeWhisperChunk(
                allChunks[chunkIndex], mimeType,
                model: effectiveModel);
            break;
          case TranscriptionMethod.audioUpload:
            chunkResult = await _transcribeAudioUploadChunk(
                allChunks[chunkIndex], mimeType,
                model: effectiveModel);
            break;
          case TranscriptionMethod.nativeAsr:
          case TranscriptionMethod.asyncAsr:
            chunkResult = await _transcribeNativeAsrChunk(
                allChunks[chunkIndex], mimeType,
                model: effectiveModel);
            break;
          case TranscriptionMethod.realtimeWebSocket:
            throw Exception(
                'Realtime WebSocket does not support chunk retranscription');
        }

        if (chunkResult.isNotEmpty) {
          results.add(chunkResult);
          _logger.i('Transcription',
              'Chunk ${chunkIndex + 1} done: ${chunkResult.length} chars');
          onProgress?.call('process', '第 ${chunkIndex + 1} 段转写完成');
        }
      } catch (e) {
        _logger.e('Transcription', 'Chunk ${chunkIndex + 1} failed: $e');
        results.add('[转写失败: 第${chunkIndex + 1}段]');
        onProgress?.call('process', '第 ${chunkIndex + 1} 段转写失败');
      }

      if (i < chunkIndices.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return results.join('\n');
  }

  Future<String> _transcribeWhisper(String audioFilePath,
      {required String model}) async {
    _logger.i('Transcription', 'Using Whisper API with model: $model');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFilePath),
      'model': model,
      'language': 'auto',
      'response_format': 'json',
    });

    final response = await _httpClient.post(
      '/audio/transcriptions',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final text = response.data['text'] ?? '';
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(
        _httpClient.currentConfig!.name, 'transcription',
        tokens: text.length);
    return text;
  }

  Future<String> _transcribeAudioUpload(String audioFilePath,
      {required String model}) async {
    _logger.i('Transcription', 'Using Gemini Audio Upload with model: $model');

    final bytes = await File(audioFilePath).readAsBytes();
    final base64Audio = base64Encode(bytes);
    final mimeType = _audioProcessor.getMimeType(audioFilePath);

    _logger.i('Transcription',
        'Audio: mimeType=$mimeType, size=${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB');

    final response = await _httpClient.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _httpClient.apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Please transcribe the following audio file to text. Output only the transcribed text, without any additional explanation.'
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Audio}
              }
            ]
          }
        ]
      },
    );

    final text = response.data['candidates']?[0]?['content']?['parts']?[0]
            ?['text'] ??
        '';
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(
        _httpClient.currentConfig!.name, 'transcription',
        tokens: text.length);
    return text;
  }

  Future<String> _transcribeNativeAsr(
    String audioFilePath, {
    required String model,
    void Function(String step, String detail)? onProgress,
  }) async {
    _log('Using Native ASR for ${_httpClient.currentConfig!.name}');

    final file = File(audioFilePath);
    final fileSize = await file.length();
    final mimeType = _audioProcessor.getMimeType(audioFilePath);

    _log(
        'Audio: mimeType=$mimeType, size=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');

    switch (_httpClient.currentConfig!.provider) {
      case AiProvider.qwen:
        final bytes = await file.readAsBytes();
        return await _transcribeQwenAsrBytes(bytes, mimeType, model: model);
      case AiProvider.tingwu:
        throw Exception(
            '通义听悟不支持本地文件直接转写，请先上传文件到云端获取URL，然后调用 transcribeTingwu() 方法');
      default:
        throw Exception(
            '${_httpClient.currentConfig!.displayName} 不支持语音转写');
    }
  }

  /// Qwen ASR API 调用
  /// 
  /// **⚠️ 重要：修改此方法前必须先阅读 `.trae/rules/QWEN_ASR_API.md` 规范文档！**
  /// 
  /// 关键格式要求：
  /// - URL: https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
  /// - type: 'audio' (不是 'audio_url')
  /// - audio: data URI 字符串 (不是对象)
  /// - asr_options: 放在 extra_body 中 (不是根级别)
  Future<String> _transcribeQwenAsrBytes(Uint8List audioBytes, String mimeType,
      {required String model}) async {
    final audioSizeMB = audioBytes.length / 1024 / 1024;

    final config = _httpClient.currentConfig!;
    final asrModel = model.isNotEmpty
        ? model
        : (config.asrModel.isNotEmpty == true
            ? config.asrModel
            : 'qwen3-asr-flash');
    _log(
        'Qwen ASR: model=$asrModel, mimeType=$mimeType, size=${audioSizeMB.toStringAsFixed(1)}MB');

    final base64Audio = base64Encode(audioBytes);

    _log('Qwen ASR: calling OpenAI-compatible endpoint');

    final audioFormat = mimeType.contains('wav')
        ? 'wav'
        : (mimeType.contains('mp3') ? 'mp3' : 'wav');
    final dataUri = 'data:audio/$audioFormat;base64,$base64Audio';

    _log('Qwen ASR: sending request...');
    _log('Qwen ASR: URL=https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions');
    _log('Qwen ASR: audioFormat=$audioFormat, base64Length=${base64Audio.length}');

    Response? response;
    try {
      _log('Qwen ASR: about to call dio.post');
      final apiKey = _httpClient.apiKey;
      _log('Qwen ASR: apiKey configured=${apiKey != null && apiKey.isNotEmpty}');

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          headers: {
            'Authorization': 'Bearer ${apiKey ?? ''}',
            'Content-Type': 'application/json',
          },
        ),
      );

      _log('Qwen ASR: dio instance created with baseUrl=${dio.options.baseUrl}');

      final postFuture = dio.post(
        '/chat/completions',
        data: {
          'model': asrModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'audio',
                  'audio': 'data:audio/$audioFormat;base64,$base64Audio',
                }
              ]
            }
          ],
          'extra_body': {
            'asr_options': {
              'enable_itn': true,
              'language': 'auto',
            },
          },
        },
      );
      _log('Qwen ASR: post future created, awaiting...');
      response = await postFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Qwen ASR ERROR: Timeout after 30 seconds');
          throw Exception('转写请求超时（30秒），请检查网络或稍后重试');
        },
      );
      _log('Qwen ASR: post completed');
    } on DioException catch (e) {
      _log('Qwen ASR ERROR: DioException - ${e.type}: ${e.message}');
      if (e.response != null) {
        _log('Qwen ASR ERROR: Response status=${e.response?.statusCode}, data=${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      _log('Qwen ASR ERROR: Exception - $e');
      rethrow;
    }

    _log('Qwen ASR: received response, status=${response.statusCode}');
    _log(
        'Qwen ASR response: ${response.data.toString().substring(0, response.data.toString().length > 800 ? 800 : response.data.toString().length)}...');

    String text = '';
    if (response.data is Map) {
      final data = response.data as Map;
      _log('Qwen ASR response keys: ${data.keys.toList()}');

      if (data.containsKey('choices') && (data['choices'] as List?)?.isNotEmpty == true) {
        final choices = data['choices'] as List;
        final firstChoice = choices[0] as Map;
        if (firstChoice.containsKey('message') && firstChoice['message'] is Map) {
          final message = firstChoice['message'] as Map;
          text = message['content'] ?? '';
          _log('Qwen ASR output keys from message: ${message.keys.toList()}');
        }
      } else if (data.containsKey('output') && data['output'] is Map) {
        final output = data['output'] as Map;
        _log('Qwen ASR output keys: ${output.keys.toList()}');
        text = output['text'] ?? output['transcription'] ?? output['result'] ?? '';
      } else if (data.containsKey('text')) {
        text = data['text'] ?? '';
      } else if (data.containsKey('transcription')) {
        text = data['transcription'] ?? '';
      }
    }

    _log('Qwen ASR extracted text: "$text"');
    _log('Qwen ASR result length: ${text.length} chars');
    if (text.isEmpty) {
      _log('Qwen ASR ERROR: Empty result. Full response: ${response.data}');
      throw Exception('转写返回空结果，请检查音频文件或稍后重试');
    }
    await StorageService.incrementUsageStat(
        _httpClient.currentConfig!.name, 'transcription',
        tokens: text.length);
    return text;
  }

  Future<String> _transcribeWhisperChunk(Uint8List chunkBytes, String mimeType,
      {required String model}) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(p.join(
        tempDir.path, 'chunk_${DateTime.now().millisecondsSinceEpoch}.wav'));
    await tempFile.writeAsBytes(chunkBytes);

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(tempFile.path),
        'model': model,
        'language': 'auto',
        'response_format': 'json',
      });

      final response = await _httpClient.post(
        '/audio/transcriptions',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data['text'] ?? '';
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<String> _transcribeAudioUploadChunk(
      Uint8List chunkBytes, String mimeType,
      {required String model}) async {
    final base64Chunk = base64Encode(chunkBytes);

    final response = await _httpClient.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _httpClient.apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Please transcribe the following audio file to text. Output only the transcribed text.'
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Chunk}
              }
            ]
          }
        ]
      },
    );

    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';
  }

  Future<String> _transcribeNativeAsrChunk(
      Uint8List chunkBytes, String mimeType,
      {required String model}) async {
    switch (_httpClient.currentConfig!.provider) {
      case AiProvider.qwen:
        return await _transcribeQwenAsrBytes(chunkBytes, mimeType,
            model: model);
      default:
        throw Exception(
            '${_httpClient.currentConfig!.displayName} 不支持语音转写');
    }
  }

  Future<String> transcribeAudioAsync(
    String audioFilePath, {
    void Function(String step, String detail)? onProgress,
    String? language,
    bool enableWords = false,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = _httpClient.currentConfig!;
    if (config.provider != AiProvider.qwen) {
      throw Exception('异步转写仅支持 Qwen 提供商');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / 1024 / 1024;

    _logger.i('Transcription', '=== Async Transcription Start ===');
    _logger.i('Transcription', 'Provider: ${config.name}');
    _logger.i('Transcription', 'AudioFile: $audioFilePath');
    _logger.i('Transcription', 'FileSize: ${fileSizeMB.toStringAsFixed(1)}MB');

    onProgress?.call(
        'upload', '上传音频文件 (${fileSizeMB.toStringAsFixed(1)}MB)');

    try {
      final fileUrl = await _uploadAudioForAsync(audioFilePath);
      _logger.i('Transcription', 'File uploaded: $fileUrl');
      onProgress?.call('submit', '提交转写任务');

      final taskId = await _submitAsyncTranscription(
        fileUrl: fileUrl,
        language: language,
        enableWords: enableWords,
      );
      _logger.i('Transcription', 'Task submitted: $taskId');
      onProgress?.call('process', '转写任务已提交，正在处理...');

      final result = await _pollAsyncResult(
        taskId: taskId,
        onProgress: onProgress,
      );

      onProgress?.call('complete', '转写完成');
      _logger.i('Transcription',
          '=== Async Transcription Success: ${result.length} chars ===');
      return result;
    } catch (e) {
      _logger.e('Transcription', '=== Async Transcription Failed ===');
      _logger.e('Transcription', 'Error: $e');
      rethrow;
    }
  }

  Future<String> _uploadAudioForAsync(String audioFilePath) async {
    final file = File(audioFilePath);
    final fileName = file.uri.pathSegments.last;
    final mimeType = _audioProcessor.getMimeType(audioFilePath);

    final fileBytes = await file.readAsBytes();
    final base64Data = base64Encode(fileBytes);

    _logger.i('Transcription',
        'Uploading audio: $fileName, mimeType: $mimeType, size: ${fileBytes.length} bytes');

    final response = await _httpClient.post(
      'https://dashscope.aliyuncs.com/api/v1/files',
      data: {
        'model': 'qwen3-asr-flash-filetrans',
        'file': 'data:$mimeType;base64,$base64Data',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_httpClient.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final fileUrl = response.data['file_url'] as String?;
      if (fileUrl == null || fileUrl.isEmpty) {
        throw Exception('文件上传成功但未返回 URL');
      }
      return fileUrl;
    } else {
      throw Exception(
          '文件上传失败: ${response.statusCode} - ${response.data}');
    }
  }

  Future<String> _submitAsyncTranscription({
    required String fileUrl,
    String? language,
    bool enableWords = false,
  }) async {
    final requestData = <String, dynamic>{
      'model': 'qwen3-asr-flash-filetrans',
      'input': {
        'file_url': fileUrl,
      },
      'parameters': {
        'enable_itn': false,
        'enable_words': enableWords,
        if (language != null) 'language': language,
      },
    };

    _logger.i('Transcription', 'Submitting async task: ${jsonEncode(requestData)}');

    final response = await _httpClient.post(
      'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
      data: requestData,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_httpClient.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final taskId = response.data['output']?['task_id'] as String?;
      if (taskId == null || taskId.isEmpty) {
        throw Exception('任务提交成功但未返回 task_id');
      }
      return taskId;
    } else {
      throw Exception(
          '任务提交失败: ${response.statusCode} - ${response.data}');
    }
  }

  Future<String> _pollAsyncResult({
    required String taskId,
    void Function(String step, String detail)? onProgress,
    int maxRetries = 60,
    Duration interval = const Duration(seconds: 5),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      _logger.i('Transcription',
          'Polling task status: $taskId (attempt ${attempt + 1}/$maxRetries)');

      final response = await _httpClient.get(
        'https://dashscope.aliyuncs.com/api/v1/tasks/$taskId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_httpClient.apiKey}',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('查询任务状态失败: ${response.statusCode}');
      }

      final taskStatus =
          response.data['output']?['task_status'] as String? ?? 'UNKNOWN';
      final result = response.data['output']?['results']?['transcription']
          ?['text'] as String?;

      _logger.i('Transcription', 'Task status: $taskStatus');

      switch (taskStatus) {
        case 'PENDING':
          onProgress?.call(
              'pending', '任务排队中... (${attempt + 1}/$maxRetries)');
          break;
        case 'RUNNING':
          onProgress?.call(
              'running', '正在转写中... (${attempt + 1}/$maxRetries)');
          break;
        case 'SUCCEEDED':
          if (result != null && result.isNotEmpty) {
            return result;
          } else {
            throw Exception('转写成功但结果为空');
          }
        case 'FAILED':
          final errorMessage =
              response.data['output']?['error_message'] as String? ?? '未知错误';
          throw Exception('转写任务失败: $errorMessage');
        case 'UNKNOWN':
          throw Exception('任务不存在或状态未知');
        default:
          _logger.w('Transcription', 'Unknown status: $taskStatus');
      }

      await Future.delayed(interval);
    }

    throw Exception('转写超时，请稍后通过任务ID查询结果: $taskId');
  }

  Future<void> retryTranscription(
    int recordId, {
    required WidgetRef ref,
    void Function(String step, String detail)? onProgress,
  }) async {
    final recordRepository = ref.read(recordRepositoryProvider);
    final record = await recordRepository.getRecord(recordId);

    if (record == null) {
      throw Exception('记录不存在');
    }

    if (record.audioPath == null || record.audioPath!.isEmpty) {
      throw Exception('音频文件路径不存在');
    }

    await recordRepository.updateTranscriptionStatus(
      recordId,
      TranscriptionStatus.processing,
      null,
    );

    try {
      final result = await transcribeAudio(
        record.audioPath!,
        onProgress: onProgress,
      );

      await recordRepository.updateRecordContent(recordId, result);
      await recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.success,
        null,
      );
    } catch (e) {
      await recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.failed,
        e.toString(),
      );
      rethrow;
    }
  }

  Future<void> transcribeRecord(
    int recordId, {
    void Function(String step, String detail)? onProgress,
  }) async {
    final db = AppDatabase();
    final recordRepository = RecordRepository(db);

    try {
      final record = await recordRepository.getRecord(recordId);

      if (record == null) {
        throw Exception('记录不存在');
      }

      if (record.audioPath == null || record.audioPath!.isEmpty) {
        throw Exception('音频文件路径不存在');
      }

      await recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.processing,
        null,
      );

      try {
        final result = await transcribeAudio(
          record.audioPath!,
          onProgress: onProgress,
        );

        await recordRepository.updateRecordContent(recordId, result);
        await recordRepository.updateTranscriptionStatus(
          recordId,
          TranscriptionStatus.success,
          null,
        );
      } catch (e) {
        await recordRepository.updateTranscriptionStatus(
          recordId,
          TranscriptionStatus.failed,
          e.toString(),
        );
        rethrow;
      }
    } finally {
      await db.close();
    }
  }

  Future<String> analyzeText(
    String text, {
    String? systemPrompt,
    String? model,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = _httpClient.currentConfig!;
    final useModel = model ?? config.defaultModel;

    if (!config.supportsChat) {
      throw Exception('${config.displayName} 不支持文本分析');
    }

    try {
      String result;
      final messages = <Map<String, dynamic>>[];

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }

      messages.add({'role': 'user', 'content': text});

      final response = await _httpClient.post(
        '/chat/completions',
        data: {
          'model': useModel,
          'messages': messages,
          'max_tokens': 4096,
        },
      );

      result = (response.data['choices'] as List?)
              ?.cast<Map<String, dynamic>>()
              .firstOrNull?['message']?['content'] as String? ??
          '';
      
      await StorageService.incrementUsageStat(
          config.name, 'text_analysis',
          tokens: result.length);
      return result;
    } catch (e) {
      _logger.e('Transcription', 'AnalyzeText error: $e');
      rethrow;
    }
  }

  Future<SupplementItem> transcribeSupplement(SupplementItem supplement) async {
    if (supplement.type != 'audio') {
      return supplement;
    }

    try {
      final transcribedContent = await transcribeAudio(supplement.content);
      return supplement.copyWith(transcribedContent: transcribedContent);
    } catch (e) {
      _logger.e('Transcription', 'Transcribe supplement error: $e');
      rethrow;
    }
  }

  Stream<RealtimeTranscriptionResult> startRealtimeTranscription({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) {
    return _realtimeTranscriptionService.transcribeRealtime(
      audioStream: audioStream,
      onStatusChange: onStatusChange,
      language: language,
    );
  }

  /// 通义听悟转写
  ///
  /// 通义听悟需要音频文件的公网 URL，不支持本地文件直接上传。
  /// 调用前需要先将录音文件上传到阿里云 OSS 或其他云存储服务。
  ///
  /// [fileUrl] 音频文件的公网可访问 URL
  /// [fileName] 文件名（可选）
  /// [enableDiarization] 是否开启说话人分离（默认开启）
  /// [enableSummarization] 是否开启全文摘要（默认开启）
  /// [enableTodo] 是否开启待办提取（默认开启）
  /// [enableKeywords] 是否开启关键词提取（默认开启）
  /// [onProgress] 进度回调
  Future<TingwuResult> transcribeTingwu({
    required String fileUrl,
    String? fileName,
    bool enableDiarization = true,
    bool enableSummarization = true,
    bool enableTodo = true,
    bool enableKeywords = true,
    void Function(String step, String detail)? onProgress,
  }) async {
    if (_tingwuService == null) {
      throw Exception('通义听悟服务未初始化');
    }

    final config = _httpClient.currentConfig!;
    if (config.provider != AiProvider.tingwu) {
      throw Exception('当前配置的提供商不是通义听悟，请在设置中切换');
    }

    _log('=== Tingwu Transcription Start ===');
    _log('FileUrl: $fileUrl');
    _log('Diarization: $enableDiarization');
    _log('Summarization: $enableSummarization');

    try {
      // 1. 提交任务
      onProgress?.call('submit', '提交通义听悟转写任务');
      final taskId = await _tingwuService!.submitTask(
        fileUrl: fileUrl,
        fileName: fileName,
        enableDiarization: enableDiarization,
        enableSummarization: enableSummarization,
        enableTodo: enableTodo,
        enableKeywords: enableKeywords,
      );

      _log('Task submitted: $taskId');
      onProgress?.call('wait', '任务已提交，等待处理完成');

      // 2. 等待任务完成
      final result = await _tingwuService!.waitForResult(taskId);

      _log('Tingwu transcription completed');
      _statsService?.apiVoiceCallCompleted(true);
      return result;
    } catch (e) {
      _log('Tingwu transcription failed: $e');
      _statsService?.apiVoiceCallCompleted(false);
      rethrow;
    }
  }

  Future<void> retryAllFailed() async {
    final db = AppDatabase();
    final recordRepository = RecordRepository(db);

    try {
      final records = await recordRepository.getAllRecords();
      final failedRecords = records.where(
        (r) => r.transcriptionStatus == TranscriptionStatus.failed
      ).toList();

      for (final record in failedRecords) {
        try {
          await transcribeRecord(record.id);
        } catch (e) {
          _logger.e('Transcription', 'Retry failed for record ${record.id}: $e');
        }
      }
    } finally {
      await db.close();
    }
  }
}
