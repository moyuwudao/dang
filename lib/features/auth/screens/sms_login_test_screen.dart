import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloud_api_service.dart';

class SmsLoginTestScreen extends ConsumerStatefulWidget {
  const SmsLoginTestScreen({super.key});

  @override
  ConsumerState<SmsLoginTestScreen> createState() => _SmsLoginTestScreenState();
}

class _SmsLoginTestScreenState extends ConsumerState<SmsLoginTestScreen> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingSms = false;
  int _countdown = 0;

  bool _needCaptcha = false;
  String? _captchaUrl;

  String? _result;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) return '手机号格式不正确';
    return null;
  }

  String? _validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < 8) return '密码至少8位';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return '需包含大写字母';
    if (!RegExp(r'[a-z]').hasMatch(value)) return '需包含小写字母';
    if (!RegExp(r'[0-9]').hasMatch(value)) return '需包含数字';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return '需包含特殊字符';
    return null;
  }

  Future<void> _getCaptcha() async {
    try {
      final response = await CloudApiService.instance.get('/auth/captcha');
      final data = response.data['data'];
      setState(() {
        _captchaUrl = data['captchaUrl'] as String?;
        _needCaptcha = true;
      });
    } catch (e) {
      setState(() => _result = '获取验证码失败: $e');
    }
  }

  Future<void> _sendSmsCode() async {
    final phone = _phoneController.text.trim();
    if (_validatePhone(phone) != null) {
      setState(() => _result = '请输入正确的手机号');
      return;
    }

    if (_needCaptcha && _captchaController.text.isEmpty) {
      setState(() => _result = '请输入图片验证码');
      return;
    }

    setState(() => _isSendingSms = true);

    try {
      final response = await CloudApiService.instance.post('/auth/send-sms-code', data: {
        'phone': phone,
        if (_captchaController.text.isNotEmpty) 'captcha': _captchaController.text,
      });

      final data = response.data['data'];
      if (data['needCaptcha'] == true) {
        setState(() => _needCaptcha = true);
        await _getCaptcha();
        setState(() => _result = '请先完成人机验证');
        return;
      }

      setState(() {
        _countdown = 60;
        _result = '验证码已发送到 $phone';
      });
      _startCountdown();
    } catch (e) {
      setState(() => _result = '发送失败: $e');
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

  Future<void> _smsLogin() async {
    final phone = _phoneController.text.trim();
    final smsCode = _smsCodeController.text.trim();

    if (_validatePhone(phone) != null) {
      setState(() => _result = '请输入正确的手机号');
      return;
    }
    if (smsCode.length != 6) {
      setState(() => _result = '请输入6位验证码');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await CloudApiService.instance.post('/auth/sms-login', data: {
        'phone': phone,
        'smsCode': smsCode,
      });

      final data = response.data['data'];
      final token = data['accessToken'] as String;
      await CloudApiService.instance.setToken(token);

      setState(() => _result = '登录成功！\nToken: ${token.substring(0, 20)}...');
    } catch (e) {
      setState(() => _result = '登录失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('短信登录测试')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '短信验证码登录测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '测试强密码验证 + 人机验证 + 短信登录',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 手机号
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '手机号',
                hintText: '请输入11位手机号',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // 人机验证
            if (_needCaptcha) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _captchaController,
                      decoration: InputDecoration(
                        labelText: '图片验证码',
                        prefixIcon: const Icon(Icons.security),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

            // 短信验证码
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _smsCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: '短信验证码',
                      hintText: '6位数字',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_countdown > 0 || _isSendingSms) ? null : _sendSmsCode,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_countdown > 0 ? '$_countdown秒' : '获取验证码'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 登录按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _smsLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('短信登录'),
              ),
            ),
            const SizedBox(height: 24),

            // 结果显示
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!.contains('成功') ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _result!.contains('成功') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    color: _result!.contains('成功') ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 密码强度测试
            const Text(
              '密码强度测试',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '密码要求：8位以上，包含大小写字母、数字和特殊字符',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '测试密码',
                hintText: '例如: Abc123!@#',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                final error = _validateStrongPassword(value);
                setState(() {
                  _result = error ?? '密码强度符合要求 ✅';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
