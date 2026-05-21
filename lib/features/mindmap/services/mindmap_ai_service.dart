import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import 'mindmap_service.dart';

class MindMapAiService {
  final TranscriptionService _transcriptionService;
  final RecordRepository _recordRepository;

  MindMapAiService(this._transcriptionService, this._recordRepository);

  Future<List<MindMapNode>> generateAiMindMap(
      {List<String>? selectedTags}) async {
    final allRecords = await _recordRepository.getAllRecords();
    var recordsWithContent =
        allRecords.where((r) => (r.content ?? '').trim().isNotEmpty).toList();

    // 如果用户选择了标签，只使用包含这些标签的记录
    if (selectedTags != null && selectedTags.isNotEmpty) {
      recordsWithContent = recordsWithContent.where((r) {
        return r.tags.any((tag) => selectedTags.contains(tag));
      }).toList();
    }

    if (recordsWithContent.isEmpty) {
      return [];
    }

    // 获取用户设置的默认脑图模板
    final templateConfig = await StorageService.getAnalysisTemplates();
    String systemPrompt =
        '你是一个知识管理和思维导图专家。你的任务是分析用户的笔记记录，发现其中的主题关联和知识结构，生成一个结构化的知识脑图。你必须只返回JSON格式的结果，不要包含任何其他文字。';

    // 查找用户自定义模板
    final customTemplate = templateConfig.customTemplates
        .where((t) =>
            t.id == templateConfig.defaultMindMapTemplateId &&
            t.type == 'mindmap')
        .firstOrNull;
    if (customTemplate != null) {
      systemPrompt = customTemplate.systemPrompt;
    } else if (templateConfig.defaultMindMapTemplateId ==
        'builtin_mindmap_problem') {
      systemPrompt = '''你是一位问题解决专家。请分析用户的笔记记录，将核心问题拆解为结构化的脑图。

你必须只返回JSON格式的结果，不要包含任何其他文字。JSON格式如下：
{
  "nodes": [
    {
      "id": "主题ID",
      "label": "主题名称",
      "children": [
        {
          "id": "子节点ID",
          "label": "子节点名称（最多15字）",
          "recordIds": [关联的记录ID数组]
        }
      ]
    }
  ]
}

请从问题拆解的角度分析记录，主题可以是：核心问题、子问题、因果关系、优先级、资源需求、下一步行动等。''';
    } else if (templateConfig.defaultMindMapTemplateId ==
        'builtin_mindmap_opportunity') {
      systemPrompt = '''你是一位商业洞察专家。请分析用户的笔记记录，挖掘潜在的机会和关联。

你必须只返回JSON格式的结果，不要包含任何其他文字。JSON格式如下：
{
  "nodes": [
    {
      "id": "主题ID",
      "label": "主题名称",
      "children": [
        {
          "id": "子节点ID",
          "label": "子节点名称（最多15字）",
          "recordIds": [关联的记录ID数组]
        }
      ]
    }
  ]
}

请从机会洞察的角度分析记录，主题可以是：核心洞察、机会地图、关联发现、趋势判断、创新点子、行动建议等。''';
    }

    final buffer = StringBuffer();
    buffer.writeln('以下是我的多条笔记记录，请帮我分析它们之间的关联，生成一个结构化的知识脑图。');
    buffer.writeln('请按以下JSON格式返回（不要包含任何其他文字，只返回JSON）：');
    buffer.writeln('''
{
  "nodes": [
    {
      "id": "主题ID",
      "label": "主题名称",
      "children": [
        {
          "id": "子节点ID",
          "label": "子节点名称（最多15字）",
          "recordIds": [关联的记录ID数组]
        }
      ]
    }
  ]
}
''');
    buffer.writeln('\n我的记录如下：\n');

    for (final record in recordsWithContent) {
      buffer.writeln('--- 记录ID: ${record.id} ---');
      if (record.tags.isNotEmpty) {
        buffer.writeln('标签: ${record.tags.join(', ')}');
      }
      final content = record.content ?? '';
      buffer.writeln(
          '内容: ${content.length > 200 ? '${content.substring(0, 200)}...' : content}');
      buffer.writeln();
    }

    buffer.writeln('\n请分析这些记录之间的主题关联、逻辑关系，生成一个结构化的知识脑图。');
    buffer.writeln('主题数量建议3-8个，每个主题下的子节点建议2-6个。');
    buffer.writeln('子节点的label请尽量简洁，不超过15个字。');
    buffer.writeln('recordIds填写与该子节点内容最相关的记录ID。');

    final result = await _transcriptionService.analyzeText(
      buffer.toString(),
      systemPrompt: systemPrompt,
    );

    return _parseAiMindMapResult(result, recordsWithContent);
  }

  List<MindMapNode> _parseAiMindMapResult(
      String result, List<RecordModel> allRecords) {
    try {
      String jsonStr = result.trim();

      final codeBlockMatch =
          RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(jsonStr);
      if (codeBlockMatch != null) {
        jsonStr = codeBlockMatch.group(1)!.trim();
      }

      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final nodesJson = data['nodes'] as List<dynamic>?;

      if (nodesJson == null || nodesJson.isEmpty) {
        return [];
      }

      const colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.cyan,
        Colors.pink,
        Colors.teal,
        Colors.indigo,
        Colors.amber,
      ];

      final List<MindMapNode> rootNodes = [];

      for (int i = 0; i < nodesJson.length; i++) {
        final nodeJson = nodesJson[i] as Map<String, dynamic>;
        final color = colors[i % colors.length];

        final childrenJson = nodeJson['children'] as List<dynamic>? ?? [];
        final children = childrenJson.map((childJson) {
          final childMap = childJson as Map<String, dynamic>;
          final recordIds = (childMap['recordIds'] as List<dynamic>?)
                  ?.whereType<int>()
                  .toList() ??
              [];

          int primaryRecordId = -1;
          if (recordIds.isNotEmpty) {
            primaryRecordId = recordIds.first;
          }

          return MindMapNode(
            id: childMap['id']?.toString() ?? 'child_$i',
            label: childMap['label']?.toString() ?? '未命名',
            content: null,
            color: color.withOpacity(0.6),
            recordId: primaryRecordId,
          );
        }).toList();

        rootNodes.add(MindMapNode(
          id: nodeJson['id']?.toString() ?? 'node_$i',
          label: nodeJson['label']?.toString() ?? '未命名主题',
          children: children,
          color: color,
          recordId: -1,
        ));
      }

      return rootNodes;
    } catch (e) {
      AppLogger().e('MindMap', 'Failed to parse AI mind map result: $e');
      return [];
    }
  }
}
