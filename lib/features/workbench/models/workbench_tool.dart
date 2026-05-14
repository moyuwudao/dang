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
      'colorValue': color.toARGB32(),
      'category': category.index,
      'route': route,
      'isEnabled': isEnabled,
      'sortOrder': sortOrder,
    };
  }

  static IconData? _findIconByCodePoint(int codePoint) {
    for (final icon in _allIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return null;
  }

  factory WorkbenchTool.fromJson(Map<String, dynamic> json) {
    final iconCodePoint = json['iconCodePoint'] as int;
    final foundIcon = _findIconByCodePoint(iconCodePoint);

    return WorkbenchTool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: foundIcon ??
          const IconData(
            0xe88a,
            fontFamily: 'MaterialIcons',
          ),
      color: Color(json['colorValue'] as int),
      category: ToolCategory.values[json['category'] as int],
      route: json['route'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

const List<IconData> _allIcons = [
  Icons.account_tree_outlined,
  Icons.summarize_outlined,
  Icons.task_alt_outlined,
  Icons.description_outlined,
  Icons.mail_outlined,
  Icons.content_copy_outlined,
  Icons.auto_stories_outlined,
  Icons.translate_outlined,
  Icons.schedule_outlined,
  Icons.rate_review_outlined,
  Icons.grid_on_outlined,
  Icons.person_search_outlined,
  Icons.trending_up_outlined,
  Icons.my_location_outlined,
  Icons.view_agenda_outlined,
  Icons.contacts_outlined,
  Icons.receipt_long_outlined,
  Icons.gavel_outlined,
  Icons.request_quote_outlined,
  Icons.style_outlined,
  Icons.psychology_outlined,
  Icons.lightbulb_outlined,
  Icons.question_answer_outlined,
  Icons.calculate_outlined,
  Icons.edit_note_outlined,
  Icons.quiz_outlined,
];

class WorkbenchLayoutConfig {
  final ToolLayoutMode layoutMode;
  final List<String> toolOrder;
  final Map<String, bool> toolVisibility;
  final Map<String, bool> showInHome;
  final List<String> recentToolIds;

  static const int maxRecentTools = 3;

  const WorkbenchLayoutConfig({
    this.layoutMode = ToolLayoutMode.grid,
    this.toolOrder = const [],
    this.toolVisibility = const {},
    this.showInHome = const {},
    this.recentToolIds = const [],
  });

  WorkbenchLayoutConfig copyWith({
    ToolLayoutMode? layoutMode,
    List<String>? toolOrder,
    Map<String, bool>? toolVisibility,
    Map<String, bool>? showInHome,
    List<String>? recentToolIds,
  }) {
    return WorkbenchLayoutConfig(
      layoutMode: layoutMode ?? this.layoutMode,
      toolOrder: toolOrder ?? this.toolOrder,
      toolVisibility: toolVisibility ?? this.toolVisibility,
      showInHome: showInHome ?? this.showInHome,
      recentToolIds: recentToolIds ?? this.recentToolIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layoutMode': layoutMode.index,
      'toolOrder': toolOrder,
      'toolVisibility': toolVisibility,
      'showInHome': showInHome,
      'recentToolIds': recentToolIds,
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
      showInHome: (json['showInHome'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
      recentToolIds: (json['recentToolIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
