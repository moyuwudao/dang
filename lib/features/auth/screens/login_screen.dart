import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSmsLogin = true;

  // 验证码相关
  bool _needCaptcha = false;
  String? _captchaUrl;
  String? _captchaId;

  // 短信验证码倒计时
  int _countdown = 0;
  bool _isSendingSms = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _smsCodeController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  // 强密码验证
  String? _validateStrongPassword(String? value) {
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

  // 手机号验证
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
      return '手机号格式不正确';
    }
    return null;
  }

  // 获取验证码
  Future<void> _getCaptcha() async {
    AppLogger().i('Login', '点击获取图片验证码');
    try {
      final data = await ref.read(authNotifierProvider.notifier).refreshCaptcha();
      setState(() {
        _captchaUrl = data['captchaUrl'] as String?;
        _captchaId = data['captchaId'] as String?;
        _needCaptcha = true;
      });
      AppLogger().i('Login', '图片验证码获取成功');
    } catch (e) {
      AppLogger().e('Login', '获取图片验证码失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取验证码失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // 发送短信验证码
  Future<void> _sendSmsCode() async {
    final phone = _phoneController.text.trim();
    AppLogger().i('Login', '点击发送短信验证码: phone=$phone');
    if (_validatePhone(phone) != null) {
      AppLogger().w('Login', '手机号格式不正确');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号'), backgroundColor: AppColors.error),
      );
      return;
    }

    // 如果需要人机验证，先校验
    if (_needCaptcha && _captchaController.text.isEmpty) {
      AppLogger().w('Login', '需要图片验证码但未输入');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入图片验证码'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSendingSms = true);

    try {
      final data = await ref.read(authNotifierProvider.notifier).sendSmsCode(
        phone: phone,
        captcha: _captchaController.text.isNotEmpty ? _captchaController.text : null,
      );

      // 检查是否需要人机验证
      if (data['needCaptcha'] == true) {
        AppLogger().w('Login', '服务器要求人机验证');
        setState(() => _needCaptcha = true);
        await _getCaptcha();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先完成人机验证'), backgroundColor: AppColors.warning),
        );
        return;
      }

      // 开始倒计时
      setState(() => _countdown = 60);
      _startCountdown();
      AppLogger().i('Login', '短信验证码发送成功');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      AppLogger().e('Login', '发送短信验证码失败: $e');
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

  // 登录
  Future<void> _login() async {
    AppLogger().i('Login', '点击登录按钮');
    if (!_formKey.currentState!.validate()) {
      AppLogger().w('Login', '表单验证失败');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      AppLogger().i('Login', '开始登录: phone=$phone, isSmsLogin=$_isSmsLogin');

      if (_isSmsLogin) {
        // 短信验证码登录
        await ref.read(authNotifierProvider.notifier).smsLogin(
          phone: phone,
          smsCode: _smsCodeController.text.trim(),
        );
      } else {
        // 密码登录
        await ref.read(authNotifierProvider.notifier).login(
          phone: phone,
          password: _passwordController.text,
        );
      }

      AppLogger().i('Login', '登录流程完成');
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      AppLogger().e('Login', '登录异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcomeBack,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSubtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // 登录方式切换
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSmsLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isSmsLogin ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '验证码登录',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isSmsLogin ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSmsLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isSmsLogin ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '密码登录',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isSmsLogin ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 手机号输入
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入11位手机号',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),

              // 人机验证（图片验证码）
              if (_needCaptcha) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _captchaController,
                        decoration: InputDecoration(
                          labelText: '图片验证码',
                          hintText: '请输入验证码',
                          prefixIcon: const Icon(Icons.security_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入图片验证码';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _getCaptcha,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _captchaUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(_captchaUrl!.split(',')[1]),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(child: Icon(Icons.refresh)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 短信验证码登录
              if (_isSmsLogin) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _smsCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: '短信验证码',
                          hintText: '请输入6位验证码',
                          prefixIcon: const Icon(Icons.message_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入验证码';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                            return '验证码为6位数字';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_countdown > 0 || _isSendingSms)
                              ? null
                              : _sendSmsCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _countdown > 0 ? '$_countdown秒' : '获取验证码',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 密码登录
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validateStrongPassword,
                ),
                const SizedBox(height: 8),
                // 密码要求提示
                const Text(
                  '密码要求：8位以上，包含大小写字母、数字和特殊字符',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(l10n.login),
                ),
              ),
              const SizedBox(height: 16),

              // 注册入口
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.noAccount),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(l10n.registerNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
