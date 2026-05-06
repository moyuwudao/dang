import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/ai_model_config.dart';
import 'storage_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late Dio _dio;
  AiModelConfig? _currentConfig;
  String? _apiKey;
  bool _isConfigured = false;

  static const int _chunkDurationSeconds = 30; // 减小分片时长，避免文件过大
  static const int _wavHeaderSize = 44;
  static const int _wavBytesPerSecond = 32000;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 300),
        sendTimeout: const Duration(seconds: 180),
      ),
    );
  }

  bool get isConfigured => _isConfigured && _currentConfig != null && _apiKey != null;

  AiModelConfig? get currentConfig => _currentConfig;

  String get configInfo {
    if (_currentConfig == null) return 'Not configured';
    return 'provider=${_currentConfig!.name}, baseUrl=${_dio.options.baseUrl}, model=${_currentConfig!.defaultModel}';
  }

  void configure({
    required String apiKey,
    required AiModelConfig config,
    String? customBaseUrl,
  }) {
    _currentConfig = config;
    _apiKey = apiKey;
    _isConfigured = true;
    final baseUrl = customBaseUrl ?? config.baseUrl;

    _dio.options.baseUrl = baseUrl;

    switch (config.provider) {
      case AiProvider.openAI:
      case AiProvider.deepSeek:
      case AiProvider.grok:
      case AiProvider.qwen:
      case AiProvider.zhipu:
      case AiProvider.kimi:
      case AiProvider.spark:
        _dio.options.headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.claude:
        _dio.options.headers = {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.gemini:
        _dio.options.headers = {
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.ernie:
        _dio.options.headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
        break;
      case AiProvider.custom:
        _dio.options.headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
        break;
    }

    debugPrint('API configured: $configInfo');
  }

  String _extractDioError(DioException e) {
    final response = e.response;
    if (response != null && response.data != null) {
      try {
        if (response.data is Map) {
          final error = response.data['error'];
          if (error is Map) {
            return error['message'] ?? error['code']?.toString() ?? response.data.toString();
          }
          return response.data['message'] ?? response.data.toString();
        }
        return response.data.toString();
      } catch (_) {
        return response.statusMessage ?? e.message ?? 'Unknown error';
      }
    }
    return e.message ?? 'Network error';
  }

  Future<bool> validateApiKey() async {
    if (!isConfigured) {
      debugPrint('API validation failed: not configured');
      return false;
    }

    debugPrint('Validating API: $configInfo');

    try {
      Response response;
      switch (_currentConfig!.provider) {
        case AiProvider.gemini:
          response = await _dio.get(
            '/models',
            queryParameters: {'key': _apiKey},
          );
          break;
        default:
          response = await _dio.get('/models');
          break;
      }
      debugPrint('API validation OK: status=${response.statusCode}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('API validation error: ${_extractDioError(e)}');
      return false;
    } catch (e) {
      debugPrint('API validation error: $e');
      return false;
    }
  }

  String _getMimeType(String filePath) {
    if (filePath.endsWith('.wav')) return 'audio/wav';
    if (filePath.endsWith('.m4a')) return 'audio/mp4';
    if (filePath.endsWith('.aac')) return 'audio/aac';
    if (filePath.endsWith('.ogg')) return 'audio/ogg';
    if (filePath.endsWith('.flac')) return 'audio/flac';
    if (filePath.endsWith('.mp3')) return 'audio/mp3';
    return 'audio/mp3';
  }

  int _getWavDurationSeconds(Uint8List wavBytes) {
    if (wavBytes.length < _wavHeaderSize) return 0;

    final dataView = ByteData.sublistView(wavBytes);

    final riff = String.fromCharCodes(wavBytes.sublist(0, 4));
    if (riff != 'RIFF') return 0;

    final sampleRate = dataView.getUint32(24, Endian.little);
    final bitsPerSample = dataView.getUint16(34, Endian.little);
    final numChannels = dataView.getUint16(22, Endian.little);
    final dataSize = dataView.getUint32(40, Endian.little);

    if (sampleRate == 0 || bitsPerSample == 0 || numChannels == 0) return 0;

    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    if (byteRate == 0) return 0;

    return dataSize ~/ byteRate;
  }

  List<Uint8List> _splitWavFile(Uint8List wavBytes) {
    if (wavBytes.length < _wavHeaderSize) return [];

    final dataView = ByteData.sublistView(wavBytes);

    // Verify RIFF header
    final riff = String.fromCharCodes(wavBytes.sublist(0, 4));
    if (riff != 'RIFF') {
      debugPrint('Invalid WAV file: missing RIFF header');
      return [];
    }

    final sampleRate = dataView.getUint32(24, Endian.little);
    final bitsPerSample = dataView.getUint16(34, Endian.little);
    final numChannels = dataView.getUint16(22, Endian.little);
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);

    if (byteRate == 0) return [];

    final chunkByteSize = byteRate * _chunkDurationSeconds;
    final originalDataSize = dataView.getUint32(40, Endian.little);
    final originalDataStart = _wavHeaderSize;

    if (originalDataSize <= chunkByteSize) {
      return [wavBytes];
    }

    final chunks = <Uint8List>[];
    int offset = 0;
    int chunkIndex = 0;

    while (offset < originalDataSize) {
      final currentChunkSize = (offset + chunkByteSize <= originalDataSize)
          ? chunkByteSize
          : originalDataSize - offset;

      // Build a proper WAV header for this chunk
      final chunkTotalSize = currentChunkSize + _wavHeaderSize - 8;
      final subchunk1Size = 16; // PCM format
      final blockAlign = numChannels * (bitsPerSample ~/ 8);

      final header = Uint8List(_wavHeaderSize);
      final headerView = ByteData.sublistView(header);

      // RIFF header
      header.setRange(0, 4, 'RIFF'.codeUnits);
      headerView.setUint32(4, chunkTotalSize, Endian.little);
      header.setRange(8, 12, 'WAVE'.codeUnits);

      // fmt subchunk
      header.setRange(12, 16, 'fmt '.codeUnits);
      headerView.setUint32(16, subchunk1Size, Endian.little);
      headerView.setUint16(20, 1, Endian.little); // AudioFormat = PCM
      headerView.setUint16(22, numChannels, Endian.little);
      headerView.setUint32(24, sampleRate, Endian.little);
      headerView.setUint32(28, byteRate, Endian.little);
      headerView.setUint16(32, blockAlign, Endian.little);
      headerView.setUint16(34, bitsPerSample, Endian.little);

      // data subchunk
      header.setRange(36, 40, 'data'.codeUnits);
      headerView.setUint32(40, currentChunkSize, Endian.little);

      final chunk = Uint8List(_wavHeaderSize + currentChunkSize);
      chunk.setRange(0, _wavHeaderSize, header);
      chunk.setRange(_wavHeaderSize, _wavHeaderSize + currentChunkSize,
          wavBytes, originalDataStart + offset);

      chunks.add(chunk);
      debugPrint('Chunk ${chunkIndex + 1}: ${currentChunkSize ~/ byteRate}s, ${(chunk.length / 1024).toStringAsFixed(0)}KB');

      offset += currentChunkSize;
      chunkIndex++;
    }

    return chunks;
  }

  Future<String> transcribeAudio(
    String audioFilePath, {
    String? model,
    void Function(String step, String detail)? onProgress,
    bool useChunking = true, // 新增：是否使用分片处理
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    // 根据提供商选择默认模型
    final effectiveModel = model ?? _currentConfig!.asrModel;
    debugPrint('TranscribeAudio: provider=${_currentConfig!.name}, model=$effectiveModel');

    if (!_currentConfig!.supportsTranscription) {
      throw Exception('${_currentConfig!.displayName} 不支持语音转写。请使用 OpenAI、Gemini 或 Qwen 进行转写。');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / 1024 / 1024;
    debugPrint('=== Transcription Start ===');
    debugPrint('Provider: ${_currentConfig!.name}');
    debugPrint('BaseUrl: ${_dio.options.baseUrl}');
    debugPrint('AudioFile: $audioFilePath');
    debugPrint('FileSize: ${fileSizeMB.toStringAsFixed(1)}MB');

    onProgress?.call('read', '读取音频文件 (${fileSizeMB.toStringAsFixed(1)}MB)');

    try {
      String result;
      
      // 检查是否需要分片处理
      final needsChunk = useChunking && _needsChunking(audioFilePath);
      
      if (needsChunk) {
        onProgress?.call('split', '音频文件较大，开始分片处理');
        result = await _transcribeWithChunking(audioFilePath, model: effectiveModel, onProgress: onProgress);
      } else {
        switch (_currentConfig!.transcriptionMethod) {
          case TranscriptionMethod.whisperApi:
            onProgress?.call('upload', '上传音频到OpenAI Whisper');
            result = await _transcribeWhisper(audioFilePath, model: effectiveModel);
            onProgress?.call('process', 'AI转写完成');
            break;
          case TranscriptionMethod.audioUpload:
            onProgress?.call('upload', '上传音频到Gemini');
            result = await _transcribeAudioUpload(audioFilePath, model: effectiveModel);
            onProgress?.call('process', 'AI转写完成');
            break;
          case TranscriptionMethod.nativeAsr:
          case TranscriptionMethod.asyncAsr:
            onProgress?.call('upload', '上传音频到${_currentConfig!.displayName}');
            result = await _transcribeNativeAsr(audioFilePath, model: effectiveModel, onProgress: onProgress);
            onProgress?.call('process', 'AI转写完成');
            break;
        }
      }
      
      onProgress?.call('save', '保存转写结果');
      debugPrint('=== Transcription Success: ${result.length} chars ===');
      return result;
    } on DioException catch (e) {
      final errorMsg = _extractDioError(e);
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      debugPrint('=== Transcription Failed ===');
      debugPrint('Status: $statusCode');
      debugPrint('Error: $errorMsg');
      debugPrint('Request URL: ${e.requestOptions.uri}');
      debugPrint('Request Method: ${e.requestOptions.method}');
      debugPrint('Request Headers: ${e.requestOptions.headers}');
      if (responseData != null) {
        final responseStr = responseData.toString();
        debugPrint('Response Data Length: ${responseStr.length}');
        if (responseStr.isNotEmpty) {
          debugPrint('Response Data: ${responseStr.length > 1500 ? responseStr.substring(0, 1500) + '...' : responseStr}');
        }
      } else {
        debugPrint('Response Data: null');
      }
      debugPrint('Dio Error Type: ${e.type}');
      debugPrint('Dio Message: ${e.message}');
      debugPrint('API Key starts with: ${_apiKey?.substring(0, 8) ?? 'null'}...');

      if (statusCode == 400) {
        throw Exception('请求格式错误(400): $errorMsg');
      } else if (statusCode == 401) {
        throw Exception('API Key无效(401)，请检查配置');
      } else if (statusCode == 403) {
        throw Exception('无权限访问(403): $errorMsg');
      } else if (statusCode == 404) {
        throw Exception('模型不存在(404): $errorMsg');
      } else if (statusCode == 429) {
        throw Exception('请求频率超限(429)，请稍后重试');
      } else if (statusCode != null && statusCode >= 500) {
        throw Exception('服务器错误($statusCode)，请稍后重试');
      } else {
        throw Exception('转写失败: $errorMsg');
      }
    } catch (e) {
      debugPrint('=== Transcription Error: $e ===');
      if (e is Exception) rethrow;
      throw Exception('转写失败: $e');
    }
  }

  bool _needsChunking(String audioFilePath) {
    final file = File(audioFilePath);
    final fileSize = file.lengthSync();

    // 只有 WAV 文件支持分片
    if (!audioFilePath.toLowerCase().endsWith('.wav')) {
      debugPrint('Chunking check: non-WAV file, cannot split compressed audio');
      return false;
    }

    // Provider-specific chunking logic
    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        // Qwen sync API (qwen3-asr-flash) has 10MB base64 limit via chat/completions
        // After base64 encoding, size increases ~33%, so use 5MB raw file limit (更保守)
        const qwenSyncLimit = 5 * 1024 * 1024;
        debugPrint('Chunking check (Qwen): fileSize=${(fileSize/1024/1024).toStringAsFixed(1)}MB, max=5MB, needsChunk=${fileSize > qwenSyncLimit}');
        return fileSize > qwenSyncLimit;
      case AiProvider.openAI:
        // Whisper API has 25MB file limit
        const openAILimit = 20 * 1024 * 1024;
        debugPrint('Chunking check (OpenAI): fileSize=${(fileSize/1024/1024).toStringAsFixed(1)}MB, max=20MB, needsChunk=${fileSize > openAILimit}');
        return fileSize > openAILimit;
      case AiProvider.gemini:
        // Gemini has 20MB limit for free tier
        const geminiLimit = 16 * 1024 * 1024;
        debugPrint('Chunking check (Gemini): fileSize=${(fileSize/1024/1024).toStringAsFixed(1)}MB, max=16MB, needsChunk=${fileSize > geminiLimit}');
        return fileSize > geminiLimit;
      default:
        if (_currentConfig!.transcriptionLimit != null) {
          final maxSizeBytes = _currentConfig!.transcriptionLimit!.maxFileSizeMB * 1024 * 1024;
          final effectiveMaxSize = (maxSizeBytes * 0.7).toInt(); // 更保守的限制
          debugPrint('Chunking check: fileSize=${(fileSize/1024/1024).toStringAsFixed(1)}MB, max=${(effectiveMaxSize/1024/1024).toStringAsFixed(1)}MB, needsChunk=${fileSize > effectiveMaxSize}');
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
    debugPrint('=== Chunked Transcription Start ===');

    final file = File(audioFilePath);
    final audioBytes = await file.readAsBytes();
    final mimeType = _getMimeType(audioFilePath);

    List<Uint8List> chunks;
    if (audioFilePath.endsWith('.wav')) {
      final totalDuration = _getWavDurationSeconds(audioBytes);
      debugPrint('WAV file, total duration: ${totalDuration}s');
      chunks = _splitWavFile(audioBytes);
    } else {
      chunks = _splitAudioByBytes(audioBytes, mimeType);
    }

    if (chunks.isEmpty) {
      throw Exception('音频文件格式无效，无法分片');
    }

    debugPrint('Split into ${chunks.length} chunks');
    onProgress?.call('split', '已分片为 ${chunks.length} 段，开始逐段转写');

    final results = <String>[];

    for (int i = 0; i < chunks.length; i++) {
      final chunkMsg = '转写第 ${i + 1}/${chunks.length} 段 (${(chunks[i].length/1024).toStringAsFixed(0)}KB)...';
      debugPrint(chunkMsg);
      onProgress?.call('upload', chunkMsg);

      String? chunkResult;
      int retries = 0;
      const maxRetries = 2;

      while (retries <= maxRetries && chunkResult == null) {
        try {
          switch (_currentConfig!.transcriptionMethod) {
            case TranscriptionMethod.whisperApi:
              chunkResult = await _transcribeWhisperChunk(chunks[i], mimeType, model: model);
              break;
            case TranscriptionMethod.audioUpload:
              chunkResult = await _transcribeAudioUploadChunk(chunks[i], mimeType, model: model);
              break;
            case TranscriptionMethod.nativeAsr:
            case TranscriptionMethod.asyncAsr:
              chunkResult = await _transcribeNativeAsrChunk(chunks[i], mimeType, model: model);
              break;
          }

          if (chunkResult != null && chunkResult.isNotEmpty) {
            results.add(chunkResult);
            debugPrint('Chunk ${i + 1} done: ${chunkResult.length} chars');
            onProgress?.call('process', '第 ${i + 1}/${chunks.length} 段转写完成');
          }
        } catch (e) {
          retries++;
          debugPrint('Chunk ${i + 1} attempt $retries failed: $e');
          onProgress?.call('upload', '第 ${i + 1} 段转写失败，重试 $retries/${maxRetries}...');
          if (retries <= maxRetries) {
            debugPrint('Retrying chunk ${i + 1} in 3 seconds...');
            await Future.delayed(const Duration(seconds: 3));
          } else {
            debugPrint('Chunk ${i + 1} failed after $maxRetries retries');
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
    debugPrint('=== Chunked Transcription Done: ${combinedResult.length} chars from ${results.length} chunks ===');

    if (combinedResult.isEmpty || combinedResult == '[转写失败: 第1段]') {
      throw Exception('所有分片转写均失败');
    }

    await StorageService.incrementUsageStat(
      _currentConfig!.name,
      'transcription',
      tokens: combinedResult.length,
    );

    return combinedResult;
  }

  List<Uint8List> _splitAudioByBytes(Uint8List audioBytes, String mimeType) {
    if (audioBytes.isEmpty) return [];

    // 对于压缩格式（MP3、M4A等），不能简单按字节分片
    // 直接返回原文件，如果太大则会在转写时失败
    // 用户需要使用 WAV 格式或异步接口处理大文件
    debugPrint('Non-WAV file detected ($mimeType), cannot split compressed audio');
    return [audioBytes];
  }

  Future<String> _transcribeWhisper(String audioFilePath, {required String model}) async {
    debugPrint('Using Whisper API with model: $model');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFilePath),
      'model': model,
      'language': 'auto',
      'response_format': 'json',
    });

    final response = await _dio.post(
      '/audio/transcriptions',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final text = response.data['text'] ?? '';
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(_currentConfig!.name, 'transcription', tokens: text.length);
    return text;
  }

  Future<String> _transcribeAudioUpload(String audioFilePath, {required String model}) async {
    debugPrint('Using Gemini Audio Upload with model: $model');

    final bytes = await File(audioFilePath).readAsBytes();
    final base64Audio = base64Encode(bytes);
    final mimeType = _getMimeType(audioFilePath);

    debugPrint('Audio: mimeType=$mimeType, size=${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB');

    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': 'Please transcribe the following audio file to text. Output only the transcribed text, without any additional explanation.'},
              {'inline_data': {'mime_type': mimeType, 'data': base64Audio}}
            ]
          }
        ]
      },
    );

    final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(_currentConfig!.name, 'transcription', tokens: text.length);
    return text;
  }

  Future<String> _transcribeNativeAsr(
    String audioFilePath, {
    required String model,
    void Function(String step, String detail)? onProgress,
  }) async {
    debugPrint('Using Native ASR for ${_currentConfig!.name}');

    final file = File(audioFilePath);
    final fileSize = await file.length();
    final mimeType = _getMimeType(audioFilePath);

    debugPrint('Audio: mimeType=$mimeType, size=${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');

    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        final bytes = await file.readAsBytes();
        final base64Audio = base64Encode(bytes);
        return await _transcribeQwenAsr(base64Audio, mimeType, model: model);
      default:
        throw Exception('${_currentConfig!.displayName} 不支持语音转写');
    }
  }

  Future<String> _transcribeQwenAsr(String base64Audio, String mimeType, {required String model}) async {
    final audioBytes = base64Decode(base64Audio);
    return await _transcribeQwenAsrBytes(audioBytes, mimeType, model: model);
  }

  Future<String> _transcribeQwenAsrBytes(Uint8List audioBytes, String mimeType, {required String model}) async {
    final audioSizeMB = audioBytes.length / 1024 / 1024;

    // Use the provided model, or fall back to config's asrModel, then hardcoded default
    final asrModel = model.isNotEmpty ? model : (_currentConfig?.asrModel.isNotEmpty == true ? _currentConfig!.asrModel : 'qwen3-asr-flash');
    debugPrint('Qwen ASR: model=$asrModel, mimeType=$mimeType, size=${audioSizeMB.toStringAsFixed(1)}MB');

    // Qwen ASR uses /chat/completions with input_audio (Qwen native support)
    final base64Audio = base64Encode(audioBytes);
    final dataUri = 'data:$mimeType;base64,$base64Audio';
    
    debugPrint('Qwen ASR: calling /chat/completions with input_audio');
    
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': 'qwen3.6-flash',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_audio',
                'input_audio': {
                  'data': dataUri,
                }
              }
            ]
          }
        ],
        'max_tokens': 4096,
      },
    );

    debugPrint('Qwen ASR response: ${response.data.toString().substring(0, response.data.toString().length > 800 ? 800 : response.data.toString().length)}...');
    
    final text = response.data['choices']?[0]?['message']?['content'] ?? '';
    debugPrint('Qwen ASR result: ${text.length} chars');
    if (text.isEmpty) throw Exception('转写返回空结果');
    await StorageService.incrementUsageStat(_currentConfig!.name, 'transcription', tokens: text.length);
    return text;
  }

  Future<String> _transcribeWhisperChunk(Uint8List chunkBytes, String mimeType, {required String model}) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(p.join(tempDir.path, 'chunk_${DateTime.now().millisecondsSinceEpoch}.wav'));
    await tempFile.writeAsBytes(chunkBytes);

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(tempFile.path),
        'model': model,
        'language': 'auto',
        'response_format': 'json',
      });

      final response = await _dio.post(
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

  Future<String> _transcribeAudioUploadChunk(Uint8List chunkBytes, String mimeType, {required String model}) async {
    final base64Chunk = base64Encode(chunkBytes);

    final response = await _dio.post(
      '/models/$model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': 'Please transcribe the following audio file to text. Output only the transcribed text.'},
              {'inline_data': {'mime_type': mimeType, 'data': base64Chunk}}
            ]
          }
        ]
      },
    );

    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
  }

  Future<String> _transcribeNativeAsrChunk(Uint8List chunkBytes, String mimeType, {required String model}) async {
    switch (_currentConfig!.provider) {
      case AiProvider.qwen:
        // Pass bytes directly, avoid double base64 encode/decode
        return await _transcribeQwenAsrBytes(chunkBytes, mimeType, model: model);
      default:
        throw Exception('${_currentConfig!.displayName} 不支持语音转写');
    }
  }

  Future<String> summarizeText(String text, {String? model}) async {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    try {
      switch (_currentConfig!.provider) {
        case AiProvider.claude:
          return await _claudeChat(model: useModel, systemPrompt: 'Summarize the following content into a todo list. Each item should include: task description, priority (high/medium/low), and deadline (if mentioned).', userContent: text);
        case AiProvider.gemini:
          return await _geminiChat(model: useModel, prompt: 'Summarize the following content into a todo list. Each item should include: task description, priority (high/medium/low), and deadline (if mentioned).\n\nContent: $text');
        default:
          return await _openAIStyleChat(model: useModel, systemPrompt: 'Summarize the following content into a todo list. Each item should include: task description, priority (high/medium/low), and deadline (if mentioned).', userContent: text);
      }
    } on DioException catch (e) {
      throw Exception('摘要失败: ${_extractDioError(e)}');
    } catch (e) {
      throw Exception('摘要失败: $e');
    }
  }

  Future<String> generateTitle(String text, {String? model}) async {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    try {
      switch (_currentConfig!.provider) {
        case AiProvider.claude:
          return await _claudeChat(model: useModel, systemPrompt: 'Generate a short title (max 20 characters) for the following content. Return only the title text.', userContent: text, maxTokens: 50);
        case AiProvider.gemini:
          return await _geminiChat(model: useModel, prompt: 'Generate a short title (max 20 characters) for the following content. Return only the title text.\n\nContent: $text');
        default:
          return await _openAIStyleChat(model: useModel, systemPrompt: 'Generate a short title (max 20 characters) for the following content. Return only the title text.', userContent: text, maxTokens: 50);
      }
    } on DioException catch (e) {
      throw Exception('标题生成失败: ${_extractDioError(e)}');
    } catch (e) {
      throw Exception('标题生成失败: $e');
    }
  }

  Future<String> chatCompletion(String prompt, {String? model}) async {
    return await chatCompletionWithSystem(
      prompt,
      systemPrompt: 'You are a helpful assistant.',
      model: model,
    );
  }

  Future<String> chatCompletionWithSystem(
    String prompt, {
    required String systemPrompt,
    String? model,
  }) async {
    if (!isConfigured) throw Exception('API not configured');
    final useModel = model ?? _currentConfig!.defaultModel;

    try {
      switch (_currentConfig!.provider) {
        case AiProvider.claude:
          return await _claudeChat(model: useModel, systemPrompt: systemPrompt, userContent: prompt);
        case AiProvider.gemini:
          return await _geminiChatWithSystem(model: useModel, prompt: prompt, systemPrompt: systemPrompt);
        default:
          return await _openAIStyleChat(model: useModel, systemPrompt: systemPrompt, userContent: prompt);
      }
    } on DioException catch (e) {
      throw Exception('对话失败: ${_extractDioError(e)}');
    } catch (e) {
      throw Exception('对话失败: $e');
    }
  }

  Future<String> _openAIStyleChat({required String model, required String systemPrompt, required String userContent, int maxTokens = 1000}) async {
    final response = await _dio.post('/chat/completions', data: {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContent},
      ],
      'temperature': 0.7,
      'max_tokens': maxTokens,
    });
    final content = response.data['choices'][0]['message']['content'] ?? '';
    final tokens = response.data['usage']?['total_tokens'] as int? ?? 0;
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat', tokens: tokens);
    return content;
  }

  Future<String> _claudeChat({required String model, required String systemPrompt, required String userContent, int maxTokens = 1000}) async {
    final response = await _dio.post('/messages', data: {
      'model': model,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': [{'role': 'user', 'content': userContent}],
    });
    final content = response.data['content'][0]['text'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat', tokens: content.length);
    return content;
  }

  Future<String> _geminiChat({required String model, required String prompt}) async {
    return await _geminiChatWithSystem(model: model, prompt: prompt, systemPrompt: '');
  }

  Future<String> _geminiChatWithSystem({required String model, required String prompt, required String systemPrompt}) async {
    final contents = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      contents.add({'role': 'user', 'parts': [{'text': systemPrompt}]});
      contents.add({'role': 'model', 'parts': [{'text': 'Understood. I will follow these instructions.'}]});
    }

    contents.add({'parts': [{'text': prompt}]});

    final response = await _dio.post('/models/$model:generateContent', queryParameters: {'key': _apiKey}, data: {
      'contents': contents,
    });
    final content = response.data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    await StorageService.incrementUsageStat(_currentConfig!.name, 'chat', tokens: content.length);
    return content;
  }

  // ==================== 异步转写方法 ====================

  /// 异步转写音频（适用于长音频 > 5分钟）
  /// 
  /// 使用 qwen3-asr-flash-filetrans 模型
  /// 支持最长12小时，最大2GB音频文件
  /// 
  /// 流程：
  /// 1. 上传音频文件获取 file_url
  /// 2. 提交异步转写任务
  /// 3. 轮询任务状态
  /// 4. 获取转写结果
  Future<String> transcribeAudioAsync(
    String audioFilePath, {
    void Function(String step, String detail)? onProgress,
    String? language,
    bool enableWords = false,
  }) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    if (_currentConfig!.provider != AiProvider.qwen) {
      throw Exception('异步转写仅支持 Qwen 提供商');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / 1024 / 1024;
    
    debugPrint('=== Async Transcription Start ===');
    debugPrint('Provider: ${_currentConfig!.name}');
    debugPrint('AudioFile: $audioFilePath');
    debugPrint('FileSize: ${fileSizeMB.toStringAsFixed(1)}MB');

    onProgress?.call('upload', '上传音频文件 (${fileSizeMB.toStringAsFixed(1)}MB)');

    try {
      // 步骤1: 上传音频文件获取 file_url
      final fileUrl = await _uploadAudioForAsync(audioFilePath);
      debugPrint('File uploaded: $fileUrl');
      onProgress?.call('submit', '提交转写任务');

      // 步骤2: 提交异步转写任务
      final taskId = await _submitAsyncTranscription(
        fileUrl: fileUrl,
        language: language,
        enableWords: enableWords,
      );
      debugPrint('Task submitted: $taskId');
      onProgress?.call('process', '转写任务已提交，正在处理...');

      // 步骤3: 轮询任务状态
      final result = await _pollAsyncResult(
        taskId: taskId,
        onProgress: onProgress,
      );

      onProgress?.call('complete', '转写完成');
      debugPrint('=== Async Transcription Success: ${result.length} chars ===');
      return result;
    } catch (e) {
      debugPrint('=== Async Transcription Failed ===');
      debugPrint('Error: $e');
      rethrow;
    }
  }

  /// 上传音频文件到阿里云 OSS 获取临时 URL
  Future<String> _uploadAudioForAsync(String audioFilePath) async {
    final file = File(audioFilePath);
    final fileName = file.uri.pathSegments.last;
    final mimeType = _getMimeType(audioFilePath);

    // 读取文件内容
    final fileBytes = await file.readAsBytes();
    final base64Data = base64Encode(fileBytes);

    debugPrint('Uploading audio: $fileName, mimeType: $mimeType, size: ${fileBytes.length} bytes');

    // 调用 DashScope 文件上传接口
    final response = await _dio.post(
      'https://dashscope.aliyuncs.com/api/v1/files',
      data: {
        'model': 'qwen3-asr-flash-filetrans',
        'file': 'data:$mimeType;base64,$base64Data',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
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
      throw Exception('文件上传失败: ${response.statusCode} - ${response.data}');
    }
  }

  /// 提交异步转写任务
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

    debugPrint('Submitting async task: ${jsonEncode(requestData)}');

    final response = await _dio.post(
      'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription',
      data: requestData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
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
      throw Exception('任务提交失败: ${response.statusCode} - ${response.data}');
    }
  }

  /// 轮询异步转写任务状态
  Future<String> _pollAsyncResult({
    required String taskId,
    void Function(String step, String detail)? onProgress,
    int maxRetries = 60, // 最多轮询60次
    Duration interval = const Duration(seconds: 5), // 每次间隔5秒
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      debugPrint('Polling task status: $taskId (attempt ${attempt + 1}/$maxRetries)');

      final response = await _dio.get(
        'https://dashscope.aliyuncs.com/api/v1/tasks/$taskId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('查询任务状态失败: ${response.statusCode}');
      }

      final taskStatus = response.data['output']?['task_status'] as String? ?? 'UNKNOWN';
      final result = response.data['output']?['results']?['transcription']?['text'] as String?;

      debugPrint('Task status: $taskStatus');

      switch (taskStatus) {
        case 'PENDING':
          onProgress?.call('pending', '任务排队中... (${attempt + 1}/$maxRetries)');
          break;
        case 'RUNNING':
          onProgress?.call('running', '正在转写中... (${attempt + 1}/$maxRetries)');
          break;
        case 'SUCCEEDED':
          if (result != null && result.isNotEmpty) {
            return result;
          } else {
            throw Exception('转写成功但结果为空');
          }
        case 'FAILED':
          final errorMessage = response.data['output']?['error_message'] as String? ?? '未知错误';
          throw Exception('转写任务失败: $errorMessage');
        case 'UNKNOWN':
          throw Exception('任务不存在或状态未知');
        default:
          debugPrint('Unknown status: $taskStatus');
      }

      // 等待后再次轮询
      await Future.delayed(interval);
    }

    throw Exception('转写超时，请稍后通过任务ID查询结果: $taskId');
  }
}
