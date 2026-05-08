import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_role.dart';
import 'api_service.dart';

final aiSummaryServiceProvider = Provider((ref) => AISummaryService(ref));

class TodoItem {
  final String id;
  final String description;
  final String priority;
  final DateTime? dueDate;
  final bool completed;

  TodoItem({
    required this.id,
    required this.description,
    required this.priority,
    this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'completed': completed,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      description: json['description'],
      priority: json['priority'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      completed: json['completed'] ?? false,
    );
  }
}

class AISummaryService {
  final Ref ref;

  AISummaryService(this.ref);

  Future<List<TodoItem>> generateTodoList(String content) async {
    final apiService = ref.read(apiServiceProvider);
    final prompt = _buildTodoPrompt(content);

    final response = await apiService.completeChat([
      {'role': 'system', 'content': _systemPrompt},
      {'role': 'user', 'content': prompt},
    ]);

    return _parseTodoResponse(response);
  }

  Future<String> generateSummary(String content) async {
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.completeChat([
      {'role': 'system', 'content': _summarySystemPrompt},
      {'role': 'user', 'content': content},
    ]);

    return response;
  }

  Future<String> generateKeyPoints(String content) async {
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.completeChat([
      {'role': 'system', 'content': _keyPointsSystemPrompt},
      {'role': 'user', 'content': content},
    ]);

    return response;
  }

  Future<String> analyzeWithRole(String content, AIRole role) async {
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.completeChat([
      {'role': 'system', 'content': role.systemPrompt},
      {'role': 'user', 'content': content},
    ]);

    return response;
  }

  String _buildTodoPrompt(String content) {
    return '''
请将以下内容总结为待办事项列表：

内容：
$content

请按照JSON格式输出，包含以下字段：
- id: 唯一标识
- description: 任务描述
- priority: 优先级（高/中/低）
- dueDate: 截止日期（ISO格式，如无则为null）
- completed: 是否完成（默认false）

示例格式：
[
  {"id": "1", "description": "完成项目文档", "priority": "高", "dueDate": "2024-01-15", "completed": false}
]
''';
  }

  List<TodoItem> _parseTodoResponse(String response) {
    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');

      if (jsonStart == -1 || jsonEnd == -1) {
        return _parsePlainTextTodo(response);
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      return jsonList
          .map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return _parsePlainTextTodo(response);
    }
  }

  List<TodoItem> _parsePlainTextTodo(String response) {
    final lines = response.split('\n');
    final todos = <TodoItem>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final match = RegExp(r'^[\d\-\*]+[\.\s]+(.+)').firstMatch(line);
      if (match != null) {
        todos.add(TodoItem(
          id: 'todo_${DateTime.now().millisecondsSinceEpoch}_$i',
          description: match.group(1)!,
          priority: '中',
        ));
      }
    }

    return todos;
  }

  String get _systemPrompt => '''
你是一个高效的待办事项提取助手。请从用户提供的文本中提取待办事项，并按照指定的JSON格式输出。

规则：
1. 只提取明确的行动项，忽略一般性陈述
2. 根据任务的重要性分配优先级（高/中/低）
3. 如果文本中提到日期，解析为dueDate
4. 输出格式必须是有效的JSON数组
5. 如果无法提取任何待办事项，返回空数组[]
''';

  String get _summarySystemPrompt => '''
你是一个专业的文本摘要助手。请对用户提供的内容进行简洁、准确的总结。

要求：
1. 提取核心要点，不超过3-5句话
2. 保持原意，不添加额外信息
3. 使用简洁的语言
''';

  String get _keyPointsSystemPrompt => '''
请从以下内容中提取关键要点，用项目符号列出：

要求：
1. 每个要点不超过20字
2. 提取最重要的5-10个要点
3. 保持简洁明了
''';
}
