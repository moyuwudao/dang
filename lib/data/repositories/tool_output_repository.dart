
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/tool_output_model.dart';
import 'record_repository.dart';

final toolOutputRepositoryProvider = Provider<ToolOutputRepository>((ref) {
  return ToolOutputRepository(ref.watch(appDatabaseProvider));
});

class ToolOutputRepository {
  final AppDatabase _database;

  ToolOutputRepository(this._database);

  Future<List<ToolOutputModel>> getAllToolOutputs() async {
    final outputs = await _database.getAllToolOutputs();
    return outputs.map(_mapToModel).toList();
  }

  Future<List<ToolOutputModel>> getToolOutputsByToolId(String toolId) async {
    final outputs = await _database.getToolOutputsByToolId(toolId);
    return outputs.map(_mapToModel).toList();
  }

  Future<ToolOutputModel?> getToolOutputById(int id) async {
    final output = await _database.getToolOutputById(id);
    return output != null ? _mapToModel(output) : null;
  }

  Future<int> createToolOutput({
    required String toolId,
    required String title,
    required String content,
    List<String> tags = const [],
    List<int> sourceRecordIds = const [],
    String? templateId,
  }) async {
    final now = DateTime.now();
    final companion = ToolOutputsCompanion(
      toolId: Value(toolId),
      title: Value(title),
      content: Value(content),
      createdAt: Value(now),
      updatedAt: Value(now),
      tags: Value(jsonEncode(tags)),
      sourceRecordIds: Value(jsonEncode(sourceRecordIds)),
      templateId: Value(templateId),
      usageCount: const Value(0),
    );
    return await _database.insertToolOutput(companion);
  }

  Future<void> updateToolOutput({
    required int id,
    String? title,
    String? content,
    List<String>? tags,
    List<int>? sourceRecordIds,
    String? templateId,
  }) async {
    final existing = await _database.getToolOutputById(id);
    if (existing == null) return;

    final companion = ToolOutputsCompanion(
      id: Value(id),
      toolId: Value(existing.toolId),
      title: title != null ? Value(title) : Value(existing.title),
      content: content != null ? Value(content) : Value(existing.content),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
      tags: tags != null ? Value(jsonEncode(tags)) : Value(existing.tags),
      sourceRecordIds: sourceRecordIds != null 
          ? Value(jsonEncode(sourceRecordIds)) 
          : Value(existing.sourceRecordIds),
      templateId: templateId != null ? Value(templateId) : Value(existing.templateId),
      usageCount: Value(existing.usageCount),
    );
    await _database.updateToolOutput(companion);
  }

  Future<void> incrementUsageCount(int id) async {
    await _database.updateToolOutputUsageCount(id);
  }

  Future<void> deleteToolOutput(int id) async {
    await _database.deleteToolOutputById(id);
  }

  Future<List<ToolOutputModel>> searchToolOutputs(String query) async {
    final outputs = await getAllToolOutputs();
    final lowerQuery = query.toLowerCase();
    return outputs.where((o) =>
      o.title.toLowerCase().contains(lowerQuery) ||
      o.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<int> getToolOutputCount() async {
    final outputs = await getAllToolOutputs();
    return outputs.length;
  }

  Future<List<ToolOutputModel>> queryToolOutputs(ToolOutputQuery query) async {
    var outputs = await getAllToolOutputs();

    if (query.toolId != null) {
      outputs = outputs.where((o) => o.toolId == query.toolId).toList();
    }

    if (query.searchQuery != null && query.searchQuery!.isNotEmpty) {
      final lowerQuery = query.searchQuery!.toLowerCase();
      outputs = outputs.where((o) => 
        o.title.toLowerCase().contains(lowerQuery) ||
        o.content.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    if (query.tags != null && query.tags!.isNotEmpty) {
      outputs = outputs.where((o) => 
        query.tags!.any((tag) => o.tags.contains(tag))
      ).toList();
    }

    if (query.dateRange != null) {
      outputs = outputs.where((o) => 
        !o.createdAt.isBefore(query.dateRange!.start) &&
        !o.createdAt.isAfter(query.dateRange!.end)
      ).toList();
    }

    return outputs;
  }

  ToolOutputModel _mapToModel(ToolOutput output) {
    return ToolOutputModel(
      id: output.id,
      toolId: output.toolId,
      title: output.title,
      content: output.content,
      createdAt: output.createdAt,
      updatedAt: output.updatedAt,
      tags: _parseTags(output.tags),
      sourceRecordIds: _parseSourceRecordIds(output.sourceRecordIds),
      templateId: output.templateId,
      usageCount: output.usageCount,
      isFavorite: output.isFavorite,
    );
  }

  Future<void> updateFavorite(int id, bool isFavorite) async {
    final existing = await _database.getToolOutputById(id);
    if (existing == null) return;
    
    final companion = ToolOutputsCompanion(
      id: Value(id),
      toolId: Value(existing.toolId),
      title: Value(existing.title),
      content: Value(existing.content),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
      tags: Value(existing.tags),
      sourceRecordIds: Value(existing.sourceRecordIds),
      templateId: Value(existing.templateId),
      usageCount: Value(existing.usageCount),
      isFavorite: Value(isFavorite),
    );
    await _database.updateToolOutput(companion);
  }

  List<String> _parseTags(String tagsString) {
    try {
      final dynamic decoded = jsonDecode(tagsString);
      if (decoded is List) {
        return decoded.whereType<String>().where((tag) => tag.isNotEmpty).toList();
      }
    } catch (e) {
      // 如果解析失败，返回空列表
    }
    return [];
  }

  List<int> _parseSourceRecordIds(String sourceRecordIdsString) {
    try {
      final dynamic decoded = jsonDecode(sourceRecordIdsString);
      if (decoded is List) {
        return decoded.whereType<int>().toList();
      }
    } catch (e) {
      // 如果解析失败，返回空列表
    }
    return [];
  }

}