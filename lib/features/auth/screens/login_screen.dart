import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'change_password_screen.dart';

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
  bool _isSmsLogin = true;
  bool _isSendingSms = false;
  int _countdown = 0;

  String? _captchaUrl;
  String? _captchaId;
  bool _needCaptcha = true;
  bool _captchaVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCaptcha();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _smsCodeController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
      return '手机号格式不正确';
    }
    return null;
  }

  Future<void> _getCaptcha() async {
    AppLogger().i('Login', '请求验证码');
    try {
      final data = await ref.read(authNotifierProvider.notifier).refreshCaptcha();
      setState(() {
        _captchaUrl = data['captchaUrl'] as String?;
        _captchaId = data['captchaId'] as String?;
        _needCaptcha = true;
        _captchaVerified = false;
      });
      AppLogger().i('Login', '验证码获取成功: captchaId=$_captchaId');
    } catch (e) {
      AppLogger().e('Login', '获取验证码失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取验证码失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

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

    if (_captchaVerified) {
      await _doSendSmsCode(phone);
      return;
    }

    await _showCaptchaDialog(phone);
  }

  Future<void> _showCaptchaDialog(String phone) async {
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
                              _captchaController.text = captchaInputController.text;
                              Navigator.of(dialogContext).pop();
                              await _doSendSmsCode(phone);
                            } else {
                              captchaInputController.clear();
                              setDialogState(() {
                                isVerifying = false;
                                errorText = '验证码错误，请重新输入';
                              });
                            }
                          } catch (e) {
                            AppLogger().e('Login', '验证图片验证码失败: $e');
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

  Future<void> _doSendSmsCode(String phone) async {
    setState(() => _isSendingSms = true);

    try {
      final data = await ref.read(authNotifierProvider.notifier).sendSmsCode(
        phone: phone,
        captcha: _captchaController.text,
        captchaId: _captchaId,
      );

      setState(() => _countdown = 60);
      _startCountdown();
      AppLogger().i('Login', '短信验证码发送成功');

      final devCode = data['devCode'] as String?;
      if (mounted) {
        if (devCode != null && devCode.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('【开发模式】验证码: $devCode（SMS服务未配置）'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 10),
            ),
          );
          _smsCodeController.text = devCode;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('验证码已发送'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      AppLogger().e('Login', '发送短信验证码失败: $e');
      setState(() => _captchaVerified = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSendingSms = false);
    }
  }

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSmsLogin) {
        await ref.read(authNotifierProvider.notifier).smsLogin(
          phone: _phoneController.text.trim(),
          smsCode: _smsCodeController.text.trim(),
        );
      } else {
        await ref.read(authNotifierProvider.notifier).login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        AppLogger().i('Login', '登录成功，准备导航到首页');
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      AppLogger().e('Login', '登录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        authenticated: (user) {
          AppLogger().i('Login', '认证状态已更新，用户已登录: ${user.phone}');
        },
        error: (message) {
          AppLogger().e('Login', '认证错误: $message');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: AppColors.error),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 6) {
                      return '密码至少6位';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.login),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '还没有账号？',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: Text(l10n.register),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '忘记密码？',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('修改密码'),
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
