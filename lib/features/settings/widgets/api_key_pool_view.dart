import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_key_pool.dart';
import '../../../core/models/health_check_result.dart';
import '../../../core/models/throttle_scope.dart';
import '../../../core/services/health_check_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/daily_usage_provider.dart';
import '../providers/health_check_provider.dart';
import '../providers/multi_api_pools_provider.dart';
import 'fallback_settings.dart';
import 'health_check_tab.dart';
import 'throttle_badge.dart';
import 'usage_tab.dart';

/// ============================================================================
/// ApiKeyPoolView — API Key 池化视图
///
/// A1 阶段：基础 Key 池管理
/// A2 阶段新增：
///   - Tab 切换：池 / 用量 / 健康
///   - 限流状态徽标
///   - 降级与轮询设置
///   - 一键"全部检查"按钮
/// ============================================================================
class ApiKeyPoolView extends ConsumerStatefulWidget {
  const ApiKeyPoolView({super.key});

  @override
  ConsumerState<ApiKeyPoolView> createState() => _ApiKeyPoolViewState();
}

class _ApiKeyPoolViewState extends ConsumerState<ApiKeyPoolView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 首次加载
    Future.microtask(() async {
      await ref.read(multiApiPoolsProvider.notifier).load();
      await ref.read(dailyUsageProvider.notifier).load();
      await ref.read(healthCheckProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined), text: '池'),
              Tab(icon: Icon(Icons.show_chart), text: '用量'),
              Tab(icon: Icon(Icons.health_and_safety), text: '健康'),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _PoolListTab(),
              UsageTab(),
              HealthCheckTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Tab 1: 池列表
// ============================================================================
class _PoolListTab extends ConsumerStatefulWidget {
  const _PoolListTab();

  @override
  ConsumerState<_PoolListTab> createState() => _PoolListTabState();
}

class _PoolListTabState extends ConsumerState<_PoolListTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiApiPoolsProvider);
    final notifier = ref.read(multiApiPoolsProvider.notifier);
    final healthState = ref.watch(healthCheckProvider);
    final throttleCount = healthState.activeThrottles.length;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 概览 + 限流提示
        _OverviewCard(
          totalKeys: state.totalKeys,
          activeKeys: state.activeKeys,
          totalUsage: state.totalDailyUsage,
          totalQuota: state.totalDailyQuota,
          throttleCount: throttleCount,
        ),
        const SizedBox(height: 12),

        // 降级设置
        const FallbackSettings(),
        const SizedBox(height: 12),

        if (state.pools.isEmpty)
          _EmptyState(onAdd: () => _showAddPoolDialog(context, notifier))
        else ...[
          ...state.pools.map((pool) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PoolCard(
                  pool: pool,
                  onAddKey: () => _showAddKeyDialog(context, notifier, pool),
                  onEditKey: (key) =>
                      _showEditKeyDialog(context, notifier, pool, key),
                  onDeleteKey: (key) =>
                      _confirmDeleteKey(context, notifier, pool, key),
                  onResetKey: (key) =>
                      notifier.resetKeyErrors(pool.id, key.id),
                  onTestKey: (key) => _testKey(pool, key),
                ),
              )),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('添加 Provider 池'),
              onPressed: () => _showAddPoolDialog(context, notifier),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================================
  // 对话框 / 操作（与 A1 阶段一致）
  // ============================================================================

  void _showAddPoolDialog(BuildContext context, MultiApiPoolsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => _AddPoolDialog(onAdd: (pool) async {
        await notifier.addPool(pool);
      }),
    );
  }

  void _showAddKeyDialog(
    BuildContext context,
    MultiApiPoolsNotifier notifier,
    ApiKeyPool pool,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AddKeyDialog(
        pool: pool,
        onAdd: (key) async {
          await notifier.addKeyToPool(pool.id, key);
        },
      ),
    );
  }

  void _showEditKeyDialog(
    BuildContext context,
    MultiApiPoolsNotifier notifier,
    ApiKeyPool pool,
    ApiKeyEntry key,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AddKeyDialog(
        pool: pool,
        existing: key,
        onAdd: (newKey) async {
          await notifier.updateKey(newKey);
        },
      ),
    );
  }

  Future<void> _confirmDeleteKey(
    BuildContext context,
    MultiApiPoolsNotifier notifier,
    ApiKeyPool pool,
    ApiKeyEntry key,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除 Key'),
        content: Text('确定要删除 ${pool.displayName} 中的 "${key.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await notifier.removeKey(pool.id, key.id);
    }
  }

  Future<void> _testKey(ApiKeyPool pool, ApiKeyEntry key) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('正在测试 ${pool.displayName} / ${key.name}...')),
    );
    ref.read(healthCheckProvider.notifier).setChecking(key.id, true);
    try {
      final service = ref.read(healthCheckServiceProvider);
      final result = await service.checkKey(key: key, pool: pool);
      ref.read(healthCheckProvider.notifier).updateResult(result);
      if (result.status == HealthStatus.throttled) {
        ref.read(healthCheckProvider.notifier).setThrottle(
              keyId: key.id,
              isThrottled: true,
              scope: ThrottleScope.unknown,
              until: null,
              message: result.errorMessage,
            );
      } else {
        ref.read(healthCheckProvider.notifier).clearThrottle(key.id);
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                '${key.name}: ${result.status.label} (${result.responseTimeMs}ms)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('测试失败: $e')),
        );
      }
    } finally {
      ref.read(healthCheckProvider.notifier).setChecking(key.id, false);
    }
  }
}

