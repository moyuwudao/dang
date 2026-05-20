import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/aliyun_signer.dart';
import 'http_client.dart';
import 'app_logger.dart';

/// 通义听悟服务
///
/// 提供通义听悟 API 的完整调用能力：
/// - 提交转写任务（支持说话人分离、摘要、待办等）
/// - 查询任务状态
/// - 获取转写结果
///
/// API 文档: https://tingwu.aliyun.com/helpcenter/api
class TingwuService {
  final HttpClient _httpClient;
  final AppLogger _logger = AppLogger();
  AliyunSigner? _signer;

  static const String _baseUrl = 'https://tingwu.cn-beijing.aliyuncs.com';

  TingwuService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient() {
    _initSigner();
  }

  void _initSigner() {
    final config = _httpClient.currentConfig;
    final accessKeyId = _httpClient.apiKey;
    final accessKeySecret = _httpClient.accessKeySecret;

    if (config != null &&
        accessKeyId != null &&
        accessKeyId.isNotEmpty &&
        accessKeySecret != null &&
        accessKeySecret.isNotEmpty) {
      _signer = AliyunSigner(
        accessKeyId: accessKeyId,
        accessKeySecret: accessKeySecret,
      );
      _log('Signer auto-initialized with AccessKeyId: ${accessKeyId.substring(0, accessKeyId.length > 8 ? 8 : accessKeyId.length)}...');
    } else {
      _signer = null;
      if (config != null) {
        _log('Signer not initialized: missing AccessKeyId or AccessKeySecret');
      }
    }
  }

  void _log(String message) {
    _logger.i('Tingwu', message);
  }

  /// 设置阿里云签名凭证
  ///
  /// [accessKeyId] 阿里云 AccessKey ID
  /// [accessKeySecret] 阿里云 AccessKey Secret
  void setCredentials(String accessKeyId, String accessKeySecret) {
    _signer = AliyunSigner(
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
    );
    _log('Credentials set for AccessKeyId: $accessKeyId');
  }

  /// 提交离线文件转写任务
  ///
  /// [fileUrl] 音频文件 URL（必须是公网可访问的 URL）
  /// [fileName] 文件名（可选）
  /// [enableDiarization] 是否开启说话人分离
  /// [speakerCount] 说话人数量：0=不定人数, 2=2人
  /// [enableSummarization] 是否开启全文摘要
  /// [enableChapter] 是否开启章节速览
  /// [enableSpeakerSummarization] 是否开启发言总结（需开启说话人分离）
  /// [enableTodo] 是否开启待办提取
  /// [enableKeywords] 是否开启关键词提取
  /// [enablePpt] 是否开启 PPT 抽取
  /// [enableTranslation] 是否开启翻译
  /// [translationLang] 翻译目标语言：zh=中文, en=英文, ja=日文
  Future<String> submitTask({
    required String fileUrl,
    String? fileName,
    bool enableDiarization = true,
    int speakerCount = 0,
    bool enableSummarization = true,
    bool enableChapter = true,
    bool enableSpeakerSummarization = true,
    bool enableTodo = true,
    bool enableKeywords = true,
    bool enablePpt = false,
    bool enableTranslation = false,
    String? translationLang,
  }) async {
    _log('Submitting Tingwu task for: $fileUrl');

    final appId = _httpClient.appId;

    if (appId == null || appId.isEmpty) {
      throw Exception('通义听悟需要配置 AppKey，请在设置中填写');
    }

    final url = '$_baseUrl/openapi/tingwu/v2/tasks';

    // 构建输入参数
    final input = <String, dynamic>{
      'FileUrl': fileUrl,
      if (fileName != null) 'SourceLanguage': 'auto',
    };

    // 构建参数
    final parameters = <String, dynamic>{
      if (enableDiarization) ...{
        'Transcription': {
          'DiarizationEnabled': true,
          'Diarization': {
            'SpeakerCount': speakerCount,
          },
        },
      },
      if (enableSummarization) ...{
        'Summarization': {
          'Types': ['Paragraph', 'Conversational', 'QuestionsAnswering', 'Chapter'],
        },
      },
      if (enableChapter) ...{
        'Summarization': {
          'Types': ['Paragraph', 'Conversational', 'QuestionsAnswering', 'Chapter'],
        },
      },
      if (enableSpeakerSummarization && enableDiarization) ...{
        'Summarization': {
          'Types': ['Paragraph', 'Conversational', 'QuestionsAnswering', 'Chapter'],
        },
      },
      if (enableTodo) ...{
        'MeetingAssistance': {
          'Types': ['Actions'],
        },
      },
      if (enableKeywords) ...{
        'MeetingAssistance': {
          'Types': ['Actions', 'KeyInformation'],
        },
      },
      if (enablePpt) ...{
        'PptExtraction': {
          'Types': ['ppt'],
        },
      },
      if (enableTranslation && translationLang != null) ...{
        'Translation': {
          'TargetLanguages': [translationLang],
        },
      },
    };

    // 合并 Summarization 和 MeetingAssistance
    final mergedParameters = _mergeParameters(parameters);

    final body = {
      'AppKey': appId,
      'Input': input,
      'Parameters': mergedParameters,
    };

    _log('Request body: ${jsonEncode(body)}');

    try {
      if (_signer == null) {
        throw Exception('阿里云签名未配置，请先调用 setCredentials()');
      }

      final bodyJson = jsonEncode(body);
      final path = '/openapi/tingwu/v2/tasks';
      final queryParams = {'type': 'offline'};

      final signedHeaders = _signer!.signRoaRequest(
        method: 'PUT',
        path: path,
        queryParams: queryParams,
        body: bodyJson,
      );

      final url = '$_baseUrl$path';
      _log('Request URL: $url');

      final dio = Dio();
      final response = await dio.put(
        url,
        data: bodyJson,
        queryParameters: queryParams,
        options: Options(headers: signedHeaders),
      );

      _log('Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final taskId = data['Data']?['TaskId'] as String?;
        if (taskId != null) {
          _log('Task submitted successfully: $taskId');
          return taskId;
        }
      }

      throw Exception('提交任务失败: ${response.data}');
    } catch (e) {
      _log('Error submitting task: $e');
      rethrow;
    }
  }

