import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

class MindMapNode {
  final String id;
  final String label;
  final String? content;
  final List<MindMapNode> children;
  final Color color;
  final int recordId;

  MindMapNode({
    required this.id,
    required this.label,
    this.content,
    this.children = const [],
    this.color = Colors.blue,
    required this.recordId,
  });

  MindMapNode copyWith({
    String? id,
    String? label,
    String? content,
    List<MindMapNode>? children,
    Color? color,
    int? recordId,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      label: label ?? this.label,
      content: content ?? this.content,
      children: children ?? this.children,
      color: color ?? this.color,
      recordId: recordId ?? this.recordId,
    );
  }
}

class MindMapService {
  final RecordRepository _repository;

  MindMapService(this._repository);

  Future<List<MindMapNode>> generateMindMapByTag() async {
    final allRecords = await _repository.getAllRecords();
    
    Map<String, List<RecordModel>> recordsByTag = {};
    
    for (final record in allRecords) {
      for (final tag in record.tags) {
        if (!recordsByTag.containsKey(tag)) {
          recordsByTag[tag] = [];
        }
        recordsByTag[tag]!.add(record);
      }
    }

    final List<MindMapNode> rootNodes = [];
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
    ];

    int colorIndex = 0;
    for (final entry in recordsByTag.entries) {
      final tag = entry.key;
      final records = entry.value;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      final children = records
          .map((record) => MindMapNode(
                id: 'record_${record.id}',
                label: record.content?.substring(0, (record.content!.length > 20 ? 20 : record.content!.length)) ?? '无内容',
                content: record.content,
                color: color.withOpacity(0.6),
                recordId: record.id,
              ))
          .toList();

      rootNodes.add(MindMapNode(
        id: 'tag_$tag',
        label: tag,
        children: children,
        color: color,
        recordId: -1,
      ));
    }

    return rootNodes;
  }

  Future<List<MindMapNode>> generateMindMapByDate() async {
    final allRecords = await _repository.getAllRecords();
    
    Map<String, List<RecordModel>> recordsByDate = {};
    
    for (final record in allRecords) {
      final dateKey = '${record.createdAt.year}-${record.createdAt.month.toString().padLeft(2, '0')}';
      if (!recordsByDate.containsKey(dateKey)) {
        recordsByDate[dateKey] = [];
      }
      recordsByDate[dateKey]!.add(record);
    }

    final List<MindMapNode> rootNodes = [];
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.cyan,
    ];

    int colorIndex = 0;
    final sortedKeys = recordsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final dateKey in sortedKeys) {
      final records = recordsByDate[dateKey]!;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      final children = records
          .map((record) => MindMapNode(
                id: 'record_${record.id}',
                label: record.content?.substring(0, (record.content!.length > 15 ? 15 : record.content!.length)) ?? '无内容',
                content: record.content,
                color: color.withOpacity(0.6),
                recordId: record.id,
              ))
          .toList();

      rootNodes.add(MindMapNode(
        id: 'date_$dateKey',
        label: dateKey,
        children: children,
        color: color,
        recordId: -1,
      ));
    }

    return rootNodes;
  }
}

final mindMapServiceProvider = Provider<MindMapService>((ref) {
  return MindMapService(ref.watch(recordRepositoryProvider));
});
