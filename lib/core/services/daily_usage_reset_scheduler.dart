import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/daily_usage_provider.dart';
import '../../features/settings/providers/health_check_provider.dart';
import '../../features/settings/providers/multi_api_pools_provider.dart';
import 'app_logger.dart';

/// ============================================================================
/// DailyUsageResetScheduler（A2 阶段新增）
///
/// 定时任务：
///   1. 隔天 0 点触发：归档今日用量到历史，重置 dailyUsage，清空 throttle
///   2. 每 5 分钟检查一次：清理过期的 throttle 状态
///   3. App 启动时立即检查：如果上次运行跨过了 0 点，立即补做一次重置
///
/// 实现：
///   - 使用 Timer.periodic + 计算距离下一个午夜的 Duration
///   - App 启动时通过 Provider 注入
/// ============================================================================
class DailyUsageResetScheduler {
  final Ref _ref;
  Timer? _midnightTimer;
  Timer? _cleanupTimer;
  bool _isRunning = false;

  DailyUsageResetScheduler(this._ref);

  /// 启动调度器
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    AppLogger().i('DailyUsageResetScheduler', '定时任务启动');

    // 1. App 启动时立即检查是否需要补做重置
    _checkAndResetOnStartup();

    // 2. 启动隔天 0 点调度
    _scheduleMidnightReset();

    // 3. 启动 5 分钟一次的清理任务
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredThrottles(),
    );
  }

  /// 停止调度器
  void stop() {
    _isRunning = false;
    _midnightTimer?.cancel();
    _midnightTimer = null;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    AppLogger().i('DailyUsageResetScheduler', '定时任务停止');
  }

  /// App 启动时检查：如果上次重置时间在今天之前，立即重置
  Future<void> _checkAndResetOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetStr = prefs.getString('last_daily_reset');
      final lastReset =
          lastResetStr != null ? DateTime.tryParse(lastResetStr) : null;
      final today = _todayDate();

      if (lastReset == null || lastReset.isBefore(today)) {
        AppLogger().i('DailyUsageResetScheduler',
            '启动时检测到需要重置 (lastReset=$lastReset, today=$today)');
        await performReset();
      } else {
        AppLogger().d('DailyUsageResetScheduler',
            '启动时无需重置 (lastReset=$lastReset)');
      }
    } catch (e) {
      AppLogger().w('DailyUsageResetScheduler', '启动检查失败: $e');
    }
  }

  /// 调度下一个 0 点的 reset
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final duration = _timeUntilNextMidnight();
    AppLogger().i('DailyUsageResetScheduler',
        '下一次 reset 在 ${duration.inHours} 小时 ${duration.inMinutes % 60} 分钟后');

    _midnightTimer = Timer(duration, () async {
      await performReset();
      // 递归调度下一次
      _scheduleMidnightReset();
    });
  }

  /// 执行重置
  Future<void> performReset() async {
    AppLogger().i('DailyUsageResetScheduler', '执行每日 reset...');
    try {
      // 1. 归档 + 重置用量
      final pools = _ref.read(multiApiPoolsProvider).pools;
      await _ref.read(dailyUsageProvider.notifier).snapshotAndReset(pools);

      // 2. 重置 multi_api_pools 中的 dailyUsage
      _ref.read(multiApiPoolsProvider.notifier).resetDailyUsage();

      // 3. 清理所有 throttle（隔天 0 点后，所有日配额 throttle 必然到期）
      _ref.read(healthCheckProvider.notifier).clear();

      // 4. 记录重置时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_daily_reset', DateTime.now().toIso8601String());

      AppLogger().i('DailyUsageResetScheduler', '每日 reset 完成');
    } catch (e) {
      AppLogger().e('DailyUsageResetScheduler', 'reset 失败: $e');
    }
  }

  /// 清理过期的 throttle 状态
  void _cleanupExpiredThrottles() {
    final health = _ref.read(healthCheckProvider);
    if (health.throttles.isEmpty) return;
    int cleaned = 0;
    for (final entry in health.throttles.entries) {
      if (!entry.value.isActive) {
        _ref.read(healthCheckProvider.notifier).clearThrottle(entry.key);
        cleaned++;
      }
    }
    if (cleaned > 0) {
      AppLogger().d('DailyUsageResetScheduler', '清理了 $cleaned 个过期 throttle');
    }
  }

  /// 计算今日 0 点
  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 计算距离下一个 0 点的时长
  Duration _timeUntilNextMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }
}

/// ============================================================================
/// Provider 声明
/// ============================================================================
final dailyUsageResetSchedulerProvider =
    Provider<DailyUsageResetScheduler>((ref) {
  final scheduler = DailyUsageResetScheduler(ref);
  ref.onDispose(() {
    scheduler.stop();
  });
  return scheduler;
});

/// 自动启动的 Provider（监听 App 生命周期）
final autoStartSchedulerProvider = Provider<void>((ref) {
  // 在 Provider 第一次被读取时启动
  // 通过 ref.listen 确保只启动一次
  final scheduler = ref.read(dailyUsageResetSchedulerProvider);
  scheduler.start();
});
