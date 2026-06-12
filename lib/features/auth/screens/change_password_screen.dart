import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/cloud_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _smsCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingSms = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 8) {
      return '密码至少8位';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '需包含大写字母';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '需包含小写字母';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '需包含数字';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '需包含特殊字符';
    }
    return null;
  }

  Future<void> _sendSmsCode() async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final phone = authState?.user?.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未获取到手机号'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSendingSms = true);

    try {
      await ref.read(authNotifierProvider.notifier).sendSmsCode(phone: phone);

      setState(() => _countdown = 60);
      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      AppLogger().e('ChangePassword', '发送验证码失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSendingSms = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的新密码不一致'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_smsCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入短信验证码'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authNotifierProvider).valueOrNull;
      final phone = authState?.user?.phone;
      final hasPassword = authState?.user?.hasPassword ?? false;

      final data = <String, dynamic>{
        'phone': phone,
        'newPassword': _newPasswordController.text,
        'smsCode': _smsCodeController.text,
      };

      // 有密码的用户需要提供旧密码
      if (hasPassword) {
        data['oldPassword'] = _oldPasswordController.text;
      }

      await CloudApiService.instance.post('/auth/change-password', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码修改成功'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger().e('ChangePassword', '修改密码失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final phone = authState?.user?.phone ?? '';
    final hasPassword = authState?.user?.hasPassword ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密码'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '手机号: $phone',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 旧密码（仅当用户有密码时显示）
              if (hasPassword) ...[
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: '旧密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOldPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入旧密码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 新密码
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: '新密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // 确认新密码
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '确认新密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请确认新密码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 短信验证码
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '短信验证码',
                        prefixIcon: const Icon(Icons.message),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入验证码';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _countdown > 0 || _isSendingSms ? null : _sendSmsCode,
                      child: Text(_countdown > 0 ? '$_countdown秒' : '获取验证码'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('修改密码', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}