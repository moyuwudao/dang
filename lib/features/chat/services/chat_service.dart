import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/text_analysis_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/api_config_resolver.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/models/ai_model_config.dart' show AiModelConfig, AiProvider, ApiFunctionType;
import '../../memory/services/memory_service.dart';
import '../models/chat_message.dart' show ChatMessageModel, MessageRole;

class ChatService {
  final TextAnalysisService _textAnalysisService;
  final MemoryService _memoryService;
  final Ref _ref;

  ChatService(this._textAnalysisService, this._memoryService, this._ref);

  /// 发送消息并获取流式响应
  Stream<String> sendMessageStream({
    required String conversationId,
    required String userMessage,
    required List<ChatMessageModel> history,
    String? systemPrompt,
    String? agentSystemPrompt,
    String? skillSystemPrompt,
    int? sourceRecordId,
    String? contextSnapshot,
    List<String> imagePaths = const [],
    bool enableSearch = false,
  }) async* {
    // 预加载当前对话的记忆（短期记忆+对话片段+长期记忆）
    try {
      await _memoryService.initConversationMemory(conversationId);
      await _memoryService.getLongTermMemory();
    } catch (e) {
      AppLogger().w('ChatService', '加载记忆失败 conv=$conversationId err=$e');
    }

    final logger = AppLogger();
    logger.i('ChatService',
        '▶ sendMessageStream 开始 conv=$conversationId history=${history.length} '
        'userLen=${userMessage.length} imgCount=${imagePaths.length} '
        'recordId=$sourceRecordId');

    // 1. 构建消息历史（OpenAI 格式）
    final messages = _buildOpenAIMessages(
      history: history,
      systemPrompt: systemPrompt,
      agentSystemPrompt: agentSystemPrompt,
      skillSystemPrompt: skillSystemPrompt,
      contextSnapshot: contextSnapshot,
      conversationId: conversationId,
    );
    logger.d('ChatService',
        '消息历史构建完成 messages=${messages.length} systemPromptLen=${systemPrompt?.length ?? 0} '
        'contextSnapshotLen=${contextSnapshot?.length ?? 0}');

    // 2. 添加用户新消息（支持多模态：文本+图片）
    if (imagePaths.isNotEmpty) {
      // 检查当前配置的模型是否支持视觉（vision）
      // 若不支持，先调用 ImageRecognitionService 做 OCR fallback，把图片转为文字描述
      final httpClient = _ref.read(sharedHttpClientProvider);
      final config = httpClient.currentConfig;
      final currentModel = httpClient.currentModel ?? config?.defaultModel;
      final supportsVision = config != null &&
          AiModelConfig.isVisionModel(config.provider, currentModel);
      logger.i('ChatService',
          '多模态分支 vision=$supportsVision provider=${config?.name} model=$currentModel');

      if (supportsVision) {
        // 多模态消息格式（OpenAI Vision API）
        final content = <Map<String, dynamic>>[
          {'type': 'text', 'text': userMessage},
        ];
        for (final imagePath in imagePaths) {
          content.add({
            'type': 'image_url',
            'image_url': {'url': await _imageToBase64Url(imagePath)},
          });
        }
        messages.add({'role': 'user', 'content': content});
        logger.d('ChatService', '已添加 vision 多模态用户消息 imgCount=${imagePaths.length}');
      } else {
        // Fallback：当前模型不支持视觉，用图像识别服务提取文字描述后拼接到用户消息
        logger.i('ChatService',
            '当前模型不支持视觉，启用 OCR fallback：${config?.displayName ?? "未知"} / $currentModel');
        final apiService = _ref.read(apiServiceProvider);
        final descriptions = <String>[];
        for (final imagePath in imagePaths) {
          try {
            final desc = await apiService.recognizeImage(imagePath);
            descriptions.add('[图片描述] $desc');
            logger.i('ChatService', 'OCR 成功 path=$imagePath descLen=${desc.length}');
          } catch (e) {
            logger.w('ChatService', '图片识别失败 path=$imagePath err=$e');
            descriptions.add('[图片识别失败]');
          }
        }
        final combinedText = descriptions.isEmpty
            ? userMessage
            : '$userMessage\n\n${descriptions.join('\n')}';
        messages.add({'role': 'user', 'content': combinedText});
        logger.d('ChatService', 'OCR fallback 拼接完成 descCount=${descriptions.length} combinedLen=${combinedText.length}');
      }
    } else {
      messages.add({'role': 'user', 'content': userMessage});
    }

    // 3. 调用流式 API
    final buffer = StringBuffer();
    var chunkCount = 0;
    var firstChunkMs = 0;
    final startMs = DateTime.now().millisecondsSinceEpoch;
    try {
      logger.i('ChatService', '开始接收流式响应... enableSearch=$enableSearch');
      await for (final chunk in _streamChatCompletion(messages, enableSearch: enableSearch)) {
        if (chunkCount == 0) {
          firstChunkMs = DateTime.now().millisecondsSinceEpoch - startMs;
          logger.i('ChatService', '首个 chunk 到达 耗时=${firstChunkMs}ms');
        }
        buffer.write(chunk);
        chunkCount++;
        yield chunk;
      }
      logger.i('ChatService',
          '◀ sendMessageStream 完成 chunks=$chunkCount totalLen=${buffer.length} '
          '耗时=${DateTime.now().millisecondsSinceEpoch - startMs}ms');
    } catch (e) {
      logger.e('ChatService',
          '✗ Stream error chunks=$chunkCount bufferLen=${buffer.length} err=$e');
      rethrow;
    }
  }

