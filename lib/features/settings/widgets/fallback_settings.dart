import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/health_check_provider.dart';

/// ============================================================================
/// 跨 Provider 降级开关（A2 阶段新增）
///
/// 控制：
///   1. 跨 Provider 降级（开关）
///   2. 限流时是否等待（开关）
///   3. 自动健康检查（开关 + 间隔）
/// ============================================================================
class FallbackSettings extends ConsumerStatefulWidget {
  const FallbackSettings({super.key});

  @override
  ConsumerState<FallbackSettings> createState() => _FallbackSettingsState();
}

class _FallbackSettingsState extends ConsumerState<FallbackSettings> {
  bool _crossProviderFallback = true;
  bool _waitOnThrottle = true;
  int _autoCheckIntervalMinutes = 5;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crossProviderFallback = prefs.getBool('fallback_cross_provider') ?? true;
      _waitOnThrottle = prefs.getBool('fallback_wait_throttle') ?? true;
      _autoCheckIntervalMinutes =
          prefs.getInt('health_check_interval_minutes') ?? 5;
      _loaded = true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthCheckProvider);
    final throttleCount = ref.watch(activeThrottleCountProvider);
    final needsFallback = ref.watch(needsCrossProviderFallbackProvider);

    if (!_loaded) {
      return const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.settings_input_component,
                    color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('降级与轮询设置',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('跨 Provider 降级',
                  style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                  '主 Provider 失败时自动切换到其他 Provider',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: _crossProviderFallback,
              onChanged: (v) {
                setState(() => _crossProviderFallback = v);
                _saveBool('fallback_cross_provider', v);
              },
              dense: true,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('限流时等待恢复',
                  style: TextStyle(fontSize: 13)),
              subtitle: const Text('不立即降级，等限流到期后再试',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: _waitOnThrottle,
              onChanged: (v) {
                setState(() => _waitOnThrottle = v);
                _saveBool('fallback_wait_throttle', v);
              },
              dense: true,
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('自动健康检查', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                healthState.enabled
                    ? '已启用，每 $_autoCheckIntervalMinutes 分钟'
                    : '已禁用',
                style: TextStyle(
                    fontSize: 11,
                    color: healthState.enabled ? Colors.green : Colors.grey),
              ),
              trailing: Switch(
                value: healthState.enabled,
                onChanged: (v) =>
                    ref.read(healthCheckProvider.notifier).setEnabled(v),
              ),
              dense: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Text('检查间隔:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _autoCheckIntervalMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_autoCheckIntervalMinutes 分钟',
                      onChanged: (v) {
                        setState(() => _autoCheckIntervalMinutes = v.toInt());
                        _saveInt('health_check_interval_minutes', v.toInt());
                      },
                    ),
                  ),
                  Text('${_autoCheckIntervalMinutes}m',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // 状态指示
            if (throttleCount > 0) ...[
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        needsFallback
                            ? '⚠️ 所有 Provider 的 Key 都不可用，已自动启用跨 Provider 降级'
                            : '$throttleCount 个 Key 正在限流中，将自动跳过',
                        style: const TextStyle(fontSize: 12),
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