  /// 查询任务状态
  ///
  /// 返回任务状态：PENDING | RUNNING | SUCCESS | FAILED
  Future<TingwuTaskStatus> queryTask(String taskId) async {
    _log('Querying task: $taskId');

    final appId = _httpClient.appId;

    try {
      if (_signer == null) {
        throw Exception('阿里云签名未配置，请先调用 setCredentials()');
      }

      final path = '/openapi/tingwu/v2/tasks/$taskId';

      final signedHeaders = _signer!.signRoaRequest(
        method: 'GET',
        path: path,
      );

      final url = '$_baseUrl$path';
      _log('Query URL: $url');

      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(headers: signedHeaders),
      );

      _log('Query response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final taskData = data['Data'];
        if (taskData != null) {
          return TingwuTaskStatus.fromJson(taskData);
        }
      }

      throw Exception('查询任务失败: ${response.data}');
    } catch (e) {
      _log('Error querying task: $e');
      rethrow;
    }
  }

  /// 等待任务完成并获取结果
  ///
  /// [taskId] 任务 ID
  /// [timeout] 超时时间（默认10分钟）
  /// [pollInterval] 轮询间隔（默认5秒）
  Future<TingwuResult> waitForResult(
    String taskId, {
    Duration timeout = const Duration(minutes: 10),
    Duration pollInterval = const Duration(seconds: 5),
  }) async {
    _log('Waiting for task completion: $taskId');

    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      final status = await queryTask(taskId);

      if (status.status == 'SUCCESS') {
        _log('Task completed successfully');
        return TingwuResult.fromTaskStatus(status);
      } else if (status.status == 'FAILED') {
        throw Exception('任务执行失败: ${status.errorMessage}');
      }

      _log('Task status: ${status.status}, waiting...');
      await Future.delayed(pollInterval);
    }

    throw Exception('任务超时未完成');
  }

  /// 合并参数，避免重复键
  Map<String, dynamic> _mergeParameters(Map<String, dynamic> parameters) {
    final merged = <String, dynamic>{};

    // 收集所有 Summarization Types
    final summarizationTypes = <String>{};
    final meetingAssistanceTypes = <String>{};

    for (final entry in parameters.entries) {
      if (entry.key == 'Summarization' && entry.value is Map) {
        final types = (entry.value as Map)['Types'] as List?;
        if (types != null) {
          summarizationTypes.addAll(types.cast<String>());
        }
      } else if (entry.key == 'MeetingAssistance' && entry.value is Map) {
        final types = (entry.value as Map)['Types'] as List?;
        if (types != null) {
          meetingAssistanceTypes.addAll(types.cast<String>());
        }
      } else {
        merged[entry.key] = entry.value;
      }
    }

    if (summarizationTypes.isNotEmpty) {
      merged['Summarization'] = {
        'Types': summarizationTypes.toList(),
      };
    }

    if (meetingAssistanceTypes.isNotEmpty) {
      merged['MeetingAssistance'] = {
        'Types': meetingAssistanceTypes.toList(),
      };
    }

    return merged;
  }
}

