import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cloud_api_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService();
});

enum FeatureType {
  transcription,
  realtimeTranscription,
  textAnalysis,
  imageRecognition,
  ocr,
  aiChat,
  tts,
}

extension FeatureTypeExtension on FeatureType {
  String get name {
    switch (this) {
      case FeatureType.transcription:
        return 'transcription';
      case FeatureType.realtimeTranscription:
        return 'realtime_transcription';
      case FeatureType.textAnalysis:
        return 'text_analysis';
      case FeatureType.imageRecognition:
        return 'image_recognition';
      case FeatureType.ocr:
        return 'ocr';
      case FeatureType.aiChat:
        return 'ai_chat';
      case FeatureType.tts:
        return 'tts';
    }
  }

  String get displayName {
    switch (this) {
      case FeatureType.transcription:
        return '语音转写';
      case FeatureType.realtimeTranscription:
        return '实时转写';
      case FeatureType.textAnalysis:
        return '文本分析';
      case FeatureType.imageRecognition:
        return '图像识别';
      case FeatureType.ocr:
        return 'OCR识别';
      case FeatureType.aiChat:
        return 'AI对话';
      case FeatureType.tts:
        return '语音合成';
    }
  }

  String get unit {
    switch (this) {
      case FeatureType.transcription:
      case FeatureType.realtimeTranscription:
        return '分钟';
      case FeatureType.textAnalysis:
      case FeatureType.tts:
        return '千字符';
      case FeatureType.imageRecognition:
      case FeatureType.ocr:
        return '张';
      case FeatureType.aiChat:
        return 'tokens';
    }
  }
}

class ConsumeResult {
  final bool success;
  final double consumed;
  final double remaining;
  final int? costCents;
  final String? message;

  ConsumeResult({
    required this.success,
    required this.consumed,
    required this.remaining,
    this.costCents,
    this.message,
  });

  factory ConsumeResult.fromJson(Map<String, dynamic> json) {
    return ConsumeResult(
      success: json['success'] as bool,
      consumed: (json['consumed'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      costCents: json['costCents'] as int?,
      message: json['message'] as String?,
    );
  }
}

class FeatureUsage {
  final double remaining;
  final String unit;

  FeatureUsage({
    required this.remaining,
    required this.unit,
  });

  factory FeatureUsage.fromJson(Map<String, dynamic> json) {
    return FeatureUsage(
      remaining: (json['remaining'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}

class BillingService {
  // 检查功能是否可用
  Future<bool> canUseFeature(FeatureType type, double amount) async {
    try {
      final response = await CloudApiService.instance.post('/subscription/check-feature', {
        'featureType': type.name,
        'amount': amount,
      });
      return response.data['data']['canUse'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // 使用功能
  Future<ConsumeResult> consumeFeature(
    FeatureType type,
    double amount, {
    String? provider,
    String? model,
    int? promptTokens,
    int? completionTokens,
  }) async {
    final response = await CloudApiService.instance.post('/subscription/consume-feature', {
      'featureType': type.name,
      'amount': amount,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
      if (promptTokens != null || completionTokens != null)
        'tokens': {
          if (promptTokens != null) 'prompt': promptTokens,
          if (completionTokens != null) 'completion': completionTokens,
        },
    });
    return ConsumeResult.fromJson(response.data['data']);
  }

  // 获取功能使用情况
  Future<Map<FeatureType, FeatureUsage>> getFeatureUsage() async {
    final response = await CloudApiService.instance.get('/subscription/feature-usage');
    final data = response.data['data'] as Map<String, dynamic>;
    
    return Map.fromEntries(
      data.entries.map((e) {
        try {
          return MapEntry(
            FeatureType.values.firstWhere((t) => t.name == e.key),
            FeatureUsage.fromJson(e.value),
          );
        } catch (_) {
          return null;
        }
      }).whereType<MapEntry<FeatureType, FeatureUsage>>(),
    );
  }

  // 使用余额购买套餐/资源包
  Future<bool> purchaseWithBalance(String planId) async {
    try {
      final response = await CloudApiService.instance.post('/subscription/purchase-with-balance', {
        'planId': planId,
      });
      return response.data['data']['success'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
