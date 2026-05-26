import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/analysis_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class AutoAnalysisSettingsScreen extends ConsumerStatefulWidget {
  const AutoAnalysisSettingsScreen({super.key});

  @override
  ConsumerState<AutoAnalysisSettingsScreen> createState() =>
      _AutoAnalysisSettingsScreenState();
}

class _AutoAnalysisSettingsScreenState
    extends ConsumerState<AutoAnalysisSettingsScreen> {
  bool _isLoading = true;
  bool _enabled = true;
  AnalysisMode _mode = AnalysisMode.quick;
  int _delaySeconds = 5;
  bool _autoSummarize = true;
  bool _autoExtractTasks = true;
  bool _autoSuggestTags = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final config = await StorageService.getAnalysisConfig();
    setState(() {
      _enabled = config.enabled;
      _mode = config.mode;
      _delaySeconds = config.delaySeconds;
      _autoSummarize = config.autoSummarize;
      _autoExtractTasks = config.autoExtractTasks;
      _autoSuggestTags = config.autoSuggestTags;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final config = AnalysisConfig(
      enabled: _enabled,
      mode: _mode,
      delaySeconds: _delaySeconds,
      autoSummarize: _autoSummarize,
      autoExtractTasks: _autoExtractTasks,
      autoSuggestTags: _autoSuggestTags,
    );
    await StorageService.saveAnalysisConfig(config);
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
        title: Text(l10n.autoAnalysisSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: l10n.autoAnalysisSwitch,
            children: [
              SwitchListTile(
                title: Text(l10n.autoAnalysisEnabled),
                subtitle: Text(l10n.autoAnalysisEnabledDesc),
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 16),
            _buildSection(
              title: l10n.analysisMode,
              children: [
                RadioListTile<AnalysisMode>(
                  title: Text(l10n.quickAnalysis),
                  subtitle: Text(l10n.quickAnalysisDesc),
                  value: AnalysisMode.quick,
                  groupValue: _mode,
                  onChanged: (value) {
                    setState(() {
                      _mode = value!;
                    });
                    _saveSettings();
                  },
                ),
                RadioListTile<AnalysisMode>(
                  title: Text(l10n.standardAnalysis),
                  subtitle: Text(l10n.standardAnalysisDesc),
                  value: AnalysisMode.standard,
                  groupValue: _mode,
                  onChanged: (value) {
                    setState(() {
                      _mode = value!;
                    });
                    _saveSettings();
                  },
                ),
                RadioListTile<AnalysisMode>(
                  title: Text(l10n.deepAnalysis),
                  subtitle: Text(l10n.deepAnalysisDesc),
                  value: AnalysisMode.deep,
                  groupValue: _mode,
                  onChanged: (value) {
                    setState(() {
                      _mode = value!;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: l10n.analysisDelay,
              children: [
                ListTile(
                  title: Text(l10n.delaySeconds),
                  subtitle: Text(l10n.delaySecondsDesc),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: l10n.seconds,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: TextEditingController(
                        text: _delaySeconds.toString(),
                      ),
                      onSubmitted: (value) {
                        final seconds = int.tryParse(value);
                        if (seconds != null && seconds >= 0) {
                          setState(() {
                            _delaySeconds = seconds;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: l10n.autoAnalysisItems,
              children: [
                CheckboxListTile(
                  title: Text(l10n.autoSummarize),
                  subtitle: Text(l10n.autoSummarizeDesc),
                  value: _autoSummarize,
                  onChanged: (value) {
                    setState(() {
                      _autoSummarize = value ?? true;
                    });
                    _saveSettings();
                  },
                ),
                CheckboxListTile(
                  title: Text(l10n.autoExtractTasks),
                  subtitle: Text(l10n.autoExtractTasksDesc),
                  value: _autoExtractTasks,
                  onChanged: (value) {
                    setState(() {
                      _autoExtractTasks = value ?? true;
                    });
                    _saveSettings();
                  },
                ),
                CheckboxListTile(
                  title: Text(l10n.autoSuggestTags),
                  subtitle: Text(l10n.autoSuggestTagsDesc),
                  value: _autoSuggestTags,
                  onChanged: (value) {
                    setState(() {
                      _autoSuggestTags = value ?? true;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
