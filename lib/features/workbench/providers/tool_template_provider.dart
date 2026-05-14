import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_template.dart';
import '../tools/tool_templates.dart';
import '../tools/tool_configs.dart';

final toolTemplateProvider = StateNotifierProvider<ToolTemplateNotifier,
    Map<String, List<ToolTemplate>>>(
  (ref) => ToolTemplateNotifier(),
);

class ToolTemplateNotifier
    extends StateNotifier<Map<String, List<ToolTemplate>>> {
  ToolTemplateNotifier() : super({}) {
    _loadTemplates();
  }

  static const String _templatesKey = 'tool_templates';

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getString(_templatesKey);

    if (templatesJson != null) {
      try {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(_decodeJson(templatesJson));
        final Map<String, List<ToolTemplate>> userTemplates = {};

        data.forEach((toolId, templatesData) {
          if (templatesData is List) {
            userTemplates[toolId] = (templatesData)
                .map((item) =>
                    ToolTemplate.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        });

        state = _mergeTemplates(userTemplates);
      } catch (e) {
        state = _mergeTemplates({});
      }
    } else {
      state = _mergeTemplates({});
    }
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final userTemplates = Map<String, List<ToolTemplate>>.from(state);

    userTemplates.forEach((toolId, templates) {
      userTemplates[toolId] = templates.where((t) => !t.isBuiltIn).toList();
    });

    final data = userTemplates.map((toolId, templates) {
      return MapEntry(
        toolId,
        templates.map((t) => t.toJson()).toList(),
      );
    });

    await prefs.setString(_templatesKey, _encodeJson(data));
  }

  Map<String, List<ToolTemplate>> _mergeTemplates(
      Map<String, List<ToolTemplate>> userTemplates) {
    final merged = <String, List<ToolTemplate>>{};

    for (final toolId in toolConfigs.keys) {
      final builtIn = builtInTemplates[toolId] ?? [];
      final user = userTemplates[toolId] ?? [];

      merged[toolId] = [...builtIn, ...user];
    }

    return merged;
  }

  void setDefaultTemplate(String toolId, String templateId) {
    final templates = state[toolId];
    if (templates == null) return;

    state = {
      ...state,
      toolId: templates
          .map((t) => t.copyWith(isDefault: t.id == templateId))
          .toList(),
    };

    _saveTemplates();
  }

  void addTemplate(String toolId, ToolTemplate template) {
    final templates = state[toolId] ?? [];

    final newTemplate = template.copyWith(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isBuiltIn: false,
    );

    state = {
      ...state,
      toolId: [...templates, newTemplate],
    };

    if (newTemplate.isDefault) {
      setDefaultTemplate(toolId, newTemplate.id);
    } else {
      _saveTemplates();
    }
  }

  void editTemplate(
      String toolId, String templateId, ToolTemplate updatedTemplate) {
    final templates = state[toolId];
    if (templates == null) return;

    state = {
      ...state,
      toolId: templates
          .map((t) => t.id == templateId ? updatedTemplate : t)
          .toList(),
    };

    _saveTemplates();
  }

  void deleteTemplate(String toolId, String templateId) {
    final templates = state[toolId];
    if (templates == null) return;

    final templateToDelete = templates.firstWhere((t) => t.id == templateId);
    if (templateToDelete.isBuiltIn) return;

    final newTemplates = templates.where((t) => t.id != templateId).toList();

    if (templateToDelete.isDefault && newTemplates.isNotEmpty) {
      newTemplates[0] = newTemplates[0].copyWith(isDefault: true);
    }

    state = {
      ...state,
      toolId: newTemplates,
    };

    _saveTemplates();
  }

  ToolTemplate? getDefaultTemplate(String toolId) {
    final templates = state[toolId];
    if (templates == null || templates.isEmpty) return null;

    return templates.firstWhere(
      (t) => t.isDefault,
      orElse: () => templates.first,
    );
  }

  dynamic _decodeJson(String json) {
    try {
      return _parseJson(json);
    } catch (_) {
      return {};
    }
  }

  String _encodeJson(dynamic data) {
    return _stringifyJson(data);
  }

  dynamic _parseJson(String source) {
    return _simpleJsonDecode(source);
  }

  String _stringifyJson(dynamic object) {
    return _simpleJsonEncode(object);
  }

  dynamic _simpleJsonDecode(String source) {
    final result = <String, dynamic>{};
    final trimmed = source.trim().substring(1, source.length - 1);
    final pairs = _splitJsonPairs(trimmed);

    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex == -1) continue;

      final key = _trimQuotes(pair.substring(0, colonIndex).trim());
      final value = pair.substring(colonIndex + 1).trim();

      result[key] = _parseJsonValue(value);
    }

    return result;
  }

  String _simpleJsonEncode(dynamic object) {
    if (object is Map) {
      final pairs = object.entries
          .map((e) => '"${e.key}": ${_simpleJsonEncode(e.value)}')
          .join(',');
      return '{$pairs}';
    } else if (object is List) {
      final items = object.map((e) => _simpleJsonEncode(e)).join(',');
      return '[$items]';
    } else if (object is String) {
      return '"${_escapeString(object)}"';
    } else {
      return object.toString();
    }
  }

  List<String> _splitJsonPairs(String source) {
    final pairs = <String>[];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < source.length; i++) {
      final char = source[i];
      if (char == '{') depth++;
      if (char == '}') depth--;
      if (char == '[') depth++;
      if (char == ']') depth--;
      if (char == ',' && depth == 0) {
        pairs.add(source.substring(start, i));
        start = i + 1;
      }
    }

    if (start < source.length) {
      pairs.add(source.substring(start));
    }

    return pairs;
  }

  String _trimQuotes(String str) {
    if (str.startsWith('"') && str.endsWith('"')) {
      return str.substring(1, str.length - 1);
    }
    return str;
  }

  dynamic _parseJsonValue(String value) {
    if (value.startsWith('"') && value.endsWith('"')) {
      return _trimQuotes(value);
    } else if (value.startsWith('{')) {
      return _simpleJsonDecode(value);
    } else if (value.startsWith('[')) {
      return _parseJsonArray(value);
    } else if (value == 'true') {
      return true;
    } else if (value == 'false') {
      return false;
    } else if (value == 'null') {
      return null;
    } else {
      try {
        return int.parse(value);
      } catch (_) {
        try {
          return double.parse(value);
        } catch (_) {
          return value;
        }
      }
    }
  }

  List<dynamic> _parseJsonArray(String source) {
    final items = <dynamic>[];
    final trimmed = source.substring(1, source.length - 1);
    final parts = _splitJsonPairs(trimmed);

    for (final part in parts) {
      items.add(_parseJsonValue(part));
    }

    return items;
  }

  String _escapeString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }
}
