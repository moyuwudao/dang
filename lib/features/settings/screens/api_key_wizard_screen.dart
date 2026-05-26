import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/aliyun_signer.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/api_config_provider.dart';

class ApiKeyWizardScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;
  const ApiKeyWizardScreen({super.key, this.isFromSettings = false});

  @override
  ConsumerState<ApiKeyWizardScreen> createState() => _ApiKeyWizardScreenState();
}

class _ApiKeyWizardScreenState extends ConsumerState<ApiKeyWizardScreen> {
  int _currentStep = 0;
  AiProvider _selectedProvider = AiProvider.openAI;
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _appIdController = TextEditingController();
  final _accessKeySecretController = TextEditingController();
  final _customProviderNameController = TextEditingController();
  bool _isCustomProvider = false;
  bool _isLoading = false;
  String? _errorMessage;

  // 功能选择
  final Set<ApiFunctionType> _selectedFunctions = {ApiFunctionType.text};

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _appIdController.dispose();
    _accessKeySecretController.dispose();
    _customProviderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apiKeyWizard),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => _previousStep(),
              child: Text(l10n.prevStep, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _buildStepContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProviderSelectionStep();
      case 1:
        return _buildFunctionSelectionStep();
      case 2:
        return _buildApiKeyInputStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProviderSelectionStep() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectProvider,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectProviderDesc,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...AiModelConfig.allProviders.map((config) => _buildProviderCard(config)),
          const SizedBox(height: 16),
          _buildCustomProviderCard(),
        ],
      ),
    );
  }

  Widget _buildProviderCard(AiModelConfig config) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedProvider == config.provider && !_isCustomProvider;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProvider = config.provider;
            _isCustomProvider = false;
            _modelController.text = config.defaultModel;
            _errorMessage = null;
            // 自动选择该模型支持的所有功能
            _selectedFunctions.clear();
            _selectedFunctions.addAll(
              ApiFunctionType.values.where((f) =>
                  AiModelConfig.providerSupportsFunction(config.provider, f)),
            );
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.api, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          config.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              _buildCapabilityChips(config),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomProviderCard() {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _isCustomProvider;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isCustomProvider = true;
            _selectedProvider = AiProvider.custom;
            _errorMessage = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.custom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.customProviderDesc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityChips(AiModelConfig config) {
    final l10n = AppLocalizations.of(context)!;
    final capabilities = <Widget>[];

    if (config.supportsTextAnalysis) {
      capabilities.add(_buildChip(l10n.textAnalysis, AppColors.success));
    }
    if (config.supportsTranscription || config.supportsOfflineTranscription) {
      capabilities.add(_buildChip(l10n.voiceTranscription, AppColors.success));
    }
    if (config.supportsRealtimeTranscription) {
      capabilities.add(_buildChip(l10n.realtimeVoiceTranscription, AppColors.primary));
    }
    if (config.supportsOfflineTranscription) {
      capabilities.add(_buildChip(l10n.offlineVoiceTranscription, AppColors.primary));
    }
    if (config.supportsSpeakerDiarization) {
      capabilities.add(_buildChip(l10n.textAnalysis, AppColors.primary));
    }
    if (config.supportsOCR) {
      capabilities.add(_buildChip(l10n.imageRecognition, AppColors.success));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: capabilities,
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildFunctionSelectionStep() {
    final l10n = AppLocalizations.of(context)!;
    final config = AiModelConfig.getConfig(_selectedProvider);
    final compatibleFunctions = ApiFunctionType.values
        .where((f) =>
            AiModelConfig.providerSupportsFunction(_selectedProvider, f))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectFeatures,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectFeaturesDesc,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (compatibleFunctions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.noCompatibleFunctions,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            )
          else
            ...compatibleFunctions.map((f) => _buildFunctionCard(f)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${config.displayName} ${l10n.providerCapabilityDesc}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildModelCapabilityInfo(config),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCapabilityInfo(AiModelConfig config) {
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[];

    if (config.supportsTextAnalysis) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.textAnalysis, l10n.textAnalysisDesc));
    }
    if (config.supportsTranscription || config.supportsOfflineTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.voiceTranscription, config.asrDescription.isNotEmpty
          ? config.asrDescription.split('\n').first
          : l10n.voiceTranscriptionDesc));
    }
    if (config.supportsRealtimeTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.realtimeVoiceTranscription, config.realtimeAsrDescription.isNotEmpty
          ? config.realtimeAsrDescription.split('\n').first
          : l10n.realtimeVoiceTranscriptionDesc));
    }
    if (config.supportsOfflineTranscription) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.offlineVoiceTranscription, l10n.offlineVoiceTranscriptionDesc));
    }
    if (config.supportsSpeakerDiarization) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.textAnalysis, l10n.textAnalysisDesc));
    }
    if (config.supportsOCR) {
      items.add(_buildInfoRow(Icons.check_circle, l10n.imageRecognition, l10n.imageRecognitionDesc));
    }

    if (config.limitationNote.isNotEmpty) {
      items.add(const SizedBox(height: 8));
      items.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                config.limitationNote,
                style: const TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(ApiFunctionType function) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedFunctions.contains(function);
    final label = AiModelConfig.getFunctionTypeLabel(function);
    final description = _getFunctionDescription(function);
    final icon = _getFunctionIcon(function);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              if (_selectedFunctions.length > 1) {
                _selectedFunctions.remove(function);
              }
            } else {
              _selectedFunctions.add(function);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? null : Colors.grey[600],
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.textSecondary
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  String _getFunctionDescription(ApiFunctionType function) {
    final l10n = AppLocalizations.of(context)!;
    switch (function) {
      case ApiFunctionType.text:
        return l10n.textAnalysisDesc;
      case ApiFunctionType.voice:
        return l10n.voiceTranscriptionDesc;
      case ApiFunctionType.voiceRealtime:
        return l10n.realtimeVoiceTranscriptionDesc;
      case ApiFunctionType.offlineVoice:
        return l10n.offlineVoiceTranscriptionDesc;
      case ApiFunctionType.image:
        return l10n.imageRecognitionDesc;
    }
  }

  IconData _getFunctionIcon(ApiFunctionType function) {
    switch (function) {
      case ApiFunctionType.text:
        return Icons.text_fields;
      case ApiFunctionType.voice:
        return Icons.mic;
      case ApiFunctionType.voiceRealtime:
        return Icons.record_voice_over;
      case ApiFunctionType.offlineVoice:
        return Icons.offline_bolt;
      case ApiFunctionType.image:
        return Icons.image;
    }
  }

  Widget _buildApiKeyInputStep() {
    final l10n = AppLocalizations.of(context)!;
    final config = AiModelConfig.getConfig(_selectedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.enterApiKey,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.enterApiKeyDesc,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_isCustomProvider) ...[
            TextField(
              controller: _customProviderNameController,
              decoration: InputDecoration(
                labelText: l10n.customProviderName,
                hintText: l10n.customProviderNameHint,
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: config.apiKeyPrefix != null
                  ? '${config.apiKeyPrefix}...'
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
          if (config.requiresAppId) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _appIdController,
              decoration: InputDecoration(
                labelText: l10n.appId,
                hintText: config.appIdDescription ?? l10n.appId,
                prefixIcon: const Icon(Icons.app_registration),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (config.requiresAccessKeySecret) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _accessKeySecretController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.accessKeySecret,
                hintText: config.accessKeySecretDescription ?? l10n.accessKeySecret,
                prefixIcon: const Icon(Icons.security),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (_isCustomProvider) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: l10n.baseUrl,
                hintText: 'https://api.example.com/v1',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
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
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
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
          ],
          const SizedBox(height: 24),
          _buildSecurityNotice(),
        ],
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

  Widget _buildConfirmationStep() {
    final l10n = AppLocalizations.of(context)!;
    final config = AiModelConfig.getConfig(_selectedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.confirmConfig,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.confirmConfigDesc,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildConfirmItem(l10n.provider, _isCustomProvider
              ? (_customProviderNameController.text.isNotEmpty
                  ? _customProviderNameController.text
                  : l10n.custom)
              : config.displayName),
          _buildConfirmItem(l10n.modelName, _modelController.text),
          _buildConfirmItem(l10n.apiKey,
              '${_apiKeyController.text.substring(0, _apiKeyController.text.length > 8 ? 8 : _apiKeyController.text.length)}...'),
          if (_appIdController.text.isNotEmpty)
            _buildConfirmItem(l10n.appId, _appIdController.text),
          if (_baseUrlController.text.isNotEmpty)
            _buildConfirmItem(l10n.baseUrl, _baseUrlController.text),
          const SizedBox(height: 16),
          Text(
            l10n.selectedFeatures,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedFunctions
                .map((f) => Chip(
                      label: Text(AiModelConfig.getFunctionTypeLabel(f)),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Text('${_currentStep + 1}/4'),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                  : Text(_currentStep == 3 ? l10n.finish : l10n.nextStep),
            ),
          ],
        ),
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    }
  }

  void _nextStep() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        if (_isCustomProvider && _customProviderNameController.text.isEmpty) {
          setState(() {
            _errorMessage = l10n.enterCustomProviderName;
          });
          return;
        }
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
        break;
      case 1:
        if (_selectedFunctions.isEmpty) {
          setState(() {
            _errorMessage = l10n.selectAtLeastOneFeature;
          });
          return;
        }
        // 校验选择的功能是否都兼容
        final incompatible = _selectedFunctions
            .where((f) => !AiModelConfig.providerSupportsFunction(_selectedProvider, f))
            .toList();
        if (incompatible.isNotEmpty) {
          final reason = incompatible
              .map((f) => AiModelConfig.getUnsupportedReason(_selectedProvider, f))
              .join('\n');
          setState(() {
            _errorMessage = '${l10n.featureIncompatible}:\n$reason';
          });
          return;
        }
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
        break;
      case 2:
        if (_apiKeyController.text.isEmpty) {
          setState(() {
            _errorMessage = l10n.apiKeyRequired;
          });
          return;
        }
        if (_modelController.text.isEmpty) {
          setState(() {
            _errorMessage = l10n.modelNameRequired;
          });
          return;
        }
        final config = AiModelConfig.getConfig(_selectedProvider);
        if (config.requiresAppId && _appIdController.text.isEmpty) {
          setState(() {
            _errorMessage = l10n.appIdRequired;
          });
          return;
        }
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
        break;
      case 3:
        _saveConfig();
        break;
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = ApiConfigEntry(
        id: 'config_${DateTime.now().millisecondsSinceEpoch}',
        name: _isCustomProvider
            ? (_customProviderNameController.text.isNotEmpty
                ? _customProviderNameController.text
                : '自定义配置')
            : AiModelConfig.getConfig(_selectedProvider).displayName,
        provider: _selectedProvider,
        apiKey: _apiKeyController.text.trim(),
        appId: _appIdController.text.trim().isEmpty
            ? null
            : _appIdController.text.trim(),
        baseUrl: _baseUrlController.text.trim().isEmpty
            ? null
            : _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        isCustomProvider: _isCustomProvider,
        customProviderName: _isCustomProvider
            ? _customProviderNameController.text.trim()
            : null,
        functions: _selectedFunctions.toList(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accessKeySecret: _accessKeySecretController.text.trim().isEmpty
            ? null
            : _accessKeySecretController.text.trim(),
      );

      final existingConfig = await StorageService.getMultiApiConfig();
      final newConfigs = List<ApiConfigEntry>.from(existingConfig.configs)
        ..add(config);
      final updatedConfig = existingConfig.copyWith(configs: newConfigs);

      await StorageService.saveMultiApiConfig(updatedConfig);

      // 同步到运行时 - 使用 ApiService 单例
      final apiService = ApiService();
      final providerConfig = AiModelConfig.getConfig(config.provider);
      apiService.configure(
        apiKey: config.apiKey,
        config: providerConfig,
        customBaseUrl: config.baseUrl,
        appId: config.appId,
        accessKeySecret: config.accessKeySecret,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = '${l10n.saveFailed}: $e';
          _isLoading = false;
        });
      }
    }
  }
}
