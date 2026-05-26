import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/aliyun_signer.dart';
import '../../../data/models/record_model.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/api_config_provider.dart';

class ApiKeyConfigScreen extends ConsumerStatefulWidget {
  const ApiKeyConfigScreen({super.key});

  @override
  ConsumerState<ApiKeyConfigScreen> createState() => _ApiKeyConfigScreenState();
}

class _ApiKeyConfigScreenState extends ConsumerState<ApiKeyConfigScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _appIdController = TextEditingController();
  final _accessKeySecretController = TextEditingController();
  bool _isLoading = false;
  bool _isTesting = false;
  String? _errorMessage;
  String? _successMessage;

  AiProvider _selectedProvider = AiProvider.openAI;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _appIdController.dispose();
    _accessKeySecretController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await StorageService.getApiConfig();
    if (config != null) {
      setState(() {
        _apiKeyController.text = config.apiKey;
        _baseUrlController.text = config.baseUrl ?? '';
        _modelController.text = config.model;
        _appIdController.text = config.appId ?? '';
        _accessKeySecretController.text = config.accessKeySecret ?? '';
        _selectedProvider = AiProvider.values.firstWhere(
          (p) => p.name == config.provider,
          orElse: () => AiProvider.openAI,
        );
      });
    }
  }

  Future<void> _saveConfig() async {
    final l10n = AppLocalizations.of(context)!;
    if (_apiKeyController.text.isEmpty) {
      setState(() => _errorMessage = l10n.apiKeyRequired);
      return;
    }

    if (_modelController.text.isEmpty) {
      setState(() => _errorMessage = l10n.modelNameRequired);
      return;
    }

    final config = ApiConfigModel(
      id: 1,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim().isEmpty
          ? null
          : _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      provider: _selectedProvider.name,
      appId: _appIdController.text.trim().isEmpty
          ? null
          : _appIdController.text.trim(),
      accessKeySecret: _accessKeySecretController.text.trim().isEmpty
          ? null
          : _accessKeySecretController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await StorageService.saveApiConfig(config);

    // 同步到运行时 - 使用 ApiService 单例
    final apiService = ApiService();
    final providerConfig = AiModelConfig.getConfig(_selectedProvider);
    apiService.configure(
      apiKey: config.apiKey,
      config: providerConfig,
      customBaseUrl: config.baseUrl,
      appId: config.appId,
      accessKeySecret: config.accessKeySecret,
    );

    setState(() {
      _successMessage = l10n.saveSuccess;
      _errorMessage = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _successMessage = null);
      }
    });
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    if (_apiKeyController.text.isEmpty) {
      setState(() => _errorMessage = l10n.apiKeyRequired);
      return;
    }

    setState(() {
      _isTesting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _baseUrlController.text.trim().isNotEmpty
              ? _baseUrlController.text.trim()
              : AiModelConfig.getConfig(_selectedProvider).baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (_selectedProvider != AiProvider.tingwu) {
        dio.options.headers['Authorization'] =
            'Bearer ${_apiKeyController.text}';
      }

      Response response;
      if (_selectedProvider == AiProvider.gemini) {
        response = await dio.get(
          '/models',
          queryParameters: {'key': _apiKeyController.text},
        );
      } else if (_selectedProvider == AiProvider.tingwu) {
        if (_accessKeySecretController.text.isEmpty) {
          throw Exception('通义听悟需要 AccessKey Secret 进行签名');
        }
        final signer = AliyunSigner(
          accessKeyId: _apiKeyController.text,
          accessKeySecret: _accessKeySecretController.text,
        );
        final path = '/openapi/tingwu/v2/tasks';
        final queryParams = {'type': 'offline'};
        final testBody = jsonEncode({
          'AppKey': _appIdController.text.isNotEmpty
              ? _appIdController.text
              : '',
          'Input': {
            'SourceLanguage': 'cn',
            'TaskKey': 'test_${DateTime.now().millisecondsSinceEpoch}',
          },
        });
        final signedHeaders = signer.signRoaRequest(
          method: 'PUT',
          path: path,
          queryParams: queryParams,
          body: testBody,
        );
        final baseUrl = _baseUrlController.text.trim().isNotEmpty
            ? _baseUrlController.text.trim()
            : 'https://tingwu.cn-beijing.aliyuncs.com';
        try {
          response = await dio.put(
            '$baseUrl$path',
            data: testBody,
            queryParameters: queryParams,
            options: Options(headers: signedHeaders),
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 400) {
            response = e.response!;
          } else {
            rethrow;
          }
        }
      } else {
        response = await dio.get('/models');
      }

      if (mounted) {
        final isSuccess = response.statusCode == 200 ||
            (_selectedProvider == AiProvider.tingwu &&
                response.statusCode == 400);
        setState(() {
          _isTesting = false;
          if (isSuccess) {
            _successMessage = l10n.connectionSuccessDetail;
          } else {
            _errorMessage =
                l10n.connectionFailedDetail(response.statusCode.toString());
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _errorMessage =
              '${l10n.connectionFailed}: ${e.message ?? e.error?.toString() ?? l10n.unknownError}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _errorMessage = '${l10n.testError}: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providerConfig = AiModelConfig.getConfig(_selectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localApiConfig),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveConfig,
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selection
            Text(l10n.selectProvider,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AiModelConfig.allProviders.map((config) {
                final isSelected = _selectedProvider == config.provider;
                return ChoiceChip(
                  label: Text(config.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedProvider = config.provider;
                        _modelController.text = config.defaultModel;
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // API Key
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: providerConfig.apiKeyPrefix != null
                    ? '${providerConfig.apiKeyPrefix}...'
                    : l10n.apiKeyHint,
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final clipboard = await Clipboard.getData('text/plain');
                    if (clipboard?.text != null) {
                      _apiKeyController.text = clipboard!.text!;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App ID (if required)
            if (providerConfig.requiresAppId) ...[
              TextField(
                controller: _appIdController,
                decoration: InputDecoration(
                  labelText: l10n.appId,
                  hintText: providerConfig.appIdDescription ?? l10n.appId,
                  prefixIcon: const Icon(Icons.app_registration),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // AccessKey Secret (if required)
            if (providerConfig.requiresAccessKeySecret) ...[
              TextField(
                controller: _accessKeySecretController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.accessKeySecret,
                  hintText: providerConfig.accessKeySecretDescription ??
                      l10n.accessKeySecret,
                  prefixIcon: const Icon(Icons.security),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Base URL (optional)
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: l10n.baseUrl,
                hintText: providerConfig.baseUrl,
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.baseUrlHint,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Model
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: l10n.modelName,
                hintText: l10n.modelNameHint,
                prefixIcon: const Icon(Icons.smart_toy),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test connection button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isTesting ? l10n.testingConnection : l10n.testConnection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Success message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Security notice
            _buildSecurityNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.securityNotice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.securityNoticeDetail,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
