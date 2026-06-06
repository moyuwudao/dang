import 'dart:convert';
import '../models/api_config.dart';
import '../models/ai_model_config.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import 'storage_service.dart';
import 'secure_storage_service.dart';
import 'app_logger.dart';
import 'cloud_api_service.dart';

/// 云端默认配置同步服务
///
/// 设计原则：
/// 1. 云端配置条目（ApiConfigEntry）持久化到 MultiApiConfig.configs 中，isCloudConfig=true
///    - API Key/baseUrl 仍从 SecureStorage 读，敏感信息不入 storage
///    - 持久化后 multi_api_config_screen 可直接读取，无需每次 dynamic load
/// 2. functionAssignments 存储分配关系（场景→云端模型）
/// 3. 关闭云端AI时清空所有 isCloudConfig 条目和分配
class CloudConfigSyncService {
  /// 功能类型映射：服务端 -> 客户端
  static final Map<String, ApiFunctionType> _functionTypeMap = {
    // 服务端 camelCase 形式（套餐 defaultConfigs 当前使用）
    'textAnalysis': ApiFunctionType.text,
    'speechTranscribe': ApiFunctionType.voice,
    'speechRealtime': ApiFunctionType.voiceRealtime,
    'speechOffline': ApiFunctionType.offlineVoice,
    'imageRecognition': ApiFunctionType.image,
    // 旧 enum 形式
    'summary': ApiFunctionType.text,
    'translate': ApiFunctionType.text,
    'mindMap': ApiFunctionType.text,
    'transcribe': ApiFunctionType.voiceRealtime,
    'transcribeFile': ApiFunctionType.offlineVoice,
    'image': ApiFunctionType.image,
    // snake_case 形式
    'text_analysis': ApiFunctionType.text,
    'voice_transcription': ApiFunctionType.voice,
    'realtime_transcription': ApiFunctionType.voiceRealtime,
    'offline_transcription': ApiFunctionType.offlineVoice,
    'image_recognition': ApiFunctionType.image,
  };

  /// 从 SecureStorage 读取云端 API Key 与 baseUrl（不入 storage 的敏感信息）
  static Future<({String? apiKey, String? baseUrl})> _readCloudSecrets() async {
    final cloudConfigJson = await SecureStorageService().read('cloud_api_config');
    if (cloudConfigJson == null) return (apiKey: null, baseUrl: null);
    try {
      final cloudData = jsonDecode(cloudConfigJson) as Map<String, dynamic>;
      return (
        apiKey: cloudData['apiKey'] as String?,
        baseUrl: cloudData['baseUrl'] as String?,
      );
    } catch (_) {
      return (apiKey: null, baseUrl: null);
    }
  }

