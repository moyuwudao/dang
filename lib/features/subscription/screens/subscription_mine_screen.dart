import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/subscription_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SubscriptionMineScreen extends ConsumerStatefulWidget {
  const SubscriptionMineScreen({super.key});

  @override
  ConsumerState<SubscriptionMineScreen> createState() => _SubscriptionMineScreenState();
}

class _SubscriptionMineScreenState extends ConsumerState<SubscriptionMineScreen> {
  bool _hasLoggedOut = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listen(
      authNotifierProvider,
      (previous, next) {
        final wasLoggedIn = previous?.valueOrNull?.isLoggedIn ?? false;
        final isLoggedIn = next.valueOrNull?.isLoggedIn ?? false;
        
        if (isLoggedIn && !wasLoggedIn) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _refreshData();
          });
        } else if (!isLoggedIn && wasLoggedIn) {
          _hasLoggedOut = true;
        }
      },
    );
  }

  Future<void> _refreshData() async {
    if (_hasLoggedOut) {
      _hasLoggedOut = false;
    }
    try {
      ref.invalidate(subscriptionNotifierProvider);
      ref.invalidate(subscriptionPlansProvider);
      ref.invalidate(packagePlansProvider);
      ref.invalidate(userBalanceProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.mySubscription),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ref.watch(subscriptionNotifierProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCurrentPlanCard(context, const SubscriptionState(), l10n),
              const SizedBox(height: 24),
              Text(l10n.quotaDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQuotaCard(context, const SubscriptionState(), l10n),
              const SizedBox(height: 24),
              const Text('API 配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildApiPoliciesCard(context, const SubscriptionState(), l10n),
              const SizedBox(height: 100),
            ],
          ),
          data: (subscriptionState) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCurrentPlanCard(context, subscriptionState, l10n),
              // 多套餐时显示切换 UI
              if (subscriptionState.subscriptions.length > 1) ...[
                const SizedBox(height: 12),
                _buildSubscriptionSwitcher(context, ref, subscriptionState),
              ],
              const SizedBox(height: 24),
              Text(l10n.quotaDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQuotaCard(context, subscriptionState, l10n),
              const SizedBox(height: 24),
              const Text('API 配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                '当前套餐分配的 API 配置、模型和消耗系数',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildDefaultConfigsCard(context, subscriptionState),
              const SizedBox(height: 12),
              _buildApiPoliciesCard(context, subscriptionState, l10n),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // 多套餐切换 UI
  Widget _buildSubscriptionSwitcher(BuildContext context, WidgetRef ref, SubscriptionState state) {
    final activeId = state.activeSubscriptionId ?? state.subscriptions.first.subscriptionId;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: state.subscriptions.map((sub) {
        final isActive = sub.subscriptionId == activeId;
        return ChoiceChip(
          label: Text(
            sub.planName,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textPrimary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          selected: isActive,
          onSelected: (selected) async {
            if (selected) {
              await ref.read(subscriptionNotifierProvider.notifier).switchSubscription(sub.subscriptionId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已切换至「${sub.planName}」')),
                );
              }
            }
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isActive ? AppColors.primary : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  // 套餐分配的各功能默认 API
  Widget _buildDefaultConfigsCard(BuildContext context, SubscriptionState state) {
    final configs = state.defaultConfigs;
    if (configs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '当前套餐未配置功能默认 API',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: configs.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_getFunctionTypeName(c.functionType)}:',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.modelPattern,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFunctionTypeName(String functionType) {
    switch (functionType) {
      case 'textAnalysis':
        return '文本分析';
      case 'speechTranscribe':
        return '语言转写';
      case 'speechRealtime':
        return '实时语音转写';
      case 'speechOffline':
        return '离线语音转写';
      case 'imageRecognition':
        return '图像识别';
      case 'transcribe':
        return '实时转写';
      case 'transcribeFile':
        return '文件转写';
      case 'summary':
        return '摘要';
      case 'translate':
        return '翻译';
      case 'mindMap':
        return '思维导图';
      case 'image':
        return '图像识别';
      default:
        return functionType;
    }
  }

  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionState state, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.currentPlan,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isActive
                      ? Colors.white.withOpacity(0.2)
                      : Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.isActive ? l10n.statusActive : l10n.statusExpired,
                  style: TextStyle(
                    color: state.isActive ? Colors.white : Colors.red[100],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.planName ?? l10n.freePlan,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (state.expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.createdAt}${state.expiresAt.toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaCard(BuildContext context, SubscriptionState state, AppLocalizations l10n) {
    final totalTokens = state.tokenBalance.totalTokens;
    final usedTokens = state.tokenBalance.usedTokens;
    final progress = totalTokens > 0
        ? usedTokens / totalTokens
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Token 余额',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.tokenBalance.balanceTokens} Tokens',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已用 $usedTokens / 总计 $totalTokens Tokens',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiPoliciesCard(BuildContext context, SubscriptionState state, AppLocalizations l10n) {
    if (state.apiPolicies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text(
            '暂无API配置信息',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final providerNames = {
      'alibabaQwen': '通义千问',
      'alibabaQwenVl': '通义千问VL',
      'qwen': '通义千问',
      'deepseek': 'DeepSeek',
      'openai': 'OpenAI',
      'anthropic': 'Anthropic',
      'gemini': 'Gemini',
      'grok': 'Grok',
      'all': '全部',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...state.apiPolicies.map((policy) {
            final modelName = policy.model ?? policy.modelPattern ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: policy.isAllowed ? AppColors.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerNames[policy.provider] ?? policy.provider,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (modelName.isNotEmpty)
                          Text(
                            modelName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: policy.isAllowed
                          ? (policy.multiplier > 1.0
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1))
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      policy.isAllowed
                          ? '${_formatMultiplier(policy.multiplier)}x'
                          : '禁用',
                      style: TextStyle(
                        color: policy.isAllowed
                            ? (policy.multiplier > 1.0 ? AppColors.warning : AppColors.primary)
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          const Text(
            '消耗倍数：每次调用消耗的 Token 倍数（>1 表示加价模型）',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatMultiplier(double m) {
    if (m == m.toInt()) return m.toInt().toString();
    return m.toStringAsFixed(1);
  }
}
