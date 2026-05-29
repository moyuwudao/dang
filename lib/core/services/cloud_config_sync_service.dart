import 'dart:convert';
import '../models/api_config.dart';
import '../models/ai_model_config.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import 'storage_service.dart';
import 'secure_storage_service.dart';
import 'app_logger.dart';

/// 云端默认配置同步服务
/// 
/// 设计原则：
/// 1. 云端配置条目（ApiConfigEntry）由 multi_api_config_screen.dart 动态加载，不存储在 MultiApiConfig 中
/// 2. 只存储分配关系（functionAssignments），告诉系统哪个场景使用哪个云端模型
/// 3. 云端配置的实际内容（API Key、模型名称等）从 SecureStorage 和 subscription 实时获取
class CloudConfigSyncService {
  /// 功能类型映射：服务端 -> 客户端
  static final Map<String, ApiFunctionType> _functionTypeMap = {
    'text_analysis': ApiFunctionType.text,
    'voice_transcription': ApiFunctionType.voice,
    'realtime_transcription': ApiFunctionType.voiceRealtime,
    'offline_transcription': ApiFunctionType.offlineVoice,
    'image_recognition': ApiFunctionType.image,
  };

  /// 将云端默认配置同步到 MultiApiConfig
  ///
  /// 只同步分配关系，不存储云端配置条目
  /// 云端配置条目由 multi_api_config_screen.dart 动态加载
  static Future<CloudSyncResult> syncCloudDefaults({
    required List<DefaultConfig> defaultConfigs,
    required List<ApiPolicy> apiPolicies,
  }) async {
    try {
      AppLogger().i('CloudSync', '开始同步云端默认配置，共 ${defaultConfigs.length} 个场景');

      // 1. 加载现有的 MultiApiConfig
      final multiConfig = await StorageService.getMultiApiConfig();

      // 2. 从 SecureStorage 获取云端 API Key 配置
      final cloudConfigJson = await SecureStorageService().read('cloud_api_config');
      String? cloudApiKey;
      if (cloudConfigJson != null) {
        final cloudData = jsonDecode(cloudConfigJson) as Map<String, dynamic>;
        cloudApiKey = cloudData['apiKey'] as String?;
      }

      if (cloudApiKey == null || cloudApiKey.isEmpty) {
        AppLogger().w('CloudSync', '云端 API Key 未配置，无法同步');
        return const CloudSyncResult(
          success: false,
          syncedCount: 0,
          message: '云端 API Key 未配置，请先登录获取',
        );
      }

      // 3. 只保留本地配置（移除任何旧的云端配置条目）
      final localConfigs = multiConfig.configs
          .where((c) => !c.isCloudConfig)
          .toList();
      AppLogger().i('CloudSync', '保留 ${localConfigs.length} 个本地配置');

      // 4. 为每个 defaultConfig 创建分配关系
      // 使用 modelPattern 作为 configId，与 multi_api_config_screen.dart 保持一致
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

        // 使用与 multi_api_config_screen.dart 相同的 configId 格式
        final configId = 'cloud_${providerName}_$modelName';
        
        newAssignments.add(ApiFunctionAssignment(
          functionType: functionType,
          configId: configId,
        ));

        AppLogger().i('CloudSync',
            '创建云端分配: ${defaultConfig.functionType} -> $configId');
      }

      // 5. 合并分配关系：云端配置优先，本地配置作为回退
      final mergedAssignments = <ApiFunctionAssignment>[];
      final allFunctionTypes = ApiFunctionType.values;

      for (final ft in allFunctionTypes) {
        // 优先使用云端分配的 configId
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

      // 6. 保存新的 MultiApiConfig（只包含本地配置 + 分配关系）
      final newConfig = MultiApiConfig(
        configs: localConfigs,
        functionAssignments: mergedAssignments,
        defaultConfigId: localConfigs.isNotEmpty ? localConfigs.first.id : null,
      );

      await StorageService.saveMultiApiConfig(newConfig);

      AppLogger().i('CloudSync',
          '同步完成: ${newAssignments.length} 个云端分配已应用');

      return CloudSyncResult(
        success: true,
        syncedCount: newAssignments.length,
        message: '已成功同步 ${newAssignments.length} 个场景的云端配置',
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
  static Future<void> clearCloudConfigs() async {
    try {
      final multiConfig = await StorageService.getMultiApiConfig();

      // 1. 过滤掉所有云端配置条目，只保留本地配置
      final localConfigs = multiConfig.configs
          .where((c) => !c.isCloudConfig)
          .toList();

      // 2. 获取本地配置的ID集合
      final localConfigIds = localConfigs.map((c) => c.id).toSet();

      // 3. 过滤掉云端配置的分配（只保留指向本地配置的分配）
      final localAssignments = multiConfig.functionAssignments
          .where((a) => a.configId != null && localConfigIds.contains(a.configId))
          .toList();

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
