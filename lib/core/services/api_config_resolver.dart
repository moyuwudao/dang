import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_model_config.dart';
import '../models/api_config.dart';
import 'api_service.dart';
import 'app_logger.dart';
import 'cloud_api_service.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';
import '../../features/auth/providers/auth_provider.dart';
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
    // 修复异常4：未登录时强制跳过云端配置（云端配置仅在登录状态下有效）
    final authState = _ref.read(authNotifierProvider).valueOrNull;
    final isLoggedIn = authState?.isLoggedIn ?? false;
    if (!isLoggedIn) {
      AppLogger().i('ApiConfigResolver', '未登录：跳过云端配置，直接走本地');
      return _loadLocalConfig();
    }

    // 1. 从 MultiApiConfig 获取场景分配
    final multiConfig = await _loadMultiApiConfig();
    if (multiConfig != null) {
      final assigned = multiConfig.getConfigForFunction(functionType);
      if (assigned != null && assigned.isActive) {
        // 修复 Issue 3：云端条目的 apiKey 可能为空（provider不匹配时未注入）
        // 如果 apiKey 为空，尝试懒加载获取对应 provider 的 Key
        String apiKey = assigned.apiKey;
        String? baseUrl = assigned.baseUrl;
        String? model = assigned.model;
        if (apiKey.isEmpty && assigned.isCloudConfig) {
          final entryProviderName = assigned.provider.name;
          final fetched = await _fetchProviderApiKey(entryProviderName);
          if (fetched != null) {
            apiKey = fetched['apiKey'] as String;
            baseUrl = fetched['baseUrl'] as String? ?? baseUrl;
            model = fetched['model'] as String? ?? model;
            AppLogger().i('ApiConfigResolver',
                '懒加载成功: provider=$entryProviderName, model=$model');
          }
        }
        // 如果仍然为空，跳过此分配，让后续逻辑处理
        if (apiKey.isNotEmpty) {
          return ResolvedApiConfig(
            provider: assigned.provider,
            apiKey: apiKey,
            baseUrl: baseUrl,
            model: model,
            appId: assigned.appId,
            accessKeySecret: assigned.accessKeySecret,
            source: assigned.isCloudConfig ? ConfigSource.cloud : ConfigSource.local,
            multiplier: assigned.isCloudConfig ? assigned.cloudMultiplier : 1.0,
          );
        }
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
          // 修复 Issue 3：将解析到的 multiplier 传入 HttpClient，确保计费检查正确
          multiplier: resolved.multiplier,
          // 修复：本地 Key 不检查余额，云端 Key 才检查
          isCloudConfig: resolved.source == ConfigSource.cloud,
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

  /// 从服务器获取指定 provider 的 API Key（懒加载）
  /// 修复 Issue 3：当云端配置需要特定 provider 但当前没有对应 Key 时，实时获取
  Future<Map<String, dynamic>?> _fetchProviderApiKey(String provider) async {
    try {
      final response = await CloudApiService.instance.get('/api-key?provider=$provider');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && data['apiKey'] != null) {
        AppLogger().i('ApiConfigResolver', '懒加载获取 $provider Key 成功');
        return data;
      }
      return null;
    } catch (e) {
      AppLogger().w('ApiConfigResolver', '懒加载获取 $provider Key 失败: $e');
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
  final double multiplier; // 修复 Issue 3：携带模型的消耗系数，用于计费检查

  const ResolvedApiConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.model,
    this.appId,
    this.accessKeySecret,
    required this.source,
    this.multiplier = 1.0,
  });
}

final apiConfigResolverProvider = Provider<ApiConfigResolver>((ref) {
  return ApiConfigResolver(ref);
});
