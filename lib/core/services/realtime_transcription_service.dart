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

  /// 带自动重连的长录音实时转写
  ///
  /// Qwen 实时转写 WebSocket 服务端限制约 10 分钟，因此：
  /// - 每 9 分钟主动断开当前连接
  /// - 携带 15 秒重叠音频缓冲区建立新连接
  /// - 多段结果自动拼接，用户无感知
  Stream<RealtimeTranscriptionResult> transcribeRealtimeWithReconnect({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
    Duration maxSessionDuration = const Duration(minutes: 9),
    Duration overlapDuration = const Duration(seconds: 15),
  }) async* {
    final config = _httpClient.currentConfig;
    if (config == null) {
      throw Exception('未配置语音识别服务');
    }

    if (config.name != 'qwen') {
      // 目前仅 Qwen 需要重连策略，其他服务走原逻辑
      yield* transcribeRealtime(
        audioStream: audioStream,
        onStatusChange: onStatusChange,
        language: language,
      );
      return;
    }

    AppLogger().i('Realtime', '=== 启动带重连的实时转写 ===');

    final controller = StreamController<RealtimeTranscriptionResult>();
    final audioBuffer = <List<int>>[];
    final overlapBytes = _overlapBytesForDuration(overlapDuration);
    var sessionCount = 0;
    StreamSubscription? audioSubscription;
    var isActive = true;
    Timer? sessionTimer;
    var currentSessionCompleter = Completer<void>();

    Future<void> startNewSession({List<int>? initialAudio}) async {
      if (!isActive) return;
      sessionCount++;
      AppLogger().i('Realtime', '启动第 $sessionCount 个实时转写会话');

      // 为当前会话创建独立的音频流
      final sessionController = StreamController<List<int>>();
      final sessionBuffer = <List<int>>[];

      // 先发送重叠音频（如果有）
      if (initialAudio != null && initialAudio.isNotEmpty) {
        AppLogger().i('Realtime', '发送 ${initialAudio.length} 字节重叠音频');
        sessionController.add(initialAudio);
      }

      // 订阅音频流：把新数据同时发给当前会话和全局缓冲区
      audioSubscription?.cancel();
      audioSubscription = audioStream.listen(
        (chunk) {
          if (!isActive) return;
          sessionController.add(chunk);
          sessionBuffer.add(chunk);
          audioBuffer.add(chunk);
          // 限制全局缓冲区大小，避免内存无限增长
          while (_totalBytes(audioBuffer) > overlapBytes * 4) {
            audioBuffer.removeAt(0);
          }
        },
        onError: (e) {
          AppLogger().e('Realtime', '音频流错误: $e');
          sessionController.addError(e);
        },
        onDone: () {
          if (!sessionController.isClosed) {
            sessionController.close();
          }
        },
      );

      // 启动会话定时器：9分钟后启动新会话
      sessionTimer?.cancel();
      sessionTimer = Timer(maxSessionDuration - overlapDuration, () {
        AppLogger().i('Realtime', '会话即将到期，准备带重叠重连');
        // 提取最近 15 秒音频作为重叠
        final overlapAudio = _extractRecentAudio(audioBuffer, overlapBytes);
        sessionController.close();
        startNewSession(initialAudio: overlapAudio);
      });

      try {
        await for (final result in _transcribeQwenRealtime(
          audioStream: sessionController.stream,
          onStatusChange: onStatusChange,
          language: language,
          autoCloseOnDone: false,
        )) {
          if (!controller.isClosed) {
            controller.add(result);
          }
        }
      } catch (e) {
        AppLogger().e('Realtime', '第 $sessionCount 个会话异常: $e');
        onStatusChange?.call('error', '转写会话异常: $e');
      }
    }

    // 启动第一个会话
    unawaited(startNewSession().then((_) {
      if (!currentSessionCompleter.isCompleted) {
        currentSessionCompleter.complete();
      }
    }));

    try {
      yield* controller.stream;
    } finally {
      isActive = false;
      sessionTimer?.cancel();
      audioSubscription?.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  /// 估算指定时长的音频字节数（16kHz 16bit 单声道 PCM = 32000 字节/秒）
  static int _overlapBytesForDuration(Duration duration) {
    return duration.inMilliseconds * 32; // 32000 bytes / 1000 ms
  }

  static int _totalBytes(List<List<int>> chunks) {
    return chunks.fold(0, (sum, c) => sum + c.length);
  }

  static List<int> _extractRecentAudio(List<List<int>> buffer, int maxBytes) {
    final result = <int>[];
    for (var i = buffer.length - 1; i >= 0; i--) {
      result.insertAll(0, buffer[i]);
      if (result.length >= maxBytes) {
        return result.sublist(result.length - maxBytes);
      }
    }
    return result;
  }

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
    bool autoCloseOnDone = true,
  }) async* {
    onStatusChange?.call('connecting', '连接通义千问实时转写服务...');

    final wsUrl = _getQwenRealtimeWsUrl();
    AppLogger().i('Realtime', 'Connecting to Qwen WebSocket: $wsUrl');
    AppLogger().i('Realtime', 'WebSocket URL protocol: ${Uri.parse(wsUrl).scheme}');

    final channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {
        'Authorization': 'Bearer ${_httpClient.apiKey}',
        'OpenAI-Beta': 'realtime=v1',
        'user-agent': 'changji-app/1.0',
      },
    );

    onStatusChange?.call('connected', '已连接，开始发送音频...');

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
        if (autoCloseOnDone) {
          onStatusChange?.call('disconnected', '实时转写连接已断开');
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    // 发送音频数据
    audioSubscription = audioStream.listen(
      (chunk) {
        if (chunk.isNotEmpty) {
          final audioEvent = {
            'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'input_audio_buffer.append',
            'audio': base64Encode(chunk),
          };
          channel.sink.add(jsonEncode(audioEvent));
        }
      },
      onDone: () {
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
    return 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime';
  }

  Stream<RealtimeTranscriptionResult> _transcribeTingwuRealtime({
    required Stream<List<int>> audioStream,
    void Function(String status, String detail)? onStatusChange,
    String? language,
  }) async* {
    onStatusChange?.call('connecting', '连接听悟实时转写服务...');

    try {
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

      final wsUrl = meetingInfo.wsUrl;
      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer ${meetingInfo.token}',
        },
      );

      onStatusChange?.call('connected', '已连接，开始发送音频...');

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

      final completer = Completer<void>();
      final controller = StreamController<RealtimeTranscriptionResult>();
      var isTaskStarted = false;
      StreamSubscription? audioSubscription;
      StreamSubscription? wsSubscription;

      wsSubscription = channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            AppLogger().d('Realtime', 'Tingwu WS received: $data');

            final header = data['header'] as Map<String, dynamic>?;
            final payload = data['payload'] as Map<String, dynamic>?;
            final eventName = header?['name'] as String?;

            if (header != null) {
              final status = header['status'] as int?;
              final statusText = header['status_text'] as String?;

              if (eventName == 'TranscriptionStarted') {
                AppLogger().i('Realtime', 'Transcription started successfully');
                isTaskStarted = true;
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

            if (payload != null) {
              final result = payload['result'] as String? ?? '';
              final beginTime = payload['begin_time'] as int? ?? 0;
              final endTime = payload['end_time'] as int? ?? 0;

              if (result.isNotEmpty) {
                AppLogger().i('Realtime', 'Tingwu result [$eventName]: "$result"');
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
          onStatusChange?.call('disconnected', '听悟实时转写连接已断开');
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

    final heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      try {
        final silentFrame = Uint8List(320);
        channel.sink.add(silentFrame);
        AppLogger().d('Realtime', 'Heartbeat: sent 320 bytes silence');
      } catch (e) {
        AppLogger().w('Realtime', 'Heartbeat failed: $e');
      }
    });

    return audioStream.listen(
      (chunk) {
        if (chunk.isNotEmpty) {
          channel.sink.add(Uint8List.fromList(chunk));
          AppLogger().d('Realtime', 'Sending audio chunk: ${chunk.length} bytes');
        }
      },
      onDone: () {
        AppLogger().i('Realtime', 'Audio stream done');
        heartbeatTimer.cancel();

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
        heartbeatTimer.cancel();
      },
    );
  }

  String _generateTaskId() {
    final uuid = const Uuid().v4().replaceAll('-', '');
    return uuid;
  }

  String _generateMessageId() {
    final uuid = const Uuid().v4().replaceAll('-', '');
    return uuid;
  }
}
