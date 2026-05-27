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
                style: TextStyle(
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
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${plan.priceCents / 100}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSubscription ? '/月' : '/${plan.durationDays}天',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(feature),
                        ],
                      ),
                    )),
                // 可用模型
                if (plan.allowedModels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '可用模型',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plan.allowedModels.map((model) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          model,
                          style: TextStyle(
                            fontSize: 12,
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
                  height: 50,
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
                      style: TextStyle(fontSize: 16),
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
