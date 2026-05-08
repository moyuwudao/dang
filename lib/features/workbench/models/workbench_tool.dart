import 'package:flutter/material.dart';

enum ToolCategory {
  productivity,
  analysis,
  management,
  ai,
}

enum ToolLayoutMode {
  grid,
  list,
}

class WorkbenchTool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final ToolCategory category;
  final String route;
  final bool isEnabled;
  final int sortOrder;

  const WorkbenchTool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.route,
    this.isEnabled = true,
    this.sortOrder = 0,
  });

  WorkbenchTool copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    ToolCategory? category,
    String? route,
    bool? isEnabled,
    int? sortOrder,
  }) {
    return WorkbenchTool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      route: route ?? this.route,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'category': category.index,
      'route': route,
      'isEnabled': isEnabled,
      'sortOrder': sortOrder,
    };
  }

  factory WorkbenchTool.fromJson(Map<String, dynamic> json) {
    return WorkbenchTool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      color: Color(json['colorValue'] as int),
      category: ToolCategory.values[json['category'] as int],
      route: json['route'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class WorkbenchLayoutConfig {
  final ToolLayoutMode layoutMode;
  final List<String> toolOrder;
  final Map<String, bool> toolVisibility;

  const WorkbenchLayoutConfig({
    this.layoutMode = ToolLayoutMode.grid,
    this.toolOrder = const [],
    this.toolVisibility = const {},
  });

  WorkbenchLayoutConfig copyWith({
    ToolLayoutMode? layoutMode,
    List<String>? toolOrder,
    Map<String, bool>? toolVisibility,
  }) {
    return WorkbenchLayoutConfig(
      layoutMode: layoutMode ?? this.layoutMode,
      toolOrder: toolOrder ?? this.toolOrder,
      toolVisibility: toolVisibility ?? this.toolVisibility,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layoutMode': layoutMode.index,
      'toolOrder': toolOrder,
      'toolVisibility': toolVisibility,
    };
  }

  factory WorkbenchLayoutConfig.fromJson(Map<String, dynamic> json) {
    return WorkbenchLayoutConfig(
      layoutMode: ToolLayoutMode.values[json['layoutMode'] as int? ?? 0],
      toolOrder: (json['toolOrder'] as List<dynamic>?)?.cast<String>() ?? const [],
      toolVisibility: (json['toolVisibility'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
    );
  }
}