  /// 将图片文件转为 base64 data URL
  Future<String> _imageToBase64Url(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    // 根据扩展名推断 MIME 类型
    final ext = imagePath.toLowerCase().split('.').last;
    String mimeType = 'image/jpeg';
    if (ext == 'png') mimeType = 'image/png';
    else if (ext == 'gif') mimeType = 'image/gif';
    else if (ext == 'webp') mimeType = 'image/webp';
    return 'data:$mimeType;base64,$base64';
  }

  /// 非流式发送消息（兼容现有工具）
  Future<String> sendMessage({
    required List<ChatMessageModel> history,
    String? systemPrompt,
    String? agentSystemPrompt,
    String? skillSystemPrompt,
    String? userMessage,
  }) async {
    final messages = _buildOpenAIMessages(
      history: history,
      systemPrompt: systemPrompt,
      agentSystemPrompt: agentSystemPrompt,
      skillSystemPrompt: skillSystemPrompt,
    );

    if (userMessage != null && userMessage.isNotEmpty) {
      messages.add({'role': 'user', 'content': userMessage});
    }

    return _textAnalysisService.chatCompletionWithSystem(
      userMessage ?? '',
      systemPrompt: _buildSystemPrompt(
        systemPrompt,
        null,
        agentSystemPrompt: agentSystemPrompt,
        skillSystemPrompt: skillSystemPrompt,
      ),
    );
  }

  /// 生成对话标题
  Future<String> generateTitle(List<ChatMessageModel> messages) async {
    final logger = AppLogger();
    if (messages.isEmpty) {
      logger.d('ChatService', 'generateTitle: 空消息列表，返回默认标题');
      return '新对话';
    }

    final firstUserMessage = messages.firstWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => messages.first,
    );

    final content = firstUserMessage.content.trim();
    if (content.length <= 12) {
      logger.d('ChatService', 'generateTitle: 内容较短，直接使用原文 len=${content.length}');
      return content;
    }

