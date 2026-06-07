import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/subscription_provider.dart';
import '../models/plan_model.dart';

class SubscriptionStoreScreen extends ConsumerStatefulWidget {
  const SubscriptionStoreScreen({super.key});

  @override
  ConsumerState<SubscriptionStoreScreen> createState() =>
      _SubscriptionStoreScreenState();
}

class _SubscriptionStoreScreenState
    extends ConsumerState<SubscriptionStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_l10n.purchasePlan),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: _l10n.monthlySubscription),
            Tab(text: _l10n.planPackage),
            Tab(text: _l10n.rechargeCenter),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionTab(),
          _buildPackageTab(),
          _buildRechargeTab(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    return plansAsync.when(
      data: (plans) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) =>
            _buildPlanCard(plans[index], isSubscription: true),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  Widget _buildPackageTab() {
    final plansAsync = ref.watch(packagePlansProvider);
    return plansAsync.when(
      data: (plans) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) =>
            _buildPlanCard(plans[index], isSubscription: false),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  Widget _buildRechargeTab() {
    final balanceAsync = ref.watch(userBalanceProvider);
    final rechargeAmounts = [50, 100, 200, 500];

    return StatefulBuilder(
      builder: (context, setState) {
        int selectedAmount = 100;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
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
                    Text(
                      _l10n.accountBalance,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${(balanceAsync.value ?? 0) / 100}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _l10n.selectRechargeAmount,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: rechargeAmounts.map((amount) {
                  final isSelected = selectedAmount == amount;
                  return ChoiceChip(
                    label: Text('¥$amount'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => selectedAmount = amount),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                _l10n.orEnterCustomAmount,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '¥',
                  hintText: _l10n.pleaseEnterAmount,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  final amount = int.tryParse(value);
                  if (amount != null) {
                    setState(() => selectedAmount = amount);
                  }
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _recharge(selectedAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('${_l10n.rechargeNow} ¥$selectedAmount'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(PlanModel plan, {required bool isSubscription}) {
    final isRecommended = plan.isRecommended;
    final hasFeatures = plan.features.isNotEmpty;
    final hasTokenQuota = plan.hasTokenQuota;
    final hasDefaultConfigs = plan.defaultConfigs.isNotEmpty;
    final hasApiPolicies = plan.apiPolicies.isNotEmpty;
    final hasAllowedModels = plan.allowedModels.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? AppColors.primary : AppColors.divider,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                _l10n.recommended,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 套餐名 + 类型徽章
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: plan.type == 'recharge'
                            ? Colors.orange.shade50
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        plan.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: plan.type == 'recharge'
                              ? Colors.orange.shade700
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // 价格 + 有效期
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${plan.priceYuan}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        ' / ${plan.durationLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Token 配额
                if (hasTokenQuota) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.token_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Token 配额：${_formatTokenCount(plan.tokenQuota!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 特性卖点（云端录入，Store 卡片展示）
                if (hasFeatures) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...plan.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // 功能默认 API（5 个）
                if (hasDefaultConfigs) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '功能默认模型',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...plan.defaultConfigs.entries
                      .where((e) => e.value.isNotEmpty)
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _getFunctionIcon(e.key),
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_functionLabel(e.key)}：',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],

                // 允许的 API + 系数（>1 用 warning 颜色）
                if (hasApiPolicies) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '可用 API（含系数）',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...plan.apiPolicies.map((p) {
                    final multiplier = p.multiplier;
                    final isHighCost = multiplier > 1.0;
                    final isAllowed = p.isAllowed;
                    final color = !isAllowed
                        ? Colors.grey
                        : isHighCost
                            ? Colors.orange.shade700
                            : AppColors.primary;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            isAllowed ? Icons.check_circle : Icons.block,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.model,
                              style: TextStyle(
                                fontSize: 12,
                                color: isAllowed ? AppColors.textPrimary : Colors.grey,
                                decoration: isAllowed
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              isAllowed ? '${multiplier.toStringAsFixed(multiplier == multiplier.truncate() ? 0 : 2)}x' : '禁用',
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else if (hasAllowedModels) ...[
                  // 兼容老数据：只返回 allowedModels，没有 apiPolicies
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '可用模型',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: plan.allowedModels.map((model) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          model,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _purchase(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRecommended ? AppColors.primary : AppColors.surfaceVariant,
                      foregroundColor:
                          isRecommended ? Colors.white : AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _l10n.buyNow,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化 token 数为可读形式（100000 → 10万）
  String _formatTokenCount(int count) {
    if (count >= 10000) {
      final v = count / 10000;
      return '${v.toStringAsFixed(v == v.truncate() ? 0 : 1)}万';
    }
    return count.toString();
  }

  /// 功能类型显示文案
  String _functionLabel(String key) {
    switch (key) {
      case 'textAnalysis':
        return '文本分析';
      case 'speechTranscribe':
        return '音频转写';
      case 'speechRealtime':
        return '实时转写';
      case 'speechOffline':
        return '离线转写';
      case 'imageRecognition':
        return '图像识别';
      default:
        return key;
    }
  }

  /// 功能类型图标
  IconData _getFunctionIcon(String key) {
    switch (key) {
      case 'textAnalysis':
        return Icons.text_fields;
      case 'speechTranscribe':
        return Icons.mic_none;
      case 'speechRealtime':
        return Icons.record_voice_over;
      case 'speechOffline':
        return Icons.audio_file;
      case 'imageRecognition':
        return Icons.image;
      default:
        return Icons.bolt;
    }
  }

  void _purchase(PlanModel plan) {
    final balance = ref.read(userBalanceProvider).value ?? 0;
    if (balance >= plan.priceCents) {
      _showBalancePaymentDialog(plan);
    } else {
      _showPaymentDialog(plan);
    }
  }

  void _recharge(int amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.confirmRecharge),
        content: Text('${_l10n.confirmRecharge} ¥$amount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showBalancePaymentDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.confirmPurchase),
        content: Text('${_l10n.useBalance} ${plan.name}?'),
        actions: [
          TextButton(
            onPressed: () => _showPaymentDialog(plan),
            child: Text(_l10n.otherPaymentMethods),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_l10n.useBalance),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.confirmPurchase),
        content: Text('${_l10n.confirmPurchase} ${plan.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_l10n.confirm),
          ),
        ],
      ),
    );
  }
}
