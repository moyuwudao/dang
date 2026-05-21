import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/aliyun_signer.dart';

class MultiApiConfigScreen extends ConsumerStatefulWidget {
  const MultiApiConfigScreen({super.key});

  @override
  ConsumerState<MultiApiConfigScreen> createState() =>
      _MultiApiConfigScreenState();
}

class _MultiApiConfigScreenState extends ConsumerState<MultiApiConfigScreen> {
  MultiApiConfig _config = const MultiApiConfig();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await StorageService.getMultiApiConfig();
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _syncRuntimeConfig() async {
    if (_config.hasAnyConfig) {
      final defaultEntry = _config.defaultConfigId != null
          ? _config.getConfigById(_config.defaultConfigId!)
          : _config.activeConfigs.firstOrNull;

      if (defaultEntry != null) {
        final apiService = ref.read(apiServiceProvider);
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
    await StorageService.saveMultiApiConfig(_config);
    await _syncRuntimeConfig();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('配置已保存'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('API配置管理'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
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
                const Text(
                  '功能分配',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '为不同功能选择使用的API配置，仅显示支持该功能的模型',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildFunctionAssignmentTile(
              icon: Icons.chat_bubble_outline,
              title: '文本分析',
              subtitle: 'AI分析、摘要、标题生成',
              functionType: ApiFunctionType.text,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.mic,
              title: '语音转写',
              subtitle: '录音后转文字',
              functionType: ApiFunctionType.voice,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.record_voice_over,
              title: '语音实时转写',
              subtitle: '录音时实时转文字',
              functionType: ApiFunctionType.voiceRealtime,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.offline_bolt,
              title: '离线语音转写',
              subtitle: '提交音频文件进行离线转写（支持说话人分离）',
              functionType: ApiFunctionType.offlineVoice,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.image,
              title: '图像识别',
              subtitle: '图片内容识别（OCR）',
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
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('未配置'),
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
              child: const Text(
                '不兼容',
                style: TextStyle(
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
          hint: const Text('选择配置'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API配置列表',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final providerConfig = AiModelConfig.getConfig(config.provider);
    final isActive = config.isActive;
    final hasIncompatible = config.hasIncompatibleFunctions;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditConfigDialog(config),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getProviderIcon(config.provider),
                    color: isActive ? AppColors.primary : Colors.grey,
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
                            if (hasIncompatible) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '功能不匹配',
                                  style: TextStyle(
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
                              ? config.customProviderName ?? '自定义'
                              : providerConfig.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              // 显示模型能力标签
              _buildCapabilityChips(providerConfig),
              const SizedBox(height: 8),
              // 显示用户选择的功能（标记不兼容的）
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
                            '${providerConfig.displayName} 不支持以下功能:',
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
                '模型: ${config.model}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
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
                    label: const Text('测试连接'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityChips(AiModelConfig config) {
    final capabilities = <Widget>[];

    if (config.supportsTextAnalysis) {
      capabilities.add(_buildCapabilityChip(Icons.text_fields, '文本分析', AppColors.success));
    }
    if (config.supportsTranscription || config.supportsOfflineTranscription) {
      capabilities.add(_buildCapabilityChip(Icons.mic, '语音转写', AppColors.success));
    }
    if (config.supportsRealtimeTranscription) {
      capabilities.add(_buildCapabilityChip(Icons.record_voice_over, '实时转写', AppColors.success));
    }
    if (config.supportsOfflineTranscription) {
      capabilities.add(_buildCapabilityChip(Icons.offline_bolt, '离线转写', AppColors.primary));
    }
    if (config.supportsSpeakerDiarization) {
      capabilities.add(_buildCapabilityChip(Icons.people_outline, '说话人分离', AppColors.primary));
    }
    if (config.supportsOCR) {
      capabilities.add(_buildCapabilityChip(Icons.image_search, '图像识别', AppColors.success));
    }
    if (config.supportsChat) {
      capabilities.add(_buildCapabilityChip(Icons.chat_bubble_outline, '对话', AppColors.success));
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在测试连接...'),
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
                Text(isSuccess ? '连接成功' : '连接失败'),
              ],
            ),
            content: Text(
              isSuccess
                  ? 'API配置有效，可以正常使用。'
                  : '状态码: ${response.statusCode}\n请检查API Key和Base URL是否正确。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
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
            title: const Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                SizedBox(width: 8),
                Text('连接失败'),
              ],
            ),
            content: Text(
              '错误信息: ${e.message ?? e.error?.toString() ?? "未知错误"}\n\n请检查:\n1. API Key是否正确\n2. Base URL是否正确\n3. 网络连接是否正常',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
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
            title: const Text('测试出错'),
            content: Text('错误: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
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
            '暂无API配置',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            '点击右下角 + 添加配置',
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
            title: Text(isEditing ? '编辑配置' : '添加配置'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '配置名称',
                      hintText: '例如：OpenAI-文本',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Provider selection
                  const Text('选择提供商',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
                        label: const Text('自定义'),
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
                      decoration: const InputDecoration(
                        labelText: '自定义提供商名称',
                        hintText: '例如：SiliconFlow',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Functions - 只显示模型支持的功能
                  Row(
                    children: [
                      const Text('支持的功能',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '已自动过滤不兼容功能',
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
                              '${providerConfig.displayName} 暂无可用的功能支持，请选择其他提供商。',
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
                          '${providerConfig.displayName} 能力说明',
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
                          : '输入API Key',
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (providerConfig.requiresAppId) ...[
                    TextField(
                      controller: appIdController,
                      decoration: InputDecoration(
                        labelText: 'App ID',
                        hintText: providerConfig.appIdDescription ?? '输入App ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (providerConfig.requiresAccessKeySecret) ...[
                    TextField(
                      controller: accessKeySecretController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'AccessKey Secret',
                        hintText: providerConfig.accessKeySecretDescription ??
                            '输入AccessKey Secret',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isCustomProvider ||
                      selectedProvider == AiProvider.custom) ...[
                    TextField(
                      controller: baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'https://api.example.com/v1',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: customModelController,
                    decoration: const InputDecoration(
                      labelText: '模型名称',
                      hintText: '例如：gpt-4o-mini',
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
                        const SnackBar(
                          content: Text('配置已删除'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('删除'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
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
                            const SnackBar(content: Text('请填写所有必填项')),
                          );
                          return;
                        }

                        if (selectedFunctions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('至少选择一个功能')),
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
                              content: Text('功能不兼容:\n$reason'),
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
                            const SnackBar(
                              content: Text('配置已保存'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    ).then((_) => disposeControllers());
  }

  Widget _buildModelCapabilityInfo(AiModelConfig config) {
    final items = <Widget>[];

    if (config.supportsTextAnalysis) {
      items.add(_buildInfoRow(Icons.check_circle, '文本分析', '支持AI分析、摘要、标题生成'));
    }
    if (config.supportsTranscription || config.supportsOfflineTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, '语音转写', config.asrDescription.isNotEmpty
          ? config.asrDescription.split('\n').first
          : '支持录音转文字'));
    }
    if (config.supportsRealtimeTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, '实时转写', config.realtimeAsrDescription.isNotEmpty
          ? config.realtimeAsrDescription.split('\n').first
          : '支持实时语音转写'));
    }
    if (config.supportsOfflineTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, '离线转写', '支持提交音频文件进行离线转写'));
    }
    if (config.supportsSpeakerDiarization) {
      items.add(_buildInfoRow(Icons.check_circle, '说话人分离', '支持区分不同发言人'));
    }
    if (config.supportsOCR) {
      items.add(_buildInfoRow(Icons.check_circle, '图像识别', '支持图片内容识别'));
    }
    if (config.supportsChat) {
      items.add(_buildInfoRow(Icons.check_circle, '对话', '支持多轮对话'));
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