// ============================================================================
// 概览卡片（A2 增强：增加限流提示）
// ============================================================================
class _OverviewCard extends StatelessWidget {
  final int totalKeys;
  final int activeKeys;
  final int totalUsage;
  final int totalQuota;
  final int throttleCount;

  const _OverviewCard({
    required this.totalKeys,
    required this.activeKeys,
    required this.totalUsage,
    required this.totalQuota,
    required this.throttleCount,
  });

  @override
  Widget build(BuildContext context) {
    final usageRatio = totalQuota > 0 ? (totalUsage / totalQuota) : 0.0;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.dashboard_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('API Key 池总览',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Metric(value: '$totalKeys', label: '总 Key 数'),
                _Metric(
                  value: '$activeKeys',
                  label: '活跃',
                  color: Colors.green,
                ),
                _Metric(
                  value: '${totalKeys - activeKeys}',
                  label: '异常',
                  color: Colors.orange,
                ),
                if (throttleCount > 0)
                  _Metric(
                    value: '$throttleCount',
                    label: '限流',
                    color: Colors.deepOrange,
                  ),
              ],
            ),
            if (totalQuota > 0) ...[
              const SizedBox(height: 12),
              Text('今日用量: $totalUsage / $totalQuota',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: usageRatio.clamp(0.0, 1.0),
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(
                  usageRatio > 0.8 ? Colors.orange : AppColors.primary,
                ),
              ),
            ],
            if (throttleCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$throttleCount 个 Key 正在限流，已自动从调用候选中排除',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _Metric({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ============================================================================
// 池卡片（A2 增强：Key 行增加限流徽标）
// ============================================================================
class _PoolCard extends StatefulWidget {
  final ApiKeyPool pool;
  final VoidCallback onAddKey;
  final void Function(ApiKeyEntry key) onEditKey;
  final void Function(ApiKeyEntry key) onDeleteKey;
  final void Function(ApiKeyEntry key) onResetKey;
  final void Function(ApiKeyEntry key) onTestKey;

  const _PoolCard({
    required this.pool,
    required this.onAddKey,
    required this.onEditKey,
    required this.onDeleteKey,
    required this.onResetKey,
    required this.onTestKey,
  });

  @override
  State<_PoolCard> createState() => _PoolCardState();
}

class _PoolCardState extends State<_PoolCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final pool = widget.pool;
    return Card(
      elevation: 1,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_queue,
                    color: pool.isEnabled ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pool.displayName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('共 ${pool.keys.length} 个 Key · 活跃 ${pool.availableKeys.length}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  _PoolHealthBadge(score: pool.poolHealth),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...pool.keys.map((key) => _KeyRow(
                  keyEntry: key,
                  onEdit: () => widget.onEditKey(key),
                  onDelete: () => widget.onDeleteKey(key),
                  onReset: () => widget.onResetKey(key),
                  onTest: () => widget.onTestKey(key),
                )),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加 Key'),
                onPressed: widget.onAddKey,
              ),
            ),
        ],
      ),
    );
  }
}