  /// 把 apiPolicies 同步为本地 MultiApiConfig 中的云端条目
  ///
  /// 行为：
  /// - 把当前 isCloudConfig=true 的旧条目全部移除
  /// - 按 apiPolicies 生成新的云端条目并追加
  /// - 保留本地（isCloudConfig=false）条目不动
  /// - API Key/baseUrl 不入 storage（仍由 SecureStorage 提供，运行时由 multi_api_config_screen 注入）
  ///
  /// 适用于"手动配置"分支：仅同步可用 API，不动场景分配
  static Future<CloudSyncResult> syncApiPolicies({
    required List<ApiPolicy> apiPolicies,
    List<DefaultConfig> defaultConfigs = const [],
  }) async {
    try {
      AppLogger().i('CloudSync', '开始同步 ${apiPolicies.length} 个云端 API Policy');

      final multiConfig = await StorageService.getMultiApiConfig();
      final now = DateTime.now();

      // 1. 保留本地配置（移除任何旧的云端配置条目）
      final localConfigs = multiConfig.configs
          .where((c) => !c.isCloudConfig)
          .toList();

      // 2. 按 apiPolicies 生成云端条目骨架（不存 API Key）
      // 反向索引：modelPattern → [ApiFunctionType, ...]
      final modelToFunctions = <String, Set<ApiFunctionType>>{};
      for (final dc in defaultConfigs) {
        if (dc.modelPattern.isEmpty) continue;
        final ft = _functionTypeMap[dc.functionType];
        if (ft == null) continue;
        modelToFunctions.putIfAbsent(dc.modelPattern, () => {}).add(ft);
      }

      final newCloudEntries = <ApiConfigEntry>[];
      final seenModels = <String>{};
      // 按 provider 批量获取 API Key，避免每个条目单独请求
      final providerKeyCache = <String, ({String apiKey, String? baseUrl, String? model})>{};

      for (final policy in apiPolicies) {
        if (policy.isAllowed == false) continue;
        final providerName = policy.provider;
        final modelPattern = policy.modelPattern ?? '';
        // 优先用 policy.model，否则从 modelPattern 解析
        final modelName = (policy.model?.isNotEmpty ?? false)
            ? policy.model!
            : modelPattern.split(':').last;
        if (providerName.isEmpty || modelName.isEmpty) continue;
        if (seenModels.contains(modelName)) continue;
        seenModels.add(modelName);

        final providerEnum = AiProvider.values.firstWhere(
          (p) => p.name.toLowerCase() == providerName.toLowerCase(),
          orElse: () => AiProvider.openAI,
        );
        final providerConfig = AiModelConfig.getConfig(providerEnum);
        final displayName = '${providerConfig.displayName} $modelName';

        // 功能列表：优先用套餐 defaultConfigs 推导，否则用 providerSupportsFunction 兜底
        final mappedFromPlan = modelToFunctions[modelName] ?? modelToFunctions[modelPattern];
        final List<ApiFunctionType> compatibleFunctions;
        if (mappedFromPlan != null && mappedFromPlan.isNotEmpty) {
          compatibleFunctions = mappedFromPlan.toList();
        } else {
          compatibleFunctions = ApiFunctionType.values
              .where((f) => AiModelConfig.providerSupportsFunction(providerEnum, f))
              .toList();
        }

        // 按 provider 获取 API Key（缓存，同一 provider 只请求一次）
        String entryApiKey = '';
        String? entryBaseUrl;
        String? entryModel;
        if (!providerKeyCache.containsKey(providerName)) {
          try {
            final response = await CloudApiService.instance.get('/api-key?provider=$providerName');
            final data = response.data['data'] as Map<String, dynamic>?;
            if (data != null && data['apiKey'] != null) {
              providerKeyCache[providerName] = (
                apiKey: data['apiKey'] as String,
                baseUrl: data['baseUrl'] as String?,
                model: data['model'] as String?,
              );
              AppLogger().i('CloudSync', '获取 $providerName Key 成功');
            }
          } catch (e) {
            AppLogger().w('CloudSync', '获取 $providerName Key 失败: $e');
          }
        }
        final cached = providerKeyCache[providerName];
        if (cached != null) {
          entryApiKey = cached.apiKey;
          entryBaseUrl = cached.baseUrl;
          entryModel = cached.model;
        }

        newCloudEntries.add(ApiConfigEntry(
          id: 'cloud_${providerName}_$modelName',
          name: displayName,
          provider: providerEnum,
          apiKey: entryApiKey,
          baseUrl: entryBaseUrl ?? providerConfig.baseUrl,
          model: entryModel ?? modelName,
          functions: compatibleFunctions,
          isActive: true,
          isCloudConfig: true,
          cloudMultiplier: policy.multiplier,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // 3. 合并：本地配置 + 新云端条目
      final mergedConfigs = [...localConfigs, ...newCloudEntries];
      final newConfig = MultiApiConfig(
        configs: mergedConfigs,
        functionAssignments: multiConfig.functionAssignments, // 保留原分配不动
        defaultConfigId: localConfigs.isNotEmpty ? localConfigs.first.id : null,
      );
      await StorageService.saveMultiApiConfig(newConfig);

      AppLogger().i('CloudSync',
          'ApiPolicy 同步完成: 新增 ${newCloudEntries.length} 个云端条目，本地保留 ${localConfigs.length} 个');

      return CloudSyncResult(
        success: true,
        syncedCount: newCloudEntries.length,
        message: '已同步 ${newCloudEntries.length} 个套餐可用 API',
      );
    } catch (e) {
      AppLogger().e('CloudSync', 'ApiPolicy 同步失败: $e');
      return CloudSyncResult(
        success: false,
        syncedCount: 0,
        message: 'ApiPolicy 同步失败: $e',
      );
    }
  }

  /// 将云端默认配置同步到 MultiApiConfig
  ///
  /// 流程：
  /// 1. 先调 [syncApiPolicies] 把 apiPolicies 持久化为本地云端条目
  /// 2. 再把 defaultConfigs 应用到 functionAssignments（场景分配）
  static Future<CloudSyncResult> syncCloudDefaults({
    required List<DefaultConfig> defaultConfigs,
    required List<ApiPolicy> apiPolicies,
  }) async {
    try {
      AppLogger().i('CloudSync', '开始同步云端默认配置，共 ${defaultConfigs.length} 个场景');

      // 0. 必须有 cloudApiKey
      final secrets = await _readCloudSecrets();
      if (secrets.apiKey == null || secrets.apiKey!.isEmpty) {
        AppLogger().w('CloudSync', '云端 API Key 未配置，无法同步');
        return const CloudSyncResult(
          success: false,
          syncedCount: 0,
          message: '云端 API Key 未配置，请先登录获取',
        );
      }

      // 1. 先把 apiPolicies 持久化为云端条目
      final policiesResult = await syncApiPolicies(
        apiPolicies: apiPolicies,
        defaultConfigs: defaultConfigs,
      );
      if (!policiesResult.success) {
        return policiesResult;
      }

      // 2. 在已同步云端条目的基础上，应用 defaultConfigs 到 functionAssignments
      final multiConfig = await StorageService.getMultiApiConfig();
      final newAssignments = <ApiFunctionAssignment>[];

      for (final defaultConfig in defaultConfigs) {
        final functionType = _functionTypeMap[defaultConfig.functionType];
        if (functionType == null) {
          AppLogger().w('CloudSync', '未知的功能类型: ${defaultConfig.functionType}');
          continue;
        }

        // 解析 modelPattern (格式: provider:model-name)
        final parts = defaultConfig.modelPattern.split(':');
        if (parts.length < 2) {
          AppLogger().w('CloudSync', '无效的 modelPattern: ${defaultConfig.modelPattern}');
          continue;
        }
        final providerName = parts[0];
        final modelName = parts.sublist(1).join(':');
        // 与 syncApiPolicies 保持一致的 configId
        final configId = 'cloud_${providerName}_$modelName';

        newAssignments.add(ApiFunctionAssignment(
          functionType: functionType,
          configId: configId,
        ));
        AppLogger().i('CloudSync',
            '创建云端分配: ${defaultConfig.functionType} -> $configId');
      }

      // 3. 合并分配关系：云端配置优先，本地配置作为回退
      final mergedAssignments = <ApiFunctionAssignment>[];
      for (final ft in ApiFunctionType.values) {
        final cloudAssignment = newAssignments.firstWhere(
          (a) => a.functionType == ft,
          orElse: () => const ApiFunctionAssignment(
            functionType: ApiFunctionType.text,
            configId: null,
          ),
        );
        if (cloudAssignment.configId != null) {
          mergedAssignments.add(cloudAssignment);
        } else {
          // 回退到本地配置的分配
          final localAssignment = multiConfig.functionAssignments.firstWhere(
            (a) => a.functionType == ft && a.configId != null,
            orElse: () => const ApiFunctionAssignment(
              functionType: ApiFunctionType.text,
              configId: null,
            ),
          );
          if (localAssignment.configId != null) {
            mergedAssignments.add(localAssignment);
          }
        }
      }

      // 4. 保存新分配（云端条目已在上一步保存，这里只覆盖 assignments）
      final newConfig = MultiApiConfig(
        configs: multiConfig.configs,
        functionAssignments: mergedAssignments,
        defaultConfigId: multiConfig.defaultConfigId,
      );
      await StorageService.saveMultiApiConfig(newConfig);

      AppLogger().i('CloudSync',
          '同步完成: ${newAssignments.length} 个云端分配已应用');

      return CloudSyncResult(
        success: true,
        syncedCount: newAssignments.length,
        message:
            '已同步 ${newAssignments.length} 个场景默认 + ${policiesResult.syncedCount} 个可用 API',
      );
    } catch (e) {
      AppLogger().e('CloudSync', '同步失败: $e');
      return CloudSyncResult(
        success: false,
        syncedCount: 0,
        message: '同步失败: $e',
      );
    }
  }

  /// 清除所有云端配置（关闭云端AI时调用）
  ///
  /// 从 MultiApiConfig.configs 移除所有 isCloudConfig=true 的条目，
  /// 并清理指向云端条目的 functionAssignments
  static Future<void> clearCloudConfigs() async {
    try {
      final multiConfig = await StorageService.getMultiApiConfig();

      // 1. 仅保留本地配置
      final localConfigs = multiConfig.configs
          .where((c) => !c.isCloudConfig)
          .toList();

      // 2. 仅保留指向本地配置的分配
      final localConfigIds = localConfigs.map((c) => c.id).toSet();
      // 修复 Issue 3：保留所有 function 类型的分配，把指向 cloud_xxx 的回退到本地默认 configId
      // 这样关闭云端AI后，ApiConfigResolver 仍能按场景找到本地配置（不会全部走 fallback）
      final localAssignments = <ApiFunctionAssignment>[];
      for (final assignment in multiConfig.functionAssignments) {
        if (assignment.configId != null && localConfigIds.contains(assignment.configId)) {
          // 已经指向本地配置 → 保留
          localAssignments.add(assignment);
        } else if (localConfigs.isNotEmpty) {
          // 指向云端配置（或失效）→ 回退到本地第一个条目
          localAssignments.add(ApiFunctionAssignment(
            functionType: assignment.functionType,
            configId: localConfigs.first.id,
          ));
        }
        // 本地无配置时，该功能分配保持 null
      }

      final newConfig = MultiApiConfig(
        configs: localConfigs,
        functionAssignments: localAssignments,
        defaultConfigId: localConfigs.isNotEmpty ? localConfigs.first.id : null,
      );
      await StorageService.saveMultiApiConfig(newConfig);
      AppLogger().i('CloudSync', '已清除所有云端配置，保留 ${localConfigs.length} 个本地配置');
    } catch (e) {
      AppLogger().e('CloudSync', '清除云端配置失败: $e');
    }
  }
}

/// 同步结果
class CloudSyncResult {
  final bool success;
  final int syncedCount;
  final String message;

  const CloudSyncResult({
    required this.success,
    required this.syncedCount,
    required this.message,
  });
}

