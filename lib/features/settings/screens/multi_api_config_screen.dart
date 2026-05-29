import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/aliyun_signer.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/providers/subscription_provider.dart';

class MultiApiConfigScreen extends ConsumerStatefulWidget {
  const MultiApiConfigScreen({super.key});

  @override
  ConsumerState<MultiApiConfigScreen> createState() {
    return _MultiApiConfigScreenState();
  }
}

class _MultiApiConfigScreenState extends ConsumerState<MultiApiConfigScreen> {
  MultiApiConfig _config = const MultiApiConfig();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听登录状态变化：退出登录后重新加载配置（排除云端配置）
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    if (authState != null && !authState.isLoggedIn && _config.hasCloudConfig) {
      _loadConfig();
      return;
    }

    // 监听云端AI开关变化：开关状态改变时重新加载配置
    final cloudEnabled = ref.watch(cloudApiEnabledProvider).valueOrNull ?? false;
    final hasCloudConfig = _config.hasCloudConfig;
    
    // 开关打开且已登录，但没有云端配置 → 重新加载
    if (cloudEnabled && authState != null && authState.isLoggedIn && !hasCloudConfig) {
      _loadConfig();
      return;
    }
    
    // 开关关闭，但有云端配置 → 重新加载（移除云端配置）
    if (!cloudEnabled && hasCloudConfig) {
      _loadConfig();
      return;
    }
  }

  Future<void> _loadConfig() async {
    final localConfig = await StorageService.getMultiApiConfig();

    // 加载云端配置（已包含登录状态校验，未登录返回空）
    final cloudEntries = await _loadCloudConfigEntries();

    // 合并：本地配置 + 云端配置
    final allConfigs = [...localConfig.configs, ...cloudEntries];
    final mergedConfig = localConfig.copyWith(configs: allConfigs);

    setState(() {
      _config = mergedConfig;
      _isLoading = false;
    });
  }

  Future<List<ApiConfigEntry>> _loadCloudConfigEntries() async {
    try {
      // 安全校验 1：必须已登录且云端AI开关开启才能加载云端配置
      final authState = ref.read(authNotifierProvider).valueOrNull;
      if (authState == null || !authState.isLoggedIn) {
        return [];
      }
      
      // 安全校验 2：云端AI开关必须开启
      final cloudEnabled = ref.read(cloudApiEnabledProvider).valueOrNull ?? false;
      if (!cloudEnabled) {
        return [];
      }

      // 安全校验 3：获取订阅状态和可用模型
      final subscriptionState = ref.read(subscriptionNotifierProvider).valueOrNull;
      final apiPolicies = subscriptionState?.apiPolicies ?? [];
      if (apiPolicies.isEmpty) return [];

      // 安全校验 4：从 SecureStorage 获取 API Key
      final jsonStr = await SecureStorageService().read('cloud_api_config');
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final cloudData = Map<String, dynamic>.from(jsonDecode(jsonStr));
      final apiKey = cloudData['apiKey'] as String?;
      if (apiKey == null) return [];

      final now = DateTime.now();
      final entries = <ApiConfigEntry>[];

      // 使用 apiPolicies 创建云端配置条目（显示所有可用模型）
      for (final policy in apiPolicies) {
        final providerName = policy.provider;
        final modelPattern = policy.modelPattern ?? '';
        final modelName = policy.model ?? modelPattern.split(':').last;

        if (providerName.isEmpty || modelPattern.isEmpty) continue;

        final providerEnum = AiProvider.values.firstWhere(
          (p) => p.name.toLowerCase() == providerName.toLowerCase(),
          orElse: () => AiProvider.openAI,
        );
        final providerConfig = AiModelConfig.getConfig(providerEnum);

        // 显示名称：provider + model（不显示默认标注）
        final displayName = '${providerConfig.displayName} $modelName';

        // 获取该模型支持的功能列表
        final compatibleFunctions = ApiFunctionType.values
            .where((f) => AiModelConfig.providerSupportsFunction(providerEnum, f))
            .toList();

        entries.add(ApiConfigEntry(
          id: 'cloud_${providerName}_$modelName',
          name: displayName,
          provider: providerEnum,
          apiKey: apiKey,
          baseUrl: cloudData['baseUrl'] as String? ?? providerConfig.baseUrl,
          model: modelName,
          functions: compatibleFunctions,
          isActive: true,
          isCloudConfig: true,
          cloudMultiplier: policy.multiplier,
          createdAt: now,
          updatedAt: now,
        ));
      }

      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> _syncRuntimeConfig() async {
    if (_config.hasAnyConfig) {
      final defaultEntry = _config.defaultConfigId != null
          ? _config.getConfigById(_config.defaultConfigId!)
          : _config.activeConfigs.firstOrNull;

      if (defaultEntry != null) {
        final apiService = ApiService();
        final providerConfig = AiModelConfig.getConfig(defaultEntry.provider);
        apiService.configure(
          apiKey: defaultEntry.apiKey,
          config: providerConfig,
          customBaseUrl: defaultEntry.baseUrl,
          appId: defaultEntry.appId,
          accessKeySecret: defaultEntry.accessKeySecret,
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    // 只保存本地配置，云端配置从 SecureStorage 加载
    final localOnlyConfig = _config.copyWith(
      configs: _config.configs.where((c) => !c.isCloudConfig).toList(),
    );
    await StorageService.saveMultiApiConfig(localOnlyConfig);
    await _syncRuntimeConfig();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.saveSuccess), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apiConfigManagement),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFunctionAssignmentSection(),
            const SizedBox(height: 24),
            _buildConfigListSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConfigDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFunctionAssignmentSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.functionAssignment,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.functionAssignmentDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildFunctionAssignmentTile(
              icon: Icons.chat_bubble_outline,
              title: l10n.textAnalysis,
              subtitle: l10n.textAnalysisDesc,
              functionType: ApiFunctionType.text,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.mic,
              title: l10n.voiceTranscription,
              subtitle: l10n.voiceTranscriptionDesc,
              functionType: ApiFunctionType.voice,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.record_voice_over,
              title: l10n.realtimeVoiceTranscription,
              subtitle: l10n.realtimeVoiceTranscriptionDesc,
              functionType: ApiFunctionType.voiceRealtime,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.offline_bolt,
              title: l10n.offlineVoiceTranscription,
              subtitle: l10n.offlineVoiceTranscriptionDesc,
              functionType: ApiFunctionType.offlineVoice,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.image,
              title: l10n.imageRecognition,
              subtitle: l10n.imageRecognitionDesc,
              functionType: ApiFunctionType.image,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionAssignmentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ApiFunctionType functionType,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final assignment = _config.functionAssignments.firstWhere(
      (a) => a.functionType == functionType,
      orElse: () => ApiFunctionAssignment(
        functionType: functionType,
        configId: null,
      ),
    );

    // 只过滤出支持当前功能的活跃配置
    final compatibleConfigs = _config.activeConfigs.where((config) {
      return config.isFunctionCompatible(functionType);
    }).toList();

    // 检查当前分配的配置是否兼容
    final currentConfigId = assignment.configId;
    final currentConfig = currentConfigId != null
        ? _config.getConfigById(currentConfigId)
        : null;
    final isCurrentIncompatible = currentConfig != null &&
        !currentConfig.isFunctionCompatible(functionType);

    final dropdownItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(l10n.notConfigured),
      ),
    ];

    for (final config in compatibleConfigs) {
      dropdownItems.add(
        DropdownMenuItem<String?>(
          value: config.id,
          child: Text(config.name, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Row(
        children: [
          Text(title),
          if (isCurrentIncompatible) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.incompatible,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (isCurrentIncompatible && currentConfig != null)
            Text(
              AiModelConfig.getUnsupportedReason(
                  currentConfig.provider, functionType),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.error,
              ),
            ),
        ],
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: DropdownButton<String?>(
          value: isCurrentIncompatible ? null : assignment.configId,
          hint: Text(l10n.selectConfig),
          underline: const SizedBox.shrink(),
          isDense: true,
          items: dropdownItems,
          onChanged: compatibleConfigs.isEmpty
              ? null
              : (value) async {
                  setState(() {
                    final newAssignments = List<ApiFunctionAssignment>.from(
                      _config.functionAssignments,
                    );
                    final index = newAssignments.indexWhere(
                      (a) => a.functionType == functionType,
                    );
                    if (index >= 0) {
                      newAssignments[index] = ApiFunctionAssignment(
                        functionType: functionType,
                        configId: value,
                      );
                    } else {
                      newAssignments.add(ApiFunctionAssignment(
                        functionType: functionType,
                        configId: value,
                      ));
                    }
                    _config = _config.copyWith(functionAssignments: newAssignments);
                  });
                  await StorageService.saveMultiApiConfig(_config);
                  await _syncRuntimeConfig();
                },
        ),
      ),
    );
  }

  Widget _buildConfigListSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.apiConfigList,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_config.configs.isEmpty)
          _buildEmptyState()
        else
          ..._config.configs.map((config) => _buildConfigCard(config)),
      ],
    );
  }

  Widget _buildConfigCard(ApiConfigEntry config) {
    final l10n = AppLocalizations.of(context)!;
    final providerConfig = AiModelConfig.getConfig(config.provider);
    final isActive = config.isActive;
    final hasIncompatible = config.hasIncompatibleFunctions;
    final isCloud = config.isCloudConfig;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: isCloud
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: isCloud ? null : () => _showEditConfigDialog(config),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCloud ? Icons.cloud : _getProviderIcon(config.provider),
                    color: isCloud
                        ? AppColors.primary
                        : (isActive ? AppColors.primary : Colors.grey),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              config.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isActive ? null : Colors.grey,
                              ),
                            ),
                            if (isCloud) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '云端',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (hasIncompatible) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.featureMismatch,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          config.isCustomProvider
                              ? config.customProviderName ?? l10n.custom
                              : providerConfig.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCloud)
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          final newConfigs = _config.configs.map((c) {
                            if (c.id == config.id) {
                              return c.copyWith(isActive: value);
                            }
                            return c;
                          }).toList();
                          _config = _config.copyWith(configs: newConfigs);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 显示模型能力标签（云端配置只显示能力标签，不显示用户选择的功能）
              _buildCapabilityChips(providerConfig),
              // 本地配置显示用户选择的功能（标记不兼容的）
              if (!isCloud) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: config.functions.map((f) {
                    final isCompatible = config.isFunctionCompatible(f);
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompatible)
                            const Icon(
                              Icons.warning_amber,
                              size: 12,
                              color: AppColors.error,
                            ),
                          if (!isCompatible) const SizedBox(width: 4),
                          Text(
                            AiModelConfig.getFunctionTypeLabel(f),
                            style: TextStyle(
                              fontSize: 11,
                              color: isCompatible ? null : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: isCompatible
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (hasIncompatible) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${providerConfig.displayName} ${l10n.providerCapabilityDesc}:',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...config.incompatibleSelectedFunctions.map((f) => Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              '- ${AiModelConfig.getFunctionTypeLabel(f)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${l10n.model}: ${config.model}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (isCloud) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '消耗系数: ${config.cloudMultiplier % 1 == 0 ? config.cloudMultiplier.toInt() : config.cloudMultiplier}x',
                      style: TextStyle(
                        fontSize: 12,
                        color: config.cloudMultiplier > 1.0 ? Colors.orange : AppColors.textSecondary,
                        fontWeight: config.cloudMultiplier > 1.0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
              Text(
                'Key: ${config.apiKey.substring(0, config.apiKey.length > 8 ? 8 : config.apiKey.length)}...',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _testConfig(config),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(l10n.testConnection),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (isCloud) ...[
                    const SizedBox(width: 8),
                    Text(
                      '由套餐分配，不可编辑',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityChips(AiModelConfig config) {
    final l10n = AppLocalizations.of(context)!;
    final capabilities = <Widget>[];

    if (config.supportsTextAnalysis) {
      capabilities.add(_buildCapabilityChip(Icons.text_fields, l10n.textAnalysis, AppColors.success));
    }
    if (config.supportsTranscription || config.supportsOfflineTranscription) {
      capabilities.add(_buildCapabilityChip(Icons.mic, l10n.voiceTranscription, AppColors.success));
    }
    if (config.supportsRealtimeTranscription) {
      capabilities.add(_buildCapabilityChip(Icons.record_voice_over, l10n.realtimeVoiceTranscription, AppColors.success));
    }
    if (config.supportsOfflineTranscription) {
      capabilities.add(_buildCapabilityChip(Icons.offline_bolt, l10n.offlineVoiceTranscription, AppColors.primary));
    }
    if (config.supportsSpeakerDiarization) {
      capabilities.add(_buildCapabilityChip(Icons.people_outline, l10n.textAnalysis, AppColors.primary));
    }
    if (config.supportsOCR) {
      capabilities.add(_buildCapabilityChip(Icons.image_search, l10n.imageRecognition, AppColors.success));
    }
    if (config.supportsChat) {
      capabilities.add(_buildCapabilityChip(Icons.chat_bubble_outline, l10n.textAnalysis, AppColors.success));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: capabilities,
    );
  }

  Widget _buildCapabilityChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConfig(ApiConfigEntry config) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(l10n.testingConnection),
          ],
        ),
      ),
    );

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl ??
              (config.isCustomProvider
                  ? ''
                  : AiModelConfig.getConfig(config.provider).baseUrl),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (config.provider != AiProvider.tingwu) {
        dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
      }

      Response response;
      if (config.provider == AiProvider.gemini) {
        response = await dio.get(
          '/models',
          queryParameters: {'key': config.apiKey},
        );
      } else if (config.provider == AiProvider.tingwu) {
        if (config.accessKeySecret == null || config.accessKeySecret!.isEmpty) {
          throw Exception('通义听悟需要 AccessKey Secret 进行签名');
        }
        final signer = AliyunSigner(
          accessKeyId: config.apiKey,
          accessKeySecret: config.accessKeySecret!,
        );
        final path = '/openapi/tingwu/v2/tasks';
        final queryParams = {'type': 'offline'};
        final testBody = jsonEncode({
          'AppKey': config.appId ?? '',
          'Input': {
            'SourceLanguage': 'cn',
            'TaskKey': 'test_${DateTime.now().millisecondsSinceEpoch}',
          },
        });
        final signedHeaders = signer.signRoaRequest(
          method: 'PUT',
          path: path,
          queryParams: queryParams,
          body: testBody,
        );
        final baseUrl = config.baseUrl ?? 'https://tingwu.cn-beijing.aliyuncs.com';
        try {
          response = await dio.put(
            '$baseUrl$path',
            data: testBody,
            queryParameters: queryParams,
            options: Options(headers: signedHeaders),
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 400) {
            response = e.response!;
          } else {
            rethrow;
          }
        }
      } else {
        response = await dio.get('/models');
      }

      if (mounted) {
        Navigator.pop(context);
        final isSuccess = response.statusCode == 200 ||
            (config.provider == AiProvider.tingwu &&
                response.statusCode == 400);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? l10n.connectionSuccess : l10n.connectionFailed),
              ],
            ),
            content: Text(
              isSuccess
                  ? l10n.connectionSuccessDetail
                  : l10n.connectionFailedDetail(response.statusCode.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: AppColors.error),
                const SizedBox(width: 8),
                Text(l10n.connectionFailed),
              ],
            ),
            content: Text(
              '${l10n.errorGeneric}: ${e.message ?? e.error?.toString() ?? l10n.errorGeneric}\n\n${l10n.checkApiKeyBaseUrlNetwork}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.testError),
            content: Text('${l10n.errorGeneric}: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.api_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            l10n.noApiConfig,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addApiConfigHint,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAddConfigDialog() {
    _showConfigEditorDialog();
  }

  void _showEditConfigDialog(ApiConfigEntry config) {
    _showConfigEditorDialog(existingConfig: config);
  }

  void _showConfigEditorDialog({ApiConfigEntry? existingConfig}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existingConfig != null;
    final nameController =
        TextEditingController(text: existingConfig?.name ?? '');
    final apiKeyController =
        TextEditingController(text: existingConfig?.apiKey ?? '');
    final appIdController =
        TextEditingController(text: existingConfig?.appId ?? '');
    final accessKeySecretController =
        TextEditingController(text: existingConfig?.accessKeySecret ?? '');
    final baseUrlController =
        TextEditingController(text: existingConfig?.baseUrl ?? '');
    final customModelController =
        TextEditingController(text: existingConfig?.model ?? '');
    final customProviderNameController = TextEditingController(
      text: existingConfig?.customProviderName ?? '',
    );

    AiProvider selectedProvider = existingConfig?.provider ?? AiProvider.openAI;
    bool isCustomProvider = existingConfig?.isCustomProvider ?? false;

    // 初始化功能选择：只选择模型支持的功能
    final Set<ApiFunctionType> selectedFunctions = Set.from(
      existingConfig?.functions ?? [ApiFunctionType.text],
    );

    // 封装 dispose 逻辑
    void disposeControllers() {
      nameController.dispose();
      apiKeyController.dispose();
      appIdController.dispose();
      accessKeySecretController.dispose();
      baseUrlController.dispose();
      customModelController.dispose();
      customProviderNameController.dispose();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final providerConfig = AiModelConfig.getConfig(selectedProvider);

          // 获取该模型支持的所有功能
          final compatibleFunctions = ApiFunctionType.values
              .where((f) =>
                  AiModelConfig.providerSupportsFunction(selectedProvider, f))
              .toList();

          // 过滤掉不兼容的已选功能
          final validSelectedFunctions = selectedFunctions
              .where((f) =>
                  AiModelConfig.providerSupportsFunction(selectedProvider, f))
              .toSet();

          // 如果有不兼容的功能被移除，更新状态
          if (validSelectedFunctions.length != selectedFunctions.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setDialogState(() {
                selectedFunctions
                  ..clear()
                  ..addAll(validSelectedFunctions);
                // 确保至少选中一个
                if (selectedFunctions.isEmpty && compatibleFunctions.isNotEmpty) {
                  selectedFunctions.add(compatibleFunctions.first);
                }
              });
            });
          }

          return AlertDialog(
            title: Text(isEditing ? l10n.editConfig : l10n.addConfig),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.configName,
                      hintText: l10n.configNameHint,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Provider selection
                  Text(l10n.selectProvider,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...AiModelConfig.allProviders.map((p) => ChoiceChip(
                            label: Text(p.displayName),
                            selected: selectedProvider == p.provider &&
                                !isCustomProvider,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedProvider = p.provider;
                                  isCustomProvider = false;
                                  customModelController.text = p.defaultModel;
                                  // 自动选择该模型支持的所有功能
                                  selectedFunctions.clear();
                                  selectedFunctions.addAll(
                                    ApiFunctionType.values.where((f) =>
                                        AiModelConfig.providerSupportsFunction(
                                            p.provider, f)),
                                  );
                                });
                              }
                            },
                          )),
                      ChoiceChip(
                        label: Text(l10n.custom),
                        selected: isCustomProvider,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              isCustomProvider = true;
                              selectedProvider = AiProvider.custom;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  if (isCustomProvider) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customProviderNameController,
                      decoration: InputDecoration(
                        labelText: l10n.configName,
                        hintText: l10n.configNameHint,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Functions - 只显示模型支持的功能
                  Row(
                    children: [
                      Text(l10n.supportedFeatures,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.autoFilterIncompatible,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (compatibleFunctions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.noCompatibleFunctions,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: compatibleFunctions.map((f) {
                        return FilterChip(
                          label: Text(AiModelConfig.getFunctionTypeLabel(f)),
                          selected: selectedFunctions.contains(f),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedFunctions.add(f);
                              } else {
                                if (selectedFunctions.length > 1) {
                                  selectedFunctions.remove(f);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // 显示模型能力说明
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${providerConfig.displayName} ${l10n.providerCapabilityDesc}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildModelCapabilityInfo(providerConfig),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: providerConfig.apiKeyPrefix != null
                          ? '${providerConfig.apiKeyPrefix}...'
                          : l10n.apiKeyHint,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (providerConfig.requiresAppId) ...[
                    TextField(
                      controller: appIdController,
                      decoration: InputDecoration(
                        labelText: l10n.appId,
                        hintText: providerConfig.appIdDescription ?? l10n.appId,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (providerConfig.requiresAccessKeySecret) ...[
                    TextField(
                      controller: accessKeySecretController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.accessKeySecret,
                        hintText: providerConfig.accessKeySecretDescription ??
                            l10n.accessKeySecret,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isCustomProvider ||
                      selectedProvider == AiProvider.custom) ...[
                    TextField(
                      controller: baseUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.baseUrl,
                        hintText: 'https://api.example.com/v1',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: customModelController,
                    decoration: InputDecoration(
                      labelText: l10n.modelName,
                      hintText: l10n.modelNameHint,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    final newConfigs = _config.configs
                        .where((c) => c.id != existingConfig.id)
                        .toList();
                    final updatedConfig = _config.copyWith(configs: newConfigs);

                    setState(() {
                      _config = updatedConfig;
                    });

                    await StorageService.saveMultiApiConfig(updatedConfig);
                    await _syncRuntimeConfig();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.deleteButton),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text(l10n.deleteButton),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: compatibleFunctions.isEmpty
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final apiKey = apiKeyController.text.trim();
                        final model = customModelController.text.trim();

                        if (name.isEmpty || apiKey.isEmpty || model.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.fillAllRequired)),
                          );
                          return;
                        }

                        if (selectedFunctions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.selectAtLeastOneFeature)),
                          );
                          return;
                        }

                        // 最终校验：确保所有选择的功能都兼容
                        final incompatible = selectedFunctions
                            .where((f) => !AiModelConfig.providerSupportsFunction(
                                selectedProvider, f))
                            .toList();
                        if (incompatible.isNotEmpty) {
                          final reason = incompatible
                              .map((f) =>
                                  AiModelConfig.getUnsupportedReason(
                                      selectedProvider, f))
                              .join('\n');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.featureIncompatible}:\n$reason'),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          return;
                        }

                        final newConfig = ApiConfigEntry(
                          id: isEditing
                              ? existingConfig.id
                              : 'config_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          provider: selectedProvider,
                          apiKey: apiKey,
                          appId: appIdController.text.trim().isEmpty
                              ? null
                              : appIdController.text.trim(),
                          baseUrl: baseUrlController.text.trim().isEmpty
                              ? null
                              : baseUrlController.text.trim(),
                          model: model,
                          isCustomProvider: isCustomProvider,
                          customProviderName: isCustomProvider
                              ? customProviderNameController.text.trim()
                              : null,
                          functions: selectedFunctions.toList(),
                          isActive: true,
                          createdAt:
                              isEditing ? existingConfig.createdAt : DateTime.now(),
                          updatedAt: DateTime.now(),
                          accessKeySecret: accessKeySecretController.text.trim().isEmpty
                              ? null
                              : accessKeySecretController.text.trim(),
                        );

                        final newConfigs = List<ApiConfigEntry>.from(_config.configs);
                        if (isEditing) {
                          final index = newConfigs.indexWhere(
                            (c) => c.id == existingConfig.id,
                          );
                          if (index >= 0) {
                            newConfigs[index] = newConfig;
                          }
                        } else {
                          newConfigs.add(newConfig);
                        }
                        final updatedConfig = _config.copyWith(configs: newConfigs);

                        setState(() {
                          _config = updatedConfig;
                        });

                        await StorageService.saveMultiApiConfig(updatedConfig);
                        await _syncRuntimeConfig();

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.saveSuccess),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                child: Text(l10n.saveButton),
              ),
            ],
          );
        },
      ),
    ).then((_) => disposeControllers());
  }

  Widget _buildModelCapabilityInfo(AiModelConfig config) {
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[];

    if (config.supportsTextAnalysis) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.textAnalysis, l10n.textAnalysisDesc));
    }
    if (config.supportsTranscription || config.supportsOfflineTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.voiceTranscription, config.asrDescription.isNotEmpty
          ? config.asrDescription.split('\n').first
          : l10n.voiceTranscriptionDesc));
    }
    if (config.supportsRealtimeTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.realtimeVoiceTranscription, config.realtimeAsrDescription.isNotEmpty
          ? config.realtimeAsrDescription.split('\n').first
          : l10n.realtimeVoiceTranscriptionDesc));
    }
    if (config.supportsOfflineTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.offlineVoiceTranscription, l10n.offlineVoiceTranscriptionDesc));
    }
    if (config.supportsSpeakerDiarization) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.textAnalysis, l10n.textAnalysisDesc));
    }
    if (config.supportsOCR) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.imageRecognition, l10n.imageRecognitionDesc));
    }
    if (config.supportsChat) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.textAnalysis, l10n.textAnalysisDesc));
    }

    if (config.limitationNote.isNotEmpty) {
      items.add(const SizedBox(height: 8));
      items.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                config.limitationNote,
                style: const TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(AiProvider provider) {
    switch (provider) {
      case AiProvider.openAI:
        return Icons.smart_toy;
      case AiProvider.claude:
        return Icons.psychology;
      case AiProvider.gemini:
        return Icons.auto_awesome;
      case AiProvider.deepSeek:
        return Icons.search;
      case AiProvider.qwen:
        return Icons.waves;
      case AiProvider.ernie:
        return Icons.language;
      case AiProvider.zhipu:
        return Icons.school;
      case AiProvider.kimi:
        return Icons.nightlight_round;
      case AiProvider.spark:
        return Icons.flash_on;
      case AiProvider.grok:
        return Icons.chat;
      case AiProvider.tingwu:
        return Icons.hearing;
      case AiProvider.custom:
        return Icons.tune;
    }
  }
}
