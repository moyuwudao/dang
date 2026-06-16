import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingSms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;

  // 验证码相关
  bool _needCaptcha = false;
  bool _captchaVerified = false;  // 图片验证码是否已验证通过
  String? _captchaUrl;
  String? _captchaId;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  // 获取图片验证码
  Future<void> _getCaptcha() async {
    try {
      final data = await ref.read(authNotifierProvider.notifier).refreshCaptcha();
      setState(() {
        _captchaUrl = data['captchaUrl'] as String?;
        _captchaId = data['captchaId'] as String?;
        _needCaptcha = true;
        _captchaVerified = false;  // 刷新验证码后重置验证状态
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取验证码失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // 发送短信验证码（弹窗验证图片验证码后自动发送）
  Future<void> _sendSmsCode() async {
    final phone = _phoneController.text.trim();
    if (_validatePhone(phone) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号'), backgroundColor: AppColors.error),
      );
      return;
    }

    // 如果已验证过图片验证码，直接发送
    if (_captchaVerified) {
      await _doSendSmsCode(phone);
      return;
    }

    // 未验证，弹出图片验证码弹窗
    await _showCaptchaDialog(phone);
  }

  // 显示图片验证码弹窗
  Future<void> _showCaptchaDialog(String phone) async {
    // 先获取验证码
    await _getCaptcha();

    if (!mounted) return;

    final captchaInputController = TextEditingController();
    bool isVerifying = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('安全验证'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('请输入图片中的验证码'),
                  const SizedBox(height: 16),
                  // 图片验证码
                  GestureDetector(
                    onTap: () async {
                      await _getCaptcha();
                      setDialogState(() {});
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _captchaUrl != null
                            ? SvgPicture.memory(
                                base64Decode(_captchaUrl!.split(',')[1]),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(Icons.refresh, color: AppColors.textSecondary),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 输入框
                  TextField(
                    controller: captchaInputController,
                    decoration: InputDecoration(
                      labelText: '验证码',
                      hintText: '请输入图片中的字符',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: errorText,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (captchaInputController.text.isEmpty) {
                            setDialogState(() => errorText = '请输入验证码');
                            return;
                          }

                          setDialogState(() {
                            isVerifying = true;
                            errorText = null;
                          });

                          try {
                            final response = await ref.read(authNotifierProvider.notifier).verifyCaptcha(
                              captchaId: _captchaId!,
                              captcha: captchaInputController.text,
                            );

                            final valid = response['valid'] as bool? ?? false;
                            if (valid) {
                              setState(() => _captchaVerified = true);
                              // 保存用户输入的验证码到 _captchaController
                              _captchaController.text = captchaInputController.text;
                              Navigator.of(dialogContext).pop();
                              // 验证成功，自动发送短信验证码
                              await _doSendSmsCode(phone);
                            } else {
                              // 验证码错误，只清空输入框，不刷新验证码，让用户重新输入
                              captchaInputController.clear();
                              setDialogState(() {
                                isVerifying = false;
                                errorText = '验证码错误，请重新输入';
                              });
                            }
                          } catch (e) {
                            // 验证失败（网络错误等），刷新验证码
                            captchaInputController.clear();
                            await _getCaptcha();
                            setDialogState(() {
                              isVerifying = false;
                              errorText = '验证失败: $e';
                            });
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('验证并发送'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 实际发送短信验证码
  Future<void> _doSendSmsCode(String phone) async {
    setState(() => _isSendingSms = true);

    try {
      final data = await ref.read(authNotifierProvider.notifier).sendSmsCode(
        phone: phone,
        captcha: _captchaController.text,
        captchaId: _captchaId,
      );

      // 开始倒计时
      setState(() => _countdown = 60);
      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        // 发送失败后重置验证状态
        setState(() => _captchaVerified = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSendingSms = false);
    }
  }

  // 验证图片验证码（保留用于兼容）
  Future<void> _verifyCaptcha() async {
    // 已移至弹窗内处理
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('两次密码不一致'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).register(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        smsCode: _smsCodeController.text.trim(),
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.registerFailed}: $e'),
            backgroundColor: AppColors.error,
          ),
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
        title: Text(l10n.register),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createAccount,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '创建新账号开始使用',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

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

              // 短信验证码
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
              const SizedBox(height: 16),

              // 密码输入
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入强密码',
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
              const SizedBox(height: 16),

              // 确认密码
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  hintText: '请再次输入密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请确认密码';
                  }
                  if (value != _passwordController.text) {
                    return '两次密码不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 注册按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
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
                      : Text(l10n.register),
                ),
              ),
              const SizedBox(height: 16),

              // 登录入口
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.hasAccount),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(l10n.loginNow),
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
