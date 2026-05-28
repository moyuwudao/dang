import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_model_config.dart';
import '../models/api_config.dart';
import 'api_service.dart';
import 'app_logger.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';
import '../../features/subscription/providers/subscription_provider.dart';

/// API 配置解析器 - 统一管理云端/本地配置的选择逻辑
///
/// 优先级：
/// 1. 场景明确分配的配置（MultiApiConfig.functionAssignments）
/// 2. 云端AI开关开启时，使用云端默认配置
/// 3. 回退到本地默认配置
class ApiConfigResolver {
  final Ref _ref;

  ApiConfigResolver(this._ref);

  /// 解析指定功能应使用的 API 配置
  Future<ResolvedApiConfig?> resolve(ApiFunctionType functionType) async {
    // 1. 从 MultiApiConfig 获取场景分配
    final multiConfig = await _loadMultiApiConfig();
    if (multiConfig != null) {
      final assigned = multiConfig.getConfigForFunction(functionType);
      if (assigned != null && assigned.isActive) {
        return ResolvedApiConfig(
          provider: assigned.provider,
          apiKey: assigned.apiKey,
          baseUrl: assigned.baseUrl,
          model: assigned.model,
          appId: assigned.appId,
          accessKeySecret: assigned.accessKeySecret,
          source: assigned.isCloudConfig ? ConfigSource.cloud : ConfigSource.local,
        );
      }
    }

    // 2. 云端AI开关开启时，尝试使用云端配置
    final cloudEnabled = _ref.read(cloudApiEnabledProvider).valueOrNull ?? false;
    if (cloudEnabled) {
      final cloudConfig = await _loadCloudConfig();
      if (cloudConfig != null) {
        final providerName = cloudConfig['provider'] as String?;
        if (providerName == null) {
          // skip to local config
        } else {
          final cloudProvider = AiProvider.values.firstWhere(
            (p) => p.name == providerName,
            orElse: () => AiProvider.openAI,
          );
          final providerConfig = AiModelConfig.getConfigByName(providerName);
          if (providerConfig != null &&
              AiModelConfig.providerSupportsFunction(cloudProvider, functionType)) {
            return ResolvedApiConfig(
              provider: cloudProvider,
              apiKey: cloudConfig['apiKey'] as String,
              baseUrl: cloudConfig['baseUrl'] as String?,
              model: cloudConfig['model'] as String?,
              source: ConfigSource.cloud,
            );
          }
        }
      }
    }

    // 3. 回退到本地默认配置
    final localConfig = await _loadLocalConfig();
    if (localConfig != null) {
      return ResolvedApiConfig(
        provider: localConfig.provider,
        apiKey: localConfig.apiKey,
        baseUrl: localConfig.baseUrl,
        model: localConfig.model,
        appId: localConfig.appId,
        accessKeySecret: localConfig.accessKeySecret,
        source: ConfigSource.local,
      );
    }

    return null;
  }

  /// 将解析结果应用到 HttpClient
  Future<bool> applyToHttpClient(ApiFunctionType functionType) async {
    final resolved = await resolve(functionType);
    if (resolved == null) {
      AppLogger().w('ApiConfigResolver', '无可用配置: function=$functionType');
      return false;
    }

    final providerConfig = AiModelConfig.getConfig(resolved.provider);
    _ref.read(apiServiceProvider).configure(
          apiKey: resolved.apiKey,
          config: providerConfig,
          customBaseUrl: resolved.baseUrl,
          appId: resolved.appId,
          accessKeySecret: resolved.accessKeySecret,
        );

    AppLogger().i('ApiConfigResolver',
        '已应用配置: function=$functionType, provider=${resolved.provider.name}, source=${resolved.source.name}');
    return true;
  }

  Future<MultiApiConfig?> _loadMultiApiConfig() async {
    try {
      final jsonStr = await StorageService.getString('multi_api_config_v2');
      if (jsonStr == null) return null;
      return MultiApiConfig.fromJson(
          Map<String, dynamic>.from(const JsonDecoder().convert(jsonStr)));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadCloudConfig() async {
    try {
      final jsonStr = await SecureStorageService().read('cloud_api_config');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return Map<String, dynamic>.from(const JsonDecoder().convert(jsonStr));
    } catch (_) {
      return null;
    }
  }

  Future<ResolvedApiConfig?> _loadLocalConfig() async {
    try {
      final config = await StorageService.getApiConfig();
      if (config == null || config.apiKey.isEmpty) return null;

      final provider = AiProvider.values.firstWhere(
        (p) => p.name == config.provider,
        orElse: () => AiProvider.openAI,
      );
      return ResolvedApiConfig(
        provider: provider,
        apiKey: config.apiKey,
        baseUrl: config.baseUrl,
        model: config.model,
        appId: config.appId,
        accessKeySecret: config.accessKeySecret,
        source: ConfigSource.local,
      );
    } catch (_) {
      return null;
    }
  }
}

enum ConfigSource { cloud, local }

class ResolvedApiConfig {
  final AiProvider provider;
  final String apiKey;
  final String? baseUrl;
  final String? model;
  final String? appId;
  final String? accessKeySecret;
  final ConfigSource source;

  const ResolvedApiConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.model,
    this.appId,
    this.accessKeySecret,
    required this.source,
  });
}

final apiConfigResolverProvider = Provider<ApiConfigResolver>((ref) {
  return ApiConfigResolver(ref);
});
