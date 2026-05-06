import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';

class ApiKeyConfigScreen extends ConsumerStatefulWidget {
  const ApiKeyConfigScreen({super.key});

  @override
  ConsumerState<ApiKeyConfigScreen> createState() => _ApiKeyConfigScreenState();
}

class _ApiKeyConfigScreenState extends ConsumerState<ApiKeyConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _customModelController = TextEditingController();
  
  AiProvider _selectedProvider = AiProvider.openAI;
  String _selectedModel = '';
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isKeyVisible = false;
  bool _useCustomModel = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ref.read(apiConfigProvider.future);
      if (config != null && mounted) {
        setState(() {
          _apiKeyController.text = config.apiKey;
          _baseUrlController.text = config.baseUrl ?? '';
          
          final providerConfig = AiModelConfig.getConfigByName(config.provider);
          if (providerConfig != null) {
            _selectedProvider = providerConfig.provider;
            _selectedModel = config.model.isEmpty ? providerConfig.defaultModel : config.model;
          } else {
            _selectedProvider = AiProvider.openAI;
            _selectedModel = AiModelConfig.openAI.defaultModel;
          }
        });
      } else if (mounted) {
        setState(() {
          _selectedProvider = AiProvider.openAI;
          _selectedModel = AiModelConfig.openAI.defaultModel;
        });
      }
    } catch (e) {
      debugPrint('加载API配置失败: $e');
      if (mounted) {
        setState(() {
          _selectedProvider = AiProvider.openAI;
          _selectedModel = AiModelConfig.openAI.defaultModel;
        });
      }
    }
  }

  AiModelConfig get _currentConfig => AiModelConfig.getConfig(_selectedProvider);

  Future<void> _testApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
    });

    try {
      final result = await ref.read(settingsNotifierProvider.notifier).testApiKey(
            apiKey: _apiKeyController.text,
            provider: _selectedProvider,
            baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
            model: _effectiveModel,
          );

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Key is valid!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Key is invalid. Please check your key.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await ref.read(settingsNotifierProvider.notifier).saveApiConfig(
            apiKey: _apiKeyController.text,
            provider: _currentConfig.name,
            baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
            model: _effectiveModel,
          );

      if (mounted) {
        if (success) {
          ref.invalidate(apiConfigProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置保存成功'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置保存失败'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  String get _effectiveModel {
    if (_useCustomModel && _customModelController.text.isNotEmpty) {
      return _customModelController.text.trim();
    }
    return _selectedModel;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = _currentConfig;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apiKeySettings),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _saveConfig,
              child: Text(l10n.saveButton),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'International'),
              const SizedBox(height: 8),
              ...AiModelConfig.internationalProviders.map((p) => _buildProviderTile(p)),
              
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Domestic (China)'),
              const SizedBox(height: 8),
              ...AiModelConfig.domesticProviders.map((p) => _buildProviderTile(p)),
              
              const SizedBox(height: 24),
              _buildProviderTile(AiModelConfig.custom),
              
              const SizedBox(height: 24),

              _buildProviderDetailCard(context, config),
              const SizedBox(height: 24),

              TextFormField(
                controller: _apiKeyController,
                obscureText: !_isKeyVisible,
                decoration: InputDecoration(
                  labelText: l10n.openaiApiKey,
                  hintText: config.apiKeyPrefix != null 
                    ? '${config.apiKeyPrefix}...' 
                    : 'Enter your API key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isKeyVisible = !_isKeyVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter API Key';
                  }
                  if (config.apiKeyPrefix != null && !value.startsWith(config.apiKeyPrefix!)) {
                    return 'API Key should start with ${config.apiKeyPrefix}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_selectedProvider == AiProvider.custom) ...[
                TextFormField(
                  controller: _baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Base URL',
                    hintText: 'https://api.example.com/v1',
                  ),
                  validator: (value) {
                    if (_selectedProvider == AiProvider.custom && 
                        (value == null || value.isEmpty)) {
                      return 'Please enter custom base URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (config.availableModels.isNotEmpty && !_useCustomModel) ...[
                DropdownButtonFormField<String>(
                  value: _selectedModel.isEmpty ? config.defaultModel : _selectedModel,
                  decoration: const InputDecoration(
                    labelText: 'Chat Model',
                  ),
                  items: config.availableModels.map((model) {
                    final detail = config.modelDetails.where((d) => d.name == model).firstOrNull;
                    return DropdownMenuItem(
                      value: model,
                      child: Row(
                        children: [
                          Text(model),
                          if (detail != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: detail.recommended ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                detail.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: detail.recommended ? AppColors.success : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedModel = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],

              if (_useCustomModel) ...[
                TextFormField(
                  controller: _customModelController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Model Name',
                    hintText: 'e.g., gpt-4o, kimi-k2.6, qwen3.6-max',
                  ),
                  validator: (value) {
                    if (_useCustomModel && (value == null || value.isEmpty)) {
                      return 'Please enter custom model name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Checkbox(
                    value: _useCustomModel,
                    onChanged: (value) {
                      setState(() {
                        _useCustomModel = value ?? false;
                        if (!_useCustomModel) {
                          _selectedModel = config.defaultModel;
                        }
                      });
                    },
                  ),
                  const Expanded(child: Text('Use custom model name', style: TextStyle(fontSize: 13))),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testApiKey,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isTesting ? 'Testing...' : 'Test API Key'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderDetailCard(BuildContext context, AiModelConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(_getProviderIcon(config.provider), color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCapabilityRow(
                  Icons.mic,
                  'Voice Transcription',
                  config.supportsTranscription,
                  subtitle: config.supportsTranscription 
                    ? 'ASR Model: ${config.asrModel}\n${config.asrDescription}'
                    : 'Not supported',
                ),
                const SizedBox(height: 12),
                _buildCapabilityRow(
                  Icons.chat_bubble_outline,
                  'Chat / Summary / Title',
                  config.supportsChat,
                  subtitle: config.supportsChat ? 'Uses your selected chat model' : null,
                ),

                if (config.transcriptionLimit != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.timer_outlined,
                    'Max Audio Duration',
                    config.transcriptionLimit!.durationLabel,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.attach_file,
                    'Max File Size',
                    '${config.transcriptionLimit!.maxFileSizeMB}MB',
                  ),
                  if (config.transcriptionLimit!.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              config.transcriptionLimit!.note,
                              style: const TextStyle(fontSize: 11, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                if (config.limitationNote.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
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
                  ),
                ],

                if (config.pricingNote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.payments_outlined,
                    'Pricing',
                    config.pricingNote,
                  ),
                ],

                if (config.modelDetails.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Available Models',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...config.modelDetails.map((detail) => _buildModelDetailRow(detail)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(IconData icon, String label, bool isSupported, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isSupported ? AppColors.success : AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSupported ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSupported ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSupported ? 'Supported' : 'Not Available',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSupported ? AppColors.success : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null && isSupported) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildModelDetailRow(ModelDetail detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Text(
                  detail.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: detail.recommended ? FontWeight.bold : FontWeight.normal,
                    color: detail.recommended ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (detail.recommended) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'Rec',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              detail.description,
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
          if (detail.contextWindow.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                detail.contextWindow,
                style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildProviderTile(AiModelConfig providerConfig) {
    final isSelected = _selectedProvider == providerConfig.provider;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          _getProviderIcon(providerConfig.provider),
          color: isSelected ? AppColors.primary : null,
        ),
        title: Text(
          providerConfig.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (providerConfig.supportsTranscription) ...[
              const Icon(Icons.mic, size: 12, color: AppColors.success),
              const SizedBox(width: 2),
              Text(
                'ASR',
                style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.success),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 2),
            Text(
              'Chat',
              style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.textTertiary),
            ),
            if (providerConfig.transcriptionLimit != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.timer_outlined, size: 12, color: isSelected ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(width: 2),
              Text(
                providerConfig.transcriptionLimit!.durationLabel,
                style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.textTertiary),
              ),
            ],
          ],
        ),
        trailing: isSelected 
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
        onTap: () {
          setState(() {
            _selectedProvider = providerConfig.provider;
            _selectedModel = _currentConfig.defaultModel;
          });
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
        return Icons.chat;
      case AiProvider.ernie:
        return Icons.language;
      case AiProvider.zhipu:
        return Icons.science;
      case AiProvider.kimi:
        return Icons.nightlight_round;
      case AiProvider.spark:
        return Icons.mic;
      case AiProvider.grok:
        return Icons.bolt;
      case AiProvider.custom:
        return Icons.settings;
    }
  }
}