/// 通义听悟任务状态
class TingwuTaskStatus {
  final String taskId;
  final String status; // PENDING | RUNNING | SUCCESS | FAILED
  final String? resultUrl;
  final String? errorMessage;
  final DateTime? submitTime;
  final DateTime? completeTime;

  TingwuTaskStatus({
    required this.taskId,
    required this.status,
    this.resultUrl,
    this.errorMessage,
    this.submitTime,
    this.completeTime,
  });

  factory TingwuTaskStatus.fromJson(Map<String, dynamic> json) {
    return TingwuTaskStatus(
      taskId: json['TaskId'] ?? '',
      status: json['TaskStatus'] ?? 'UNKNOWN',
      resultUrl: json['Result'],
      errorMessage: json['ErrorMessage'],
      submitTime: json['SubmitTime'] != null
          ? DateTime.tryParse(json['SubmitTime'])
          : null,
      completeTime: json['CompleteTime'] != null
          ? DateTime.tryParse(json['CompleteTime'])
          : null,
    );
  }

  bool get isCompleted => status == 'SUCCESS' || status == 'FAILED';
  bool get isSuccessful => status == 'SUCCESS';
}

/// 通义听悟转写结果
class TingwuResult {
  final String taskId;
  final String? transcriptionText;
  final List<TingwuSentence> sentences;
  final List<TingwuParagraph> paragraphs;
  final List<TingwuSpeaker> speakers;
  final TingwuSummarization? summarization;
  final List<TingwuTodo> todos;
  final List<String> keywords;
  final List<TingwuChapter> chapters;

  TingwuResult({
    required this.taskId,
    this.transcriptionText,
    this.sentences = const [],
    this.paragraphs = const [],
    this.speakers = const [],
    this.summarization,
    this.todos = const [],
    this.keywords = const [],
    this.chapters = const [],
  });

  factory TingwuResult.fromTaskStatus(TingwuTaskStatus status) {
    // TODO: 从 resultUrl 下载并解析完整结果
    // 结果格式为 JSON，包含 Transcription、Summarization、MeetingAssistance 等
    return TingwuResult(
      taskId: status.taskId,
      transcriptionText: null,
    );
  }

  /// 获取带说话人标记的文本
  String getSpeakerLabeledText() {
    final buffer = StringBuffer();
    for (final sentence in sentences) {
      if (sentence.speakerId != null) {
        buffer.writeln('发言人${sentence.speakerId}: ${sentence.text}');
      } else {
        buffer.writeln(sentence.text);
      }
    }
    return buffer.toString();
  }
}

/// 通义听悟句子
class TingwuSentence {
  final String text;
  final int? speakerId;
  final double beginTime; // 毫秒
  final double endTime; // 毫秒

  TingwuSentence({
    required this.text,
    this.speakerId,
    required this.beginTime,
    required this.endTime,
  });
}

/// 通义听悟段落
class TingwuParagraph {
  final String text;
  final int? speakerId;
  final double beginTime;
  final double endTime;

  TingwuParagraph({
    required this.text,
    this.speakerId,
    required this.beginTime,
    required this.endTime,
  });
}

/// 通义听悟说话人
class TingwuSpeaker {
  final int speakerId;
  final String? speakerName;
  final double totalTime; // 毫秒

  TingwuSpeaker({
    required this.speakerId,
    this.speakerName,
    required this.totalTime,
  });
}

/// 通义听悟摘要
class TingwuSummarization {
  final String? fullTextSummary;
  final String? conversationalSummary;
  final String? qaSummary;
  final List<TingwuSpeakerSummary> speakerSummaries;

  TingwuSummarization({
    this.fullTextSummary,
    this.conversationalSummary,
    this.qaSummary,
    this.speakerSummaries = const [],
  });
}

/// 发言人总结
class TingwuSpeakerSummary {
  final int speakerId;
  final String summary;

  TingwuSpeakerSummary({
    required this.speakerId,
    required this.summary,
  });
}

/// 待办事项
class TingwuTodo {
  final String content;
  final String? assignee;

  TingwuTodo({
    required this.content,
    this.assignee,
  });
}

/// 章节
class TingwuChapter {
  final String title;
  final String summary;
  final double beginTime;
  final double endTime;

  TingwuChapter({
    required this.title,
    required this.summary,
    required this.beginTime,
    required this.endTime,
  });
}