    try {
      logger.d('ChatService', 'generateTitle: 调用 AI 生成标题 contentLen=${content.length}');
      final prompt = '请用 2-6 个字为这段对话生成一个简短标签（类似话题标签），不要加标点，不要解释：\n\n$content';
      final title = await _textAnalysisService.chatCompletion(prompt);
      var result = title.trim();
      // 去除可能生成的标点和引号
      result = result.replaceAll(RegExp(r'[\s·.,;:!?，。；：！？""''()]'), '');
      if (result.isEmpty || result.length > 12) {
        result = content.substring(0, content.length.clamp(1, 12));
      }
      logger.i('ChatService', 'generateTitle: 生成成功 title="$result"');
      return result;
    } catch (e) {
      logger.w('ChatService', 'generateTitle: AI 调用失败，回退截取前12字 err=$e');
      return content.substring(0, content.length.clamp(1, 12));
    }
  }

  /// 构建 OpenAI 格式的消息列表
  List<Map<String, dynamic>> _buildOpenAIMessages({
    required List<ChatMessageModel> history,
    String? systemPrompt,
    String? agentSystemPrompt,
    String? skillSystemPrompt,
    String? contextSnapshot,
    String? conversationId,
  }) {
    final messages = <Map<String, dynamic>>[];

    // 系统提示词
    final effectiveSystemPrompt = _buildSystemPrompt(
      systemPrompt,
      contextSnapshot,
      agentSystemPrompt: agentSystemPrompt,
      skillSystemPrompt: skillSystemPrompt,
      conversationId: conversationId,
    );
    if (effectiveSystemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': effectiveSystemPrompt});
    }

    // 历史消息
    for (final message in history) {
      if (message.role == MessageRole.system) continue;
      messages.add({
        'role': message.role.name,
        'content': message.content,
      });
    }

    return messages;
  }

  String _buildSystemPrompt(
    String? systemPrompt,
    String? contextSnapshot, {
    String? agentSystemPrompt,
    String? skillSystemPrompt,
    String? conversationId,
  }) {
    final logger = AppLogger();
    final parts = <String>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      parts.add(systemPrompt);
    }

    if (agentSystemPrompt != null && agentSystemPrompt.isNotEmpty) {
      parts.add(agentSystemPrompt);
    }

    if (skillSystemPrompt != null && skillSystemPrompt.isNotEmpty) {
      parts.add(skillSystemPrompt);
    }

    if (contextSnapshot != null && contextSnapshot.isNotEmpty) {
      parts.add('【相关上下文】\n$contextSnapshot');
    }

    // 注入相关记忆（按 conversationId 隔离对话记忆）
    try {
      final memoryContext = _memoryService.buildMemoryContextSync(
        conversationId: conversationId,
      );
      if (memoryContext.isNotEmpty) {
        parts.add(memoryContext);
        logger.d('ChatService', '系统提示词注入记忆成功 conv=$conversationId memoryLen=${memoryContext.length}');
      } else {
        logger.d('ChatService', '系统提示词无记忆可注入（记忆为空）');
      }
    } catch (e) {
      logger.w('ChatService', '记忆注入失败 err=$e');
    }

    final result = parts.join('\n\n');
    logger.d('ChatService',
        '系统提示词构建完成 parts=${parts.length} totalLen=${result.length}');
    return result;
  }

  /// 流式聊天完成（SSE）
  Stream<String> _streamChatCompletion(List<Map<String, dynamic>> messages, {bool enableSearch = false}) async* {
    final logger = AppLogger();
    // 修复：先解析 API 配置，确保 HttpClient 已正确配置
    // 与 TextAnalysisService 保持一致，避免因未调用 applyToHttpClient 导致 isConfigured=false
    await ApiConfigResolver(_ref).applyToHttpClient(ApiFunctionType.text);

    final httpClient = _ref.read(sharedHttpClientProvider);
    if (!httpClient.isConfigured) {
      logger.e('ChatService', '_streamChatCompletion: HttpClient 未配置');
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = httpClient.currentConfig!;
    if (!config.supportsChat) {
      logger.e('ChatService',
          '_streamChatCompletion: provider=${config.name} 不支持对话');
      throw Exception('${config.displayName} 不支持对话');
    }
    logger.i('ChatService',
        '调用流式 API provider=${config.name} model=${config.defaultModel} messages=${messages.length} enableSearch=$enableSearch');

    // 计费检查
    final billingService = _ref.read(billingServiceProvider);
    if (httpClient.isCloudConfig) {
      final multiplier = httpClient.currentMultiplier;
      final totalChars = messages.fold<int>(0, (sum, m) {
        final content = m['content'] as String? ?? '';
        return sum + content.length;
      });
      logger.d('ChatService',
          '计费检查 cloudConfig=true totalChars=$totalChars multiplier=$multiplier');
      final canUse = await billingService.canUseFeature(
        FeatureType.aiChat,
        totalChars / 1000,
        multiplier: multiplier,
      );
      if (!canUse) {
        logger.w('ChatService', '计费检查未通过：套餐配额不足');
        throw Exception('套餐配额不足，请充值后再试');
      }
      logger.d('ChatService', '计费检查通过');
    } else {
      logger.d('ChatService', '本地配置，跳过计费检查');
    }

    // 全部国内 6 家 provider 均使用 OpenAI 兼容格式，统一走 _streamOpenAIStyle
    yield* _streamOpenAIStyle(messages, config, enableSearch: enableSearch);
  }

  Stream<String> _streamOpenAIStyle(
    List<Map<String, dynamic>> messages,
    AiModelConfig config, {
    bool enableSearch = false,
  }) async* {
    final logger = AppLogger();
    final httpClient = _ref.read(sharedHttpClientProvider);
    final dio = httpClient.dio;

    final requestStart = DateTime.now().millisecondsSinceEpoch;
    logger.d('ChatService',
        'POST /chat/completions model=${config.defaultModel} stream=true enableSearch=$enableSearch');

    final requestData = <String, dynamic>{
      'model': config.defaultModel,
      'messages': messages,
      'stream': true,
    };

    // 阿里云百炼（qwen）支持联网搜索，通过 enable_search 参数启用
    if (enableSearch && config.provider == AiProvider.qwen) {
      requestData['enable_search'] = true;
    }

    final response = await dio.post(
      '/chat/completions',
      data: requestData,
      options: Options(
        responseType: ResponseType.stream,
        // 增加流式读取超时，避免长时间无响应无反馈
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    logger.i('ChatService',
        'API 响应开始 status=${response.statusCode} 耗时=${DateTime.now().millisecondsSinceEpoch - requestStart}ms');

    Stream<List<int>>? byteStream;
    if (response.data is ResponseBody) {
      // Dio 在 responseType: stream 时返回 ResponseBody，需读取其 stream 字段
      final responseBody = response.data as ResponseBody;
      byteStream = responseBody.stream;
      logger.i('ChatService',
          '响应类型为 ResponseBody，使用 responseBody.stream 读取');
    } else if (response.data is Stream<List<int>>) {
      byteStream = response.data as Stream<List<int>>;
    }

    if (byteStream == null) {
      // 兜底：部分 provider 即使 stream=true 也返回完整 JSON，尝试按普通 completion 解析
      final nonStreamData = response.data;
      logger.w('ChatService',
          '响应不是流式数据 type=${nonStreamData.runtimeType}，尝试按普通 completion 解析');
      try {
        final Map<String, dynamic> json;
        if (nonStreamData is Map<String, dynamic>) {
          json = nonStreamData;
        } else {
          json = jsonDecode(nonStreamData.toString()) as Map<String, dynamic>;
        }
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            logger.i('ChatService', '非流式响应解析成功 contentLen=${content.length}');
            yield content;
            return;
          }
        }
        logger.e('ChatService', '非流式响应中未找到有效内容');
      } catch (e) {
        logger.e('ChatService', '非流式响应解析失败 data=$nonStreamData err=$e');
      }
      throw Exception('API 响应格式异常：非流式数据');
    }

    final stream = byteStream;
    var receivedBytes = 0;
    var yieldedChunks = 0;
    var parseErrors = 0;
    var doneReceived = false;
    // 按 SSE 事件边界缓存文本，避免 chunk 切分导致事件/UTF-8 字符被截断
    final eventBuffer = StringBuffer();
    final utf8Decoder = Utf8Decoder(allowMalformed: true);
    await for (final chunk in stream) {
      receivedBytes += chunk.length;
      eventBuffer.write(utf8Decoder.convert(chunk));

      // 以空行（\n\n）分隔 SSE 事件
      while (true) {
        final bufferText = eventBuffer.toString();
        final eventEnd = bufferText.indexOf('\n\n');
        if (eventEnd == -1) break;

        final eventText = bufferText.substring(0, eventEnd);
        eventBuffer.clear();
        if (eventEnd + 2 < bufferText.length) {
          eventBuffer.write(bufferText.substring(eventEnd + 2));
        }

        final lines = eventText.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              doneReceived = true;
              logger.d('ChatService', 'SSE [DONE] 收到');
              continue;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yieldedChunks++;
                  yield content;
                }
              }
            } catch (e) {
              parseErrors++;
              if (parseErrors <= 3) {
                logger.w('ChatService', 'SSE 解析失败 line="$data" err=$e');
              }
            }
          }
        }
      }
    }
    // 流结束后尝试处理缓存中剩余内容
    final remaining = eventBuffer.toString().trim();
    if (remaining.isNotEmpty) {
      logger.d('ChatService', '流结束剩余未处理文本: $remaining');
    }
    logger.i('ChatService',
        'SSE 流结束 receivedBytes=$receivedBytes yieldedChunks=$yieldedChunks parseErrors=$parseErrors done=$doneReceived');
  }
}

// Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    ref.watch(textAnalysisServiceProvider),
    ref.watch(memoryServiceProvider),
    ref,
  );
});
