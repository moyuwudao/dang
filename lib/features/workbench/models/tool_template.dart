class ToolTemplate {
  final String id;
  final String toolId;
  final String name;
  final String description;
  final String systemPrompt;
  final Map<String, dynamic> parameters;
  final bool isDefault;
  final bool isBuiltIn;
  final DateTime? createdAt;

  const ToolTemplate({
    required this.id,
    required this.toolId,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.parameters = const {},
    this.isDefault = false,
    this.isBuiltIn = true,
    this.createdAt,
  });

  ToolTemplate copyWith({
    String? id,
    String? toolId,
    String? name,
    String? description,
    String? systemPrompt,
    Map<String, dynamic>? parameters,
    bool? isDefault,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return ToolTemplate(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      parameters: parameters ?? this.parameters,
      isDefault: isDefault ?? this.isDefault,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'name': name,
        'description': description,
        'systemPrompt': systemPrompt,
        'parameters': parameters,
        'isDefault': isDefault,
        'isBuiltIn': isBuiltIn,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ToolTemplate.fromJson(Map<String, dynamic> json) => ToolTemplate(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        systemPrompt: json['systemPrompt'] as String,
        parameters: (json['parameters'] as Map<String, dynamic>?) ?? const {},
        isDefault: json['isDefault'] as bool? ?? false,
        isBuiltIn: json['isBuiltIn'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
