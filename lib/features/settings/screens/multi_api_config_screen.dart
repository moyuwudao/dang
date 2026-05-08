import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';

class MultiApiConfigScreen extends ConsumerStatefulWidget {
  const MultiApiConfigScreen({super.key});

  @override
  ConsumerState<MultiApiConfigScreen> createState() => _MultiApiConfigScreenState();
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

  Future<void> _saveConfig() async {
    await StorageService.saveMultiApiConfig(_config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存'), backgroundColor: AppColors.success),
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
            const Text(
              '功能分配',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '为不同功能选择使用的API配置',
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
              subtitle: '录音转文字',
              functionType: ApiFunctionType.voice,
            ),
            const Divider(),
            _buildFunctionAssignmentTile(
              icon: Icons.image,
              title: '图像识别',
              subtitle: '图片内容识别（预留）',
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
        configId: _config.configs.isNotEmpty ? _config.configs.first.id : null,
      ),
    );

    final availableConfigs = _config.activeConfigs;

    final dropdownItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('使用默认'),
      ),
    ];
    for (final config in availableConfigs) {
      dropdownItems.add(
        DropdownMenuItem<String?>(
          value: config.id,
          child: Text(config.name, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String?>(
        value: assignment.configId,
        hint: const Text('选择配置'),
        underline: const SizedBox.shrink(),
        items: dropdownItems,
        onChanged: (value) async {
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
          // Auto-save function assignment changes
          await StorageService.saveMultiApiConfig(_config);
        },
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
                        Text(
                          config.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                        Text(
                          config.isCustomProvider
                              ? config.customProviderName ?? '自定义'
                              : providerConfig.displayName,
                          style: TextStyle(
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
              Wrap(
                spacing: 8,
                children: config.functions.map((f) {
                  final labels = {
                    ApiFunctionType.text: '文本',
                    ApiFunctionType.voice: '语音',
                    ApiFunctionType.image: '图像',
                  };
                  return Chip(
                    label: Text(
                      labels[f] ?? f.name,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '模型: ${config.model}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'Key: ${config.apiKey.substring(0, config.apiKey.length > 8 ? 8 : config.apiKey.length)}...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

      // Set auth header
      dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';

      Response response;
      if (config.provider == AiProvider.gemini) {
        response = await dio.get(
          '/models',
          queryParameters: {'key': config.apiKey},
        );
      } else {
        response = await dio.get('/models');
      }

      if (mounted) {
        Navigator.pop(context);
        final isSuccess = response.statusCode == 200;
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
    final nameController = TextEditingController(text: existingConfig?.name ?? '');
    final apiKeyController = TextEditingController(text: existingConfig?.apiKey ?? '');
    final baseUrlController = TextEditingController(text: existingConfig?.baseUrl ?? '');
    final customModelController = TextEditingController(text: existingConfig?.model ?? '');
    final customProviderNameController = TextEditingController(
      text: existingConfig?.customProviderName ?? '',
    );

    AiProvider selectedProvider = existingConfig?.provider ?? AiProvider.openAI;
    bool isCustomProvider = existingConfig?.isCustomProvider ?? false;
    Set<ApiFunctionType> selectedFunctions = Set.from(
      existingConfig?.functions ?? [ApiFunctionType.text],
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final providerConfig = AiModelConfig.getConfig(selectedProvider);

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
                  const Text('选择提供商', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...AiModelConfig.allProviders.map((p) => ChoiceChip(
                            label: Text(p.displayName),
                            selected: selectedProvider == p.provider && !isCustomProvider,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedProvider = p.provider;
                                  isCustomProvider = false;
                                  customModelController.text = p.defaultModel;
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

                  // Functions
                  const Text('支持的功能', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ApiFunctionType.values.map((f) {
                      final labels = {
                        ApiFunctionType.text: '文本分析',
                        ApiFunctionType.voice: '语音转写',
                        ApiFunctionType.image: '图像识别',
                      };
                      return FilterChip(
                        label: Text(labels[f] ?? f.name),
                        selected: selectedFunctions.contains(f),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedFunctions.add(f);
                            } else {
                              selectedFunctions.remove(f);
                            }
                          });
                        },
                      );
                    }).toList(),
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

                  if (isCustomProvider || selectedProvider == AiProvider.custom) ...[
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
                        .where((c) => c.id != existingConfig!.id)
                        .toList();
                    final updatedConfig = _config.copyWith(configs: newConfigs);

                    setState(() {
                      _config = updatedConfig;
                    });

                    await StorageService.saveMultiApiConfig(updatedConfig);

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
                onPressed: () async {
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

                  final newConfig = ApiConfigEntry(
                    id: isEditing
                        ? existingConfig!.id
                        : 'config_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    provider: selectedProvider,
                    apiKey: apiKey,
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
                    createdAt: isEditing ? existingConfig!.createdAt : DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  final newConfigs = List<ApiConfigEntry>.from(_config.configs);
                  if (isEditing) {
                    final index = newConfigs.indexWhere(
                      (c) => c.id == existingConfig!.id,
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

                  // Auto-save to storage immediately
                  await StorageService.saveMultiApiConfig(updatedConfig);

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
      case AiProvider.custom:
        return Icons.tune;
    }
  }
}
