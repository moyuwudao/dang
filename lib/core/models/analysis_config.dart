enum AnalysisMode {
  disabled,
  auto,
  manual,
  quick,
  standard,
  deep,
}

class AnalysisConfig {
  final AnalysisMode mode;
  final bool enabled;
  final String? defaultModel;
  final int delaySeconds;
  final bool autoSummarize;
  final bool autoExtractTasks;
  final bool autoSuggestTags;

  const AnalysisConfig({
    this.mode = AnalysisMode.disabled,
    this.enabled = false,
    this.defaultModel,
    this.delaySeconds = 5,
    this.autoSummarize = true,
    this.autoExtractTasks = true,
    this.autoSuggestTags = true,
  });

  factory AnalysisConfig.fromJson(Map<String, dynamic> json) {
    return AnalysisConfig(
      mode: AnalysisMode.values.byName(json['mode'] as String? ?? 'disabled'),
      enabled: json['enabled'] as bool? ?? false,
      defaultModel: json['defaultModel'] as String?,
      delaySeconds: json['delaySeconds'] as int? ?? 5,
      autoSummarize: json['autoSummarize'] as bool? ?? true,
      autoExtractTasks: json['autoExtractTasks'] as bool? ?? true,
      autoSuggestTags: json['autoSuggestTags'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'enabled': enabled,
      'defaultModel': defaultModel,
      'delaySeconds': delaySeconds,
      'autoSummarize': autoSummarize,
      'autoExtractTasks': autoExtractTasks,
      'autoSuggestTags': autoSuggestTags,
    };
  }
}