class _PoolHealthBadge extends StatelessWidget {
  final double score;
  const _PoolHealthBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('${score.toStringAsFixed(0)}分',
          style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

// ============================================================================
// Key 行（A2 增强：限流徽标）
// ============================================================================
class _KeyRow extends StatelessWidget {
  final ApiKeyEntry keyEntry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final VoidCallback onTest;

  const _KeyRow({
    required this.keyEntry,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final key = keyEntry;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 健康状态点
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: key.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(key.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        Text(key.maskedKey,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 6),
                        // A2: 限流徽标
                        ThrottleBadge(keyId: key.id, dense: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(key.statusLabel,
                        style: TextStyle(
                            fontSize: 11, color: key.statusColor)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'test':
                      onTest();
                      break;
                    case 'reset':
                      onReset();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  const PopupMenuItem(value: 'test', child: Text('测试连接')),
                  if (key.status == ApiKeyStatus.throttled)
                    const PopupMenuItem(value: 'reset', child: Text('重置错误')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          if (key.dailyQuota > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: key.usageRatio,
                    minHeight: 4,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      key.usageRatio > 0.8
                          ? Colors.orange
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${key.dailyUsage}/${key.dailyQuota}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
          if (key.lastError != null) ...[
            const SizedBox(height: 4),
            Text('最后错误: ${key.lastError}',
                style: const TextStyle(fontSize: 10, color: Colors.red),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 添加池对话框
// ============================================================================
class _AddPoolDialog extends StatefulWidget {
  final Future<void> Function(ApiKeyPool) onAdd;
  const _AddPoolDialog({required this.onAdd});

  @override
  State<_AddPoolDialog> createState() => _AddPoolDialogState();
}

class _AddPoolDialogState extends State<_AddPoolDialog> {
  AiProvider? _selectedProvider;
  final _modelController = TextEditingController();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _modelController.dispose();
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加 Provider 池'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<AiProvider>(
              initialValue: _selectedProvider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: AiProvider.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(AiModelConfig.getConfig(p).displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedProvider = v;
                  if (v != null && _modelController.text.isEmpty) {
                    _modelController.text =
                        AiModelConfig.getConfig(v).defaultModel;
                  }
                });
              },
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '池名称（可选）'),
            ),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: '默认 Model'),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: '首个 API Key（必填）'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedProvider == null || _apiKeyController.text.isEmpty
              ? null
              : () async {
                  final now = DateTime.now();
                  final key = ApiKeyEntry(
                    id: 'key_${now.millisecondsSinceEpoch}',
                    name: '主 Key',
                    apiKey: _apiKeyController.text.trim(),
                    createdAt: now,
                    updatedAt: now,
                  );
                  final pool = ApiKeyPool(
                    id:
                        'pool_${_selectedProvider!.name}_${now.millisecondsSinceEpoch}',
                    provider: _selectedProvider!,
                    model: _modelController.text.trim(),
                    name: _nameController.text.trim().isEmpty
                        ? null
                        : _nameController.text.trim(),
                    keys: [key],
                    createdAt: now,
                    updatedAt: now,
                  );
                  await widget.onAdd(pool);
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('创建'),
        ),
      ],
    );
  }
}

// ============================================================================
// 添加 / 编辑 Key 对话框
// ============================================================================
class _AddKeyDialog extends StatefulWidget {
  final ApiKeyPool pool;
  final ApiKeyEntry? existing;
  final Future<void> Function(ApiKeyEntry) onAdd;

  const _AddKeyDialog({
    required this.pool,
    required this.onAdd,
    this.existing,
  });

  @override
  State<_AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends State<_AddKeyDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _appIdController;
  late final TextEditingController _accessKeyController;
  late final TextEditingController _dailyQuotaController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '备用 Key');
    _apiKeyController =
        TextEditingController(text: widget.existing?.apiKey ?? '');
    _appIdController =
        TextEditingController(text: widget.existing?.appId ?? '');
    _accessKeyController =
        TextEditingController(text: widget.existing?.accessKeySecret ?? '');
    _dailyQuotaController = TextEditingController(
        text: widget.existing?.dailyQuota.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _appIdController.dispose();
    _accessKeyController.dispose();
    _dailyQuotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '添加 Key' : '编辑 Key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: widget.existing != null,
            ),
            if (widget.pool.provider == AiProvider.qwen) ...[
              TextField(
                controller: _appIdController,
                decoration: const InputDecoration(labelText: 'App ID'),
              ),
              TextField(
                controller: _accessKeyController,
                decoration: const InputDecoration(labelText: 'AccessKey Secret'),
                obscureText: true,
              ),
            ],
            TextField(
              controller: _dailyQuotaController,
              decoration: const InputDecoration(
                  labelText: '每日 Token 配额 (0=无限制)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_apiKeyController.text.trim().isEmpty) return;
            final now = DateTime.now();
            final dailyQuota =
                int.tryParse(_dailyQuotaController.text.trim()) ?? 0;
            final newKey = (widget.existing ?? ApiKeyEntry(
              id: 'key_${now.millisecondsSinceEpoch}',
              name: _nameController.text.trim(),
              apiKey: '',
              createdAt: now,
              updatedAt: now,
            ))
                .copyWith(
              name: _nameController.text.trim(),
              apiKey: _apiKeyController.text.trim(),
              appId: _appIdController.text.trim().isEmpty
                  ? null
                  : _appIdController.text.trim(),
              accessKeySecret: _accessKeyController.text.trim().isEmpty
                  ? null
                  : _accessKeyController.text.trim(),
              dailyQuota: dailyQuota,
              updatedAt: now,
            );
            await widget.onAdd(newKey);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// ============================================================================
// 空状态
// ============================================================================
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('还没有配置 API Key 池',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('添加你的第一个 Provider 池开始使用',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加 Provider 池'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
