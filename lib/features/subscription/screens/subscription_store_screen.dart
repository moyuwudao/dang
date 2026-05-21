import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('购买套餐'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '按月订阅'),
            Tab(text: '套餐包'),
            Tab(text: '充值'),
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
                    const Text(
                      '账户余额',
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
              const Text(
                '选择充值金额',
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
              const Text(
                '或输入自定义金额',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '¥',
                  hintText: '请输入金额',
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
                  child: Text('立即充值 ¥$selectedAmount'),
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
              child: const Text(
                '推荐',
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
                    child: const Text(
                      '立即购买',
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
        title: const Text('确认充值'),
        content: Text('确认充值 ¥$amount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showBalancePaymentDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('使用余额购买 ${plan.name} 套餐?'),
        actions: [
          TextButton(
            onPressed: () => _showPaymentDialog(plan),
            child: const Text('其他支付方式'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('使用余额'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('确认购买 ${plan.name} 套餐?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
