import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_model_config.dart';
import '../models/realtime_transcription_result.dart';
import 'http_client.dart';
import 'app_logger.dart';

class RealtimeTranscriptionService {
  final HttpClient _httpClient;

  RealtimeTranscriptionService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  bool get isConfigured => _httpClient.isConfigured;

  Stream<RealtimeTranscriptionResult> transcribeRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) {
    if (!isConfigured) {
      throw Exception('API未配置，请先在设置中配置API Key');
    }

    final config = _httpClient.currentConfig!;
    AppLogger().i('Realtime', 'TranscribeRealtime: provider=${config.name}, method=${config.realtimeTranscriptionMethod}');

    if (!config.supportsRealtimeTranscription) {
      throw Exception(
          '${config.displayName} 不支持实时转写。请使用支持实时转写的提供商。');
    }

    switch (config.realtimeTranscriptionMethod) {
      case TranscriptionMethod.realtimeWebSocket:
        if (config.provider == AiProvider.qwen) {
          return _transcribeQwenRealtime(
            audioStream: audioStream,
            onStatusChange: onStatusChange,
          );
        } else if (config.provider == AiProvider.tingwu) {
          return _transcribeTingwuRealtime(
            audioStream: audioStream,
            onStatusChange: onStatusChange,
          );
        } else {
          throw Exception('${config.displayName} 不支持实时转写');
        }
      default:
        throw Exception('${config.displayName} 不支持实时转写');
    }
  }

  Stream<RealtimeTranscriptionResult> _transcribeQwenRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
  }) {
    onStatusChange?.call('connecting', '连接Qwen实时转写服务...');

    final wsUrl = _buildQwenWsUrl();
    final apiKey = _httpClient.apiKey!;
    AppLogger().i('Realtime', 'Connecting to Qwen WebSocket: $wsUrl');

    try {
      // 使用 headers 进行认证（Authorization: bearer apiKey）
      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'bearer $apiKey',
        },
      );
      AppLogger().i('Realtime', 'WebSocket channel created successfully');

      final controller = StreamController<RealtimeTranscriptionResult>();
      final completer = Completer<void>();
      var sessionConfigured = false;
      var conversationItemCreated = false;

      channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            AppLogger().d('Realtime', 'Qwen WS received: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');

            final type = data['type'] as String?;

            switch (type) {
              case 'session.created':
                AppLogger().i('Realtime', 'Qwen WS: session created');
                // 发送 session.update 配置会话
                // 关键：设置 modalities 为 ["text"] 禁用音频输出，只获取文本转写结果
                // 简化参数，只保留必要配置
                final sessionUpdate = {
                  'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}_update',
                  'type': 'session.update',
                  'session': {
                    'modalities': ['text'],
                    'input_audio_format': 'pcm',
                  },
                };
                AppLogger().i('Realtime', 'Sending session.update: ${jsonEncode(sessionUpdate)}');
                channel.sink.add(jsonEncode(sessionUpdate));
                break;

              case 'session.updated':
                AppLogger().i('Realtime', 'Qwen WS: session updated');
                sessionConfigured = true;
                onStatusChange?.call('connected', '已连接，开始发送音频...');
                // 音频数据发送后会自动触发 VAD 检测和转写
                // 不需要手动创建 conversation.item 或发送 response.create
                break;

              case 'conversation.item.created':
                AppLogger().i('Realtime', 'Qwen WS: conversation item created');
                conversationItemCreated = true;
                break;

              case 'conversation.item.input_audio_transcription.completed':
                final item = data['item'] as Map<String, dynamic>?;
                if (item != null) {
                  final content = item['content'] as List<dynamic>?;
                  if (content != null && content.isNotEmpty) {
                    final text = content[0]['text'] as String? ?? '';
                    if (text.isNotEmpty) {
                      AppLogger().i('Realtime', 'Qwen WS result: "$text"');
                      controller.add(RealtimeTranscriptionResult(
                        text: text,
                        isFinal: true,
                        beginTime: Duration.zero,
                        endTime: Duration.zero,
                      ));
                    }
                  }
                }
                break;

              case 'input_audio_buffer.speech_started':
                AppLogger().i('Realtime', 'Qwen WS: speech started');
                break;

              case 'input_audio_buffer.speech_stopped':
                AppLogger().i('Realtime', 'Qwen WS: speech stopped');
                break;

              case 'conversation.item.input_audio_transcription.text':
                // 实时转写结果
                // text: 完整转写文本（包含所有历史句子）
                // stash: 当前正在识别的句子片段
                final fullText = data['text'] as String? ?? '';
                final stash = data['stash'] as String? ?? '';
                
                if (fullText.isNotEmpty) {
                  AppLogger().i('Realtime', 'Qwen WS full text: "$fullText"');
                  // 发送完整文本给UI显示
                  controller.add(RealtimeTranscriptionResult(
                    text: fullText,
                    isFinal: false,
                    beginTime: Duration.zero,
                    endTime: Duration.zero,
                  ));
                } else if (stash.isNotEmpty) {
                  // 备用：如果没有fullText，使用stash
                  AppLogger().i('Realtime', 'Qwen WS stash: "$stash"');
                  controller.add(RealtimeTranscriptionResult(
                    text: stash,
                    isFinal: false,
                    beginTime: Duration.zero,
                    endTime: Duration.zero,
                  ));
                }
                break;

              // 添加更多可能的事件类型
              case 'response.created':
                AppLogger().i('Realtime', 'Qwen WS: response created');
                break;

              case 'response.done':
                AppLogger().i('Realtime', 'Qwen WS: response done');
                break;

              case 'conversation.item.created':
                AppLogger().i('Realtime', 'Qwen WS: conversation item created');
                break;

              case 'response.content_part.added':
                final part = data['part'] as Map<String, dynamic>?;
                if (part != null) {
                  final text = part['text'] as String? ?? '';
                  if (text.isNotEmpty) {
                    AppLogger().i('Realtime', 'Qwen WS content: "$text"');
                    controller.add(RealtimeTranscriptionResult(
                      text: text,
                      isFinal: false,
                      beginTime: Duration.zero,
                      endTime: Duration.zero,
                    ));
                  }
                }
                break;

              case 'response.audio_transcript.delta':
                final delta = data['delta'] as String? ?? '';
                if (delta.isNotEmpty) {
                  AppLogger().i('Realtime', 'Qwen WS transcript delta: "$delta"');
                  controller.add(RealtimeTranscriptionResult(
                    text: delta,
                    isFinal: false,
                    beginTime: Duration.zero,
                    endTime: Duration.zero,
                  ));
                }
                break;

              case 'response.audio_transcript.done':
                final transcript = data['transcript'] as String? ?? '';
                if (transcript.isNotEmpty) {
                  AppLogger().i('Realtime', 'Qwen WS transcript done: "$transcript"');
                  controller.add(RealtimeTranscriptionResult(
                    text: transcript,
                    isFinal: true,
                    beginTime: Duration.zero,
                    endTime: Duration.zero,
                  ));
                }
                break;

              case 'error':
                final errorMsg = data['error']?['message'] as String? ?? '未知错误';
                AppLogger().e('Realtime', 'Qwen WS error: $errorMsg');
                onStatusChange?.call('error', '转写错误: $errorMsg');
                break;

              default:
                AppLogger().d('Realtime', 'Qwen WS: unknown event type - $type');
                // 打印完整消息以便调试
                AppLogger().d('Realtime', 'Full message: ${jsonEncode(data)}');
            }
          } catch (e) {
            AppLogger().e('Realtime', 'Error parsing Qwen WS message: $e');
          }
        },
        onError: (error) {
          AppLogger().e('Realtime', 'Qwen WS error: $error');
          onStatusChange?.call('error', '连接错误: $error');
          controller.addError(error);
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          AppLogger().i('Realtime', 'Qwen WS closed');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      // 监听音频流并发送到 WebSocket（Base64编码）
      var chunkCount = 0;
      audioStream.listen(
        (audioChunk) {
          if (audioChunk.isNotEmpty && sessionConfigured) {
            chunkCount++;
            // 发送 input_audio_buffer.append 事件（Base64编码）
            final appendMessage = {
              'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
              'type': 'input_audio_buffer.append',
              'audio': base64Encode(audioChunk),
            };
            if (chunkCount <= 5 || chunkCount % 50 == 0) {
              AppLogger().i('Realtime', 'Sending audio chunk #$chunkCount, size: ${audioChunk.length} bytes');
            }
            channel.sink.add(jsonEncode(appendMessage));
          }
        },
        onDone: () {
          AppLogger().i('Realtime', 'Audio stream done');
          // 发送 input_audio_buffer.commit 事件
          final commitMessage = {
            'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'input_audio_buffer.commit',
          };
          AppLogger().i('Realtime', 'Sending input_audio_buffer.commit');
          channel.sink.add(jsonEncode(commitMessage));

          Future.delayed(const Duration(seconds: 2), () {
            if (!completer.isCompleted) {
              completer.complete();
            }
          });
        },
        onError: (e) {
          AppLogger().e('Realtime', 'Audio stream error: $e');
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
      );

      completer.future.then((_) {
        AppLogger().i('Realtime', 'Closing controller');
        controller.close();
        channel.sink.close();
      }).catchError((e) {
        AppLogger().e('Realtime', 'Completer error: $e');
        controller.close();
        channel.sink.close();
      });

      return controller.stream;
    } catch (e) {
      AppLogger().e('Realtime', 'Failed to create WebSocket connection: $e');
      onStatusChange?.call('error', 'WebSocket连接失败: $e');
      final controller = StreamController<RealtimeTranscriptionResult>();
      controller.addError(e);
      controller.close();
      return controller.stream;
    }
  }

  String _buildQwenWsUrl() {
    // Qwen-Omni-Realtime 正确的 WebSocket 端点
    // 官方文档: wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=xxx
    // 认证方式: Authorization header (bearer apiKey)
    // 关键：必须在URL中添加model查询参数！
    return 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime';
  }

  Stream<RealtimeTranscriptionResult> _transcribeTingwuRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
  }) async* {
    onStatusChange?.call('connecting', '连接听悟实时转写服务...');

    // 通义听悟实时转写使用 DashScope WebSocket 端点
    // 官方文档: wss://dashscope.aliyuncs.com/api-ws/v1/inference
    // 需要设置 model 参数为 tingwu-realtime
    final wsUrl = 'wss://dashscope.aliyuncs.com/api-ws/v1/inference?model=tingwu-realtime';
    AppLogger().i('Realtime', 'Connecting to Tingwu WebSocket: $wsUrl');
    AppLogger().i('Realtime', 'WebSocket URL protocol: ${Uri.parse(wsUrl).scheme}');

    final channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {
        'Authorization': 'bearer ${_httpClient.apiKey}',
      },
    );
    onStatusChange?.call('connected', '已连接，开始发送音频...');

    try {
      final completer = Completer<void>();
      final controller = StreamController<RealtimeTranscriptionResult>();

      channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            debugPrint('Tingwu WS received: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');

            final result = data['result'] as Map<String, dynamic>?;
            if (result != null) {
              final text = result['text'] as String? ?? '';
              final isFinal = result['is_final'] as bool? ?? false;
              final beginTime = Duration(
                  milliseconds: result['begin_time'] as int? ?? 0);
              final endTime = Duration(
                  milliseconds: result['end_time'] as int? ?? 0);

              if (text.isNotEmpty) {
                controller.add(RealtimeTranscriptionResult(
                  text: text,
                  isFinal: isFinal,
                  beginTime: beginTime,
                  endTime: endTime,
                ));
              }
            }

            final status = data['status'] as String?;
            if (status == 'completed') {
              debugPrint('Tingwu WS: transcription complete');
              onStatusChange?.call('complete', '转写完成');
              completer.complete();
            }
          } catch (e) {
            debugPrint('Error parsing Tingwu WS message: $e');
          }
        },
        onError: (error) {
          debugPrint('Tingwu WS error: $error');
          onStatusChange?.call('error', '连接错误: $error');
          completer.completeError(error);
        },
        onDone: () {
          debugPrint('Tingwu WS closed');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await for (final audioChunk in audioStream) {
        if (audioChunk.isNotEmpty) {
          channel.sink.add(audioChunk);
        }
      }

      await completer.future;
      await controller.close();
    } finally {
      channel.sink.close();
    }
  }
}
