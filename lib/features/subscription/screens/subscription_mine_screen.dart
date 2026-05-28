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
              const SizedBox(height: 24),
              Text(l10n.quotaDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQuotaCard(context, subscriptionState, l10n),
              const SizedBox(height: 24),
              const Text('API 配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildApiPoliciesCard(context, subscriptionState, l10n),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
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
    final progress = state.totalQuota > 0
        ? state.usedQuota / state.totalQuota
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
                l10n.transcriptionQuota,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.totalQuota - state.usedQuota} ${l10n.minutes}',
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
                '${l10n.minutesUsed(state.usedQuota, state.totalQuota)}',
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
      'qwen': '通义千问',
      'deepseek': 'DeepSeek',
      'openai': 'OpenAI',
      'anthropic': 'Anthropic',
      'gemini': 'Gemini',
      'grok': 'Grok',
      'all': '全部',
    };

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
          ...state.apiPolicies.map((policy) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerNames[policy.provider] ?? policy.provider,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (policy.modelPattern != null)
                          Text(
                            '模型: ${policy.modelPattern}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: policy.isAllowed
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      policy.isAllowed ? '${policy.multiplier}x' : '禁用',
                      style: TextStyle(
                        color: policy.isAllowed ? AppColors.primary : Colors.red,
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
            '消耗倍数：每次调用消耗的配额单位倍数',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
