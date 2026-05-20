import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

class ApiKeyWizardScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const ApiKeyWizardScreen({super.key, this.isFromSettings = false});

  @override
  ConsumerState<ApiKeyWizardScreen> createState() => _ApiKeyWizardScreenState();
}

class _ApiKeyWizardScreenState extends ConsumerState<ApiKeyWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  String _selectedScenario = 'meeting';
  AiProvider _selectedProvider = AiProvider.deepSeek;
  final _apiKeyController = TextEditingController();
  bool _isKeyVisible = false;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _testPassed = false;

  static const _scenarios = [
    {
      'id': 'meeting',
      'icon': Icons.groups,
      'title': '会议/沟通记录',
      'desc': '客户沟通、团队会议、电话录音',
      'recommend': 'DeepSeek / Qwen',
    },
    {
      'id': 'idea',
      'icon': Icons.lightbulb_outline,
      'title': '灵感/创意捕捉',
      'desc': '随时记录想法，AI帮你梳理',
      'recommend': 'DeepSeek / Gemini',
    },
    {
      'id': 'study',
      'icon': Icons.school_outlined,
      'title': '学习/课堂笔记',
      'desc': '课程录音、读书笔记、知识整理',
      'recommend': 'Qwen / Gemini',
    },
    {
      'id': 'all',
      'icon': Icons.all_inclusive,
      'title': '全部场景',
      'desc': '录音转写 + AI分析，完整体验',
      'recommend': 'Qwen（转写+分析）',
    },
  ];

  static const _providerRecommendations = {
    'meeting': [AiProvider.deepSeek, AiProvider.qwen, AiProvider.gemini],
    'idea': [AiProvider.deepSeek, AiProvider.gemini, AiProvider.qwen],
    'study': [AiProvider.qwen, AiProvider.gemini, AiProvider.deepSeek],
    'all': [AiProvider.qwen, AiProvider.gemini, AiProvider.deepSeek],
  };

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _testAndSave() async {
    if (_apiKeyController.text.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testPassed = false;
    });

    try {
      final config = AiModelConfig.getConfig(_selectedProvider);
      final result =
          await ref.read(settingsNotifierProvider.notifier).testApiKey(
                apiKey: _apiKeyController.text,
                provider: _selectedProvider,
                baseUrl: null,
                model: config.defaultModel,
              );

      if (result) {
        setState(() => _testPassed = true);

        setState(() => _isSaving = true);
        final saveResult =
            await ref.read(settingsNotifierProvider.notifier).saveApiConfig(
                  apiKey: _apiKeyController.text,
                  provider: config.name,
                  baseUrl: null,
                  model: config.defaultModel,
                );

        if (mounted) {
          if (saveResult) {
            ref.invalidate(apiConfigProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('配置成功！畅记已准备就绪 🎉'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('保存失败，请重试'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key无效，请检查后重试'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('验证失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildStepIndicator(theme),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Scenario(theme),
                  _buildStep2Provider(theme),
                  _buildStep3ApiKey(theme),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (widget.isFromSettings || _currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          if (!widget.isFromSettings)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后配置'),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCurrent
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Scenario(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '你好！👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '畅记需要配置AI服务才能工作。\n只需3步，1分钟搞定！',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '第一步：你的主要场景是？',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._scenarios.map((s) => _buildScenarioCard(s)),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> scenario) {
    final isSelected = _selectedScenario == scenario['id'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedScenario = scenario['id'] as String;
            final recs = _providerRecommendations[_selectedScenario]!;
            _selectedProvider = recs.first;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.1))
                      .withOpacity(isSelected ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  scenario['icon'] as IconData,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scenario['desc'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Provider(ThemeData theme) {
    final recommendations =
        _providerRecommendations[_selectedScenario] ?? [AiProvider.deepSeek];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '第二步：选择AI服务商',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '推荐以下服务商（按性价比排序）',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final provider = entry.value;
            final config = AiModelConfig.getConfig(provider);
            final isSelected = _selectedProvider == provider;
            return _buildProviderRecommendCard(config, index, isSelected);
          }),
          const SizedBox(height: 16),
          Text(
            '💡 提示：你只需要填API Key，其他参数已自动配置好',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRecommendCard(
      AiModelConfig config, int rank, bool isSelected) {
    final rankLabels = ['推荐', '备选', '备选'];
    final rankColors = [
      AppColors.success,
      AppColors.info,
      AppColors.textTertiary
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedProvider = config.provider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getProviderIcon(config.provider),
                      color: isSelected ? AppColors.primary : null, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          config.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rankColors[rank].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rankLabels[rank],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rankColors[rank],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                config.description,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (config.supportsTranscription) ...[
                    _buildCapabilityTag(Icons.mic, '转写', AppColors.success),
                    const SizedBox(width: 8),
                  ],
                  _buildCapabilityTag(
                      Icons.chat_bubble_outline, 'AI分析', AppColors.info),
                  const SizedBox(width: 8),
                  _buildCapabilityTag(Icons.payments_outlined,
                      config.pricingNote, AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityTag(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }

  Widget _buildStep3ApiKey(ThemeData theme) {
    final config = AiModelConfig.getConfig(_selectedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '第三步：输入API Key',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '填入你的 ${config.displayName} API Key 即可完成配置',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getProviderIcon(config.provider),
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      config.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '模型: ${config.defaultModel}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (config.supportsTranscription)
                  Text(
                    '转写模型: ${config.asrModel}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _apiKeyController,
            obscureText: !_isKeyVisible,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: config.apiKeyPrefix != null
                  ? '${config.apiKeyPrefix}...'
                  : '输入你的 API Key',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_isKeyVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _isKeyVisible = !_isKeyVisible),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() => _testPassed = false),
          ),
          const SizedBox(height: 16),
          _buildGetKeyGuide(config),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '你的API Key仅存储在本地设备，加密保存，不会上传到任何第三方服务器。',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetKeyGuide(AiModelConfig config) {
    String guideText;

    switch (config.provider) {
      case AiProvider.openAI:
        guideText = '前往 OpenAI 平台获取 API Key';
        break;
      case AiProvider.deepSeek:
        guideText = '前往 DeepSeek 平台获取 API Key';
        break;
      case AiProvider.qwen:
        guideText = '前往阿里云 DashScope 获取 API Key';
        break;
      case AiProvider.gemini:
        guideText = '前往 Google AI Studio 获取 API Key';
        break;
      default:
        guideText = '前往服务商官网获取 API Key';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '没有API Key？$guideText',
              style: const TextStyle(fontSize: 12, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('上一步'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: _currentStep < 2
                ? ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('下一步'),
                  )
                : ElevatedButton(
                    onPressed: _isTesting || _isSaving ? null : _testAndSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isTesting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('验证中...'),
                            ],
                          )
                        : _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('保存中...'),
                                ],
                              )
                            : const Text('验证并保存'),
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
      case AiProvider.tingwu:
        return Icons.hearing;
      case AiProvider.custom:
        return Icons.settings;
    }
  }
}
