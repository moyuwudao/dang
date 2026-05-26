import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ToolAiConfigScreen extends ConsumerStatefulWidget {
  const ToolAiConfigScreen({super.key});

  @override
  ConsumerState<ToolAiConfigScreen> createState() => _ToolAiConfigScreenState();
}

class _ToolAiConfigScreenState extends ConsumerState<ToolAiConfigScreen> {
  bool _isLoading = true;
  String _transcriptionModel = 'qwen-realtime';
  String _analysisModel = 'qwen-max';
  String _summaryModel = 'qwen-turbo';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await StorageService.getToolAiConfig();
    setState(() {
      _transcriptionModel = config['transcription_model'] ?? 'qwen-realtime';
      _analysisModel = config['analysis_model'] ?? 'qwen-max';
      _summaryModel = config['summary_model'] ?? 'qwen-turbo';
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    await StorageService.saveToolAiConfig({
      'transcription_model': _transcriptionModel,
      'analysis_model': _analysisModel,
      'summary_model': _summaryModel,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.toolAiConfig),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: l10n.transcriptionModel,
            icon: Icons.mic,
            children: [
              _buildModelSelector(
                value: _transcriptionModel,
                onChanged: (value) {
                  setState(() {
                    _transcriptionModel = value;
                  });
                  _saveConfig();
                },
                models: [
                  _ModelOption('qwen-realtime', l10n.qwenRealtime),
                  _ModelOption('qwen-audio', l10n.qwenAudio),
                  _ModelOption('paraformer-realtime', l10n.paraformerRealtime),
                  _ModelOption('paraformer', l10n.paraformer),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l10n.analysisModel,
            icon: Icons.psychology,
            children: [
              _buildModelSelector(
                value: _analysisModel,
                onChanged: (value) {
                  setState(() {
                    _analysisModel = value;
                  });
                  _saveConfig();
                },
                models: [
                  _ModelOption('qwen-max', l10n.qwenMax),
                  _ModelOption('qwen-plus', l10n.qwenPlus),
                  _ModelOption('qwen-turbo', l10n.qwenTurbo),
                  _ModelOption('deepseek-chat', l10n.deepseekChat),
                  _ModelOption('deepseek-reasoner', l10n.deepseekReasoner),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l10n.summaryModel,
            icon: Icons.summarize,
            children: [
              _buildModelSelector(
                value: _summaryModel,
                onChanged: (value) {
                  setState(() {
                    _summaryModel = value;
                  });
                  _saveConfig();
                },
                models: [
                  _ModelOption('qwen-turbo', l10n.qwenTurbo),
                  _ModelOption('qwen-plus', l10n.qwenPlus),
                  _ModelOption('qwen-max', l10n.qwenMax),
                  _ModelOption('deepseek-chat', l10n.deepseekChat),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModelSelector({
    required String value,
    required ValueChanged<String> onChanged,
    required List<_ModelOption> models,
  }) {
    return Column(
      children: models.map((model) {
        return RadioListTile<String>(
          title: Text(model.label),
          subtitle: Text(model.value),
          value: model.value,
          groupValue: value,
          onChanged: (value) => onChanged(value!),
        );
      }).toList(),
    );
  }
}

class _ModelOption {
  final String value;
  final String label;

  _ModelOption(this.value, this.label);
}
