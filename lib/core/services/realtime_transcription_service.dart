import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_model_config.dart';
import '../models/realtime_transcription_result.dart';
import 'http_client.dart';
import 'app_logger.dart';
import 'tingwu_service.dart';

class RealtimeTranscriptionService {
  final HttpClient _httpClient;
  late final TingwuService _tingwuService;

  RealtimeTranscriptionService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient() {
    _tingwuService = TingwuService(httpClient: _httpClient);
  }

  bool get isConfigured => _httpClient.isConfigured;

  Stream<RealtimeTranscriptionResult> transcribeRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    final config = _httpClient.currentConfig;
    if (config == null) {
      throw Exception('未配置语音识别服务');
    }

    if (config.name == 'tingwu') {
      yield* _transcribeTingwuRealtime(
        audioStream: audioStream,
        onStatusChange: onStatusChange,
        language: language,
      );
    } else if (config.name == 'qwen') {
      yield* _transcribeQwenRealtime(
        audioStream: audioStream,
        onStatusChange: onStatusChange,
        language: language,
      );
    } else {
      throw Exception('不支持的实时转写服务: ${config.name}');
    }
  }

  Stream<RealtimeTranscriptionResult> _transcribeQwenRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    onStatusChange?.call('connecting', '连接通义千问实时转写服务...');

    final wsUrl = _getQwenRealtimeWsUrl();
    AppLogger().i('Realtime', 'Connecting to Qwen WebSocket: $wsUrl');
    AppLogger().i('Realtime', 'WebSocket URL protocol: ${Uri.parse(wsUrl).scheme}');

    final channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {
        'Authorization': 'Bearer ${_httpClient.apiKey}',
        'user-agent': 'changji-app/1.0',
      },
    );

    onStatusChange?.call('connected', '已连接，开始发送音频...');

    final sessionId = const Uuid().v4();
    final completer = Completer<void>();
    final controller = StreamController<RealtimeTranscriptionResult>();
    StreamSubscription? wsSubscription;
    StreamSubscription? audioSubscription;

    // 发送 session.update 事件
    final sessionUpdate = {
      'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'session.update',
      'session': {
        'input_audio_format': 'pcm',
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 500,
        },
        'input_audio_transcription': {
          'model': 'qwen3-asr-flash-realtime',
        },
      },
    };

    AppLogger().i('Realtime', 'Sending session.update: ${jsonEncode(sessionUpdate)}');
    channel.sink.add(jsonEncode(sessionUpdate));

    // 监听 WebSocket 消息
    wsSubscription = channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String);
          AppLogger().d('Realtime', 'Qwen WS received: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');

          final eventType = data['type'] as String?;

          switch (eventType) {
            case 'session.created':
              AppLogger().i('Realtime', 'Qwen WS: session created');
              break;

            case 'session.updated':
              AppLogger().i('Realtime', 'Qwen WS: session updated');
              break;

            case 'input_audio_buffer.speech_started':
              AppLogger().i('Realtime', 'Qwen WS: speech started');
              break;

            case 'input_audio_buffer.speech_stopped':
              AppLogger().i('Realtime', 'Qwen WS: speech stopped');
              break;

            case 'input_audio_buffer.committed':
              AppLogger().i('Realtime', 'Qwen WS: audio buffer committed');
              break;

            case 'conversation.item.created':
              AppLogger().i('Realtime', 'Qwen WS: conversation item created');
              break;

            case 'conversation.item.input_audio_transcription.text':
              final stash = data['stash'] as String? ?? '';
              if (stash.isNotEmpty) {
                AppLogger().i('Realtime', 'Qwen WS stash: "$stash"');
              }
              break;

            case 'conversation.item.input_audio_transcription.completed':
              final transcript = data['transcript'] as String? ?? '';
              final itemId = data['item_id'] as String? ?? '';
              AppLogger().i('Realtime', 'Qwen WS full text: "$transcript"');

              if (transcript.isNotEmpty) {
                final result = RealtimeTranscriptionResult(
                  text: transcript,
                  isFinal: true,
                  beginTime: Duration.zero,
                  endTime: Duration.zero,
                );
                controller.add(result);
                AppLogger().i('Realtime', 'Result: "$transcript", isFinal: true');
              }
              break;

            case 'conversation.item.input_audio_transcription.failed':
              AppLogger().e('Realtime', 'Qwen WS: transcription failed');
              break;

            case 'error':
              final error = data['error'] as Map<String, dynamic>?;
              final errorMsg = error?['message'] ?? 'Unknown error';
              AppLogger().e('Realtime', 'Qwen WS error: $errorMsg');
              onStatusChange?.call('error', errorMsg.toString());
              break;

            default:
              AppLogger().d('Realtime', 'Qwen WS: unknown event type - $eventType');
          }
        } catch (e) {
          AppLogger().e('Realtime', 'Error parsing Qwen message: $e');
        }
      },
      onError: (error) {
        AppLogger().e('Realtime', 'Qwen WS error: $error');
        onStatusChange?.call('error', '连接错误: $error');
        completer.completeError(error);
      },
      onDone: () {
        AppLogger().i('Realtime', 'Qwen WS closed');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    // 发送音频数据
    audioSubscription = audioStream.listen(
      (chunk) {
        if (chunk.isNotEmpty) {
          // 发送音频数据
          final audioEvent = {
            'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'input_audio_buffer.append',
            'audio': base64Encode(chunk),
          };
          channel.sink.add(jsonEncode(audioEvent));
        }
      },
      onDone: () {
        // 音频发送完成，发送 finish 事件
        final finishEvent = {
          'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'session.finish',
        };
        channel.sink.add(jsonEncode(finishEvent));
      },
      onError: (error) {
        AppLogger().e('Realtime', 'Audio stream error: $error');
        onStatusChange?.call('error', '音频流错误: $error');
      },
    );

    try {
      yield* controller.stream;
      await completer.future;
    } finally {
      await audioSubscription?.cancel();
      await wsSubscription?.cancel();
      await channel.sink.close();
      await controller.close();
    }
  }

  String _getQwenRealtimeWsUrl() {
    // 通义千问实时转写 WebSocket 端点
    // 官方文档: wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime
    // 关键：必须在URL中添加model查询参数！
    return 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime';
  }

  Stream<RealtimeTranscriptionResult> _transcribeTingwuRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    onStatusChange?.call('connecting', '连接听悟实时转写服务...');

    try {
      // 1. 先创建实时会议，获取 WebSocket 连接信息
      final meetingInfo = await _tingwuService.createMeeting(
        audioFormat: 'pcm',
        sampleRate: 16000,
        language: 'cn',
        realtimeResultEnabled: true,
        realtimeResultLevel: 2,
        diarizationEnabled: true,
      );

      AppLogger().i('Realtime', 'Meeting created: ${meetingInfo.meetingId}');
      AppLogger().i('Realtime', 'WS URL: ${meetingInfo.wsUrl}');
      AppLogger().i('Realtime', 'Has token: ${meetingInfo.token.isNotEmpty}');

      if (meetingInfo.wsUrl.isEmpty) {
        throw Exception('获取 WebSocket 连接地址失败');
      }

      // 2. 连接 WebSocket
      final wsUrl = meetingInfo.wsUrl;
      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer ${meetingInfo.token}',
        },
      );

      onStatusChange?.call('connected', '已连接，开始发送音频...');

      // 3. 发送 StartTranscription 指令（NLS 协议）
      final taskId = _generateTaskId();
      final startTranscriptionMessage = {
        'header': {
          'appkey': _httpClient.appId,
          'message_id': _generateMessageId(),
          'task_id': taskId,
          'namespace': 'SpeechTranscriber',
          'name': 'StartTranscription',
        },
        'payload': {
          'format': 'pcm',
          'sample_rate': 16000,
          'enable_intermediate_result': true,
          'enable_punctuation_prediction': true,
          'enable_inverse_text_normalization': true,
          'disfluency_removal': true,
          'special_word_filter': '***',
        },
      };

      AppLogger().i('Realtime', 'Sending StartTranscription: ${jsonEncode(startTranscriptionMessage)}');
      channel.sink.add(jsonEncode(startTranscriptionMessage));

      // 4. 等待服务器确认后开始发送音频
      final completer = Completer<void>();
      final controller = StreamController<RealtimeTranscriptionResult>();
      var isTaskStarted = false;
      StreamSubscription? audioSubscription;
      StreamSubscription? wsSubscription;

      // 监听 WebSocket 消息
      wsSubscription = channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            AppLogger().d('Realtime', 'Tingwu WS received: $data');

            // 处理响应
            final header = data['header'] as Map<String, dynamic>?;
            final payload = data['payload'] as Map<String, dynamic>?;
            
            // 提取 name 用于后续处理
            final eventName = header?['name'] as String?;

            if (header != null) {
              final status = header['status'] as int?;
              final statusText = header['status_text'] as String?;
              
              if (eventName == 'TranscriptionStarted') {
                AppLogger().i('Realtime', 'Transcription started successfully');
                isTaskStarted = true;
                // 开始发送音频数据
                audioSubscription = _startAudioStream(audioStream, channel, taskId, controller, completer);
              } else if (eventName == 'TranscriptionCompleted') {
                AppLogger().i('Realtime', 'Transcription completed');
                onStatusChange?.call('complete', '转写完成');
                if (!completer.isCompleted) {
                  completer.complete();
                }
              } else if (eventName == 'TaskFailed') {
                AppLogger().e('Realtime', 'Tingwu TaskFailed: $statusText');
                onStatusChange?.call('error', statusText ?? '任务失败');
                if (!completer.isCompleted) {
                  completer.completeError(statusText ?? '任务失败');
                }
              } else if (eventName == 'SentenceBegin') {
                AppLogger().i('Realtime', 'Sentence begin');
              } else if (eventName == 'SentenceEnd') {
                AppLogger().i('Realtime', 'Sentence end');
              }
            }

            // 处理转写结果
            if (payload != null) {
              final result = payload['result'] as String? ?? '';
              final beginTime = payload['begin_time'] as int? ?? 0;
              final endTime = payload['end_time'] as int? ?? 0;
              final index = payload['index'] as int? ?? 0;
              
              if (result.isNotEmpty) {
                AppLogger().i('Realtime', 'Tingwu result [$eventName]: "$result"');
                
                // 根据事件类型设置 isFinal
                final isFinal = eventName == 'SentenceEnd' || eventName == 'TranscriptionCompleted';
                
                controller.add(RealtimeTranscriptionResult(
                  text: result,
                  isFinal: isFinal,
                  beginTime: Duration(milliseconds: beginTime),
                  endTime: Duration(milliseconds: endTime),
                ));
              }
            }
          } catch (e) {
            AppLogger().e('Realtime', 'Error parsing Tingwu message: $e');
          }
        },
        onError: (error) {
          AppLogger().e('Realtime', 'Tingwu WS error: $error');
          onStatusChange?.call('error', '连接错误: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          AppLogger().i('Realtime', 'Tingwu WS closed');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      try {
        yield* controller.stream;
        await completer.future;
      } finally {
        await audioSubscription?.cancel();
        await wsSubscription?.cancel();
        await channel.sink.close();
        await controller.close();
      }
    } catch (e) {
      AppLogger().e('Realtime', 'Tingwu realtime error: $e');
      onStatusChange?.call('error', '通义听悟实时转写失败: $e');
      rethrow;
    }
  }

  StreamSubscription _startAudioStream(
    Stream<List<int>> audioStream,
    IOWebSocketChannel channel,
    String taskId,
    StreamController<RealtimeTranscriptionResult> controller,
    Completer<void> completer,
  ) {
    AppLogger().i('Realtime', 'Starting audio stream...');

    // 注意：web_socket_channel 会自动处理 WebSocket ping-pong
    // 不需要手动发送心跳包

    return audioStream.listen(
      (chunk) {
        if (chunk.isNotEmpty) {
          // 直接发送音频数据 - 使用二进制帧
          // record 插件的 startStream 返回的是裸 PCM 数据
          channel.sink.add(Uint8List.fromList(chunk));
          AppLogger().d('Realtime', 'Sending audio chunk: ${chunk.length} bytes');
        }
      },
      onDone: () {
        AppLogger().i('Realtime', 'Audio stream done');
        
        // 发送 StopTranscription 指令
        final stopMessage = {
          'header': {
            'appkey': _httpClient.appId,
            'message_id': _generateMessageId(),
            'task_id': taskId,
            'namespace': 'SpeechTranscriber',
            'name': 'StopTranscription',
          },
        };
        channel.sink.add(jsonEncode(stopMessage));
      },
      onError: (error) {
        AppLogger().e('Realtime', 'Audio stream error: $error');
      },
    );
  }

  String _generateTaskId() {
    // NLS 协议要求 32 位十六进制字符串（不含连字符）
    // 例如: 802738f37fb24459bbe7b241210e19b8
    final uuid = const Uuid().v4().replaceAll('-', '');
    return uuid;
  }

  String _generateMessageId() {
    // NLS 协议要求 32 位十六进制字符串（不含连字符）
    final uuid = const Uuid().v4().replaceAll('-', '');
    return uuid;
  }
}