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

class TokenBalance {
  final int balanceTokens;
  final int freeTokensRemaining;
  final int totalTokens;
  final int usedTokens;

  const TokenBalance({
    required this.balanceTokens,
    required this.freeTokensRemaining,
    required this.totalTokens,
    required this.usedTokens,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    return TokenBalance(
      balanceTokens: (json['balanceTokens'] as num?)?.toInt() ?? 0,
      freeTokensRemaining: (json['freeTokensRemaining'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      usedTokens: (json['usedTokens'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalAvailable => balanceTokens + freeTokensRemaining;

  bool hasEnough(int estimatedTokens) => totalAvailable >= estimatedTokens;
}

class RechargeRecord {
  final int id;
  final int tokens;
  final int amountCents;
  final String status;
  final DateTime createdAt;

  RechargeRecord({
    required this.id,
    required this.tokens,
    required this.amountCents,
    required this.status,
    required this.createdAt,
  });

  factory RechargeRecord.fromJson(Map<String, dynamic> json) {
    return RechargeRecord(
      id: (json['id'] as num).toInt(),
      tokens: (json['tokens'] as num).toInt(),
      amountCents: (json['amountCents'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class BillingService {
  TokenBalance? _cachedBalance;
  DateTime? _balanceCacheTime;
  static const _cacheDuration = Duration(seconds: 30);

  Future<TokenBalance> getTokenBalance({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedBalance != null &&
        _balanceCacheTime != null &&
        DateTime.now().difference(_balanceCacheTime!) < _cacheDuration) {
      return _cachedBalance!;
    }

    try {
      final response = await CloudApiService.instance.get('/subscription/balance');
      final data = response.data['data'] as Map<String, dynamic>;
      _cachedBalance = TokenBalance.fromJson(data);
      _balanceCacheTime = DateTime.now();
      return _cachedBalance!;
    } catch (e) {
      return _cachedBalance ??
          TokenBalance(
            balanceTokens: 0,
            freeTokensRemaining: 0,
            totalTokens: 0,
            usedTokens: 0,
          );
    }
  }

  void clearBalanceCache() {
    _cachedBalance = null;
    _balanceCacheTime = null;
  }

  Future<bool> canUseFeature(FeatureType type, double amount) async {
    try {
      final balance = await getTokenBalance();
      final estimatedTokens = _estimateTokens(type, amount);
      return balance.hasEnough(estimatedTokens);
    } catch (e) {
      return false;
    }
  }

  int _estimateTokens(FeatureType type, double amount) {
    switch (type) {
      case FeatureType.transcription:
      case FeatureType.realtimeTranscription:
        return (amount * 1200).ceil();
      case FeatureType.textAnalysis:
      case FeatureType.tts:
        return (amount * 1000).ceil();
      case FeatureType.imageRecognition:
        return (amount * 2000).ceil();
      case FeatureType.ocr:
        return (amount * 800).ceil();
      case FeatureType.aiChat:
        return amount.ceil();
    }
  }

  Future<bool> rechargeTokens(int amountCents) async {
    try {
      final response = await CloudApiService.instance.post(
        '/subscription/recharge',
        data: {'amountCents': amountCents},
      );
      final success = response.data['data']?['success'] ?? false;
      if (success) {
        clearBalanceCache();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<List<RechargeRecord>> getRechargeRecords() async {
    try {
      final response = await CloudApiService.instance.get('/subscription/records');
      final data = response.data['data'] as List<dynamic>;
      return data.map((e) => RechargeRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @Deprecated('后端自动计费，前端不再主动扣减')
  Future<void> consumeFeature(
    FeatureType type,
    double amount, {
    String? provider,
    String? model,
    int? promptTokens,
    int? completionTokens,
  }) async {
    clearBalanceCache();
  }

  @Deprecated('使用 getTokenBalance 替代')
  Future<Map<FeatureType, FeatureUsage>> getFeatureUsage() async {
    return {};
  }

  @Deprecated('使用 rechargeTokens 替代')
  Future<bool> purchaseWithBalance(String planId) async {
    return false;
  }
}

@Deprecated('已弃用，使用 TokenBalance 替代')
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

@Deprecated('已弃用，使用 TokenBalance 替代')
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
