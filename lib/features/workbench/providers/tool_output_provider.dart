
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../../../data/models/tool_output_model.dart';

final toolOutputStateProvider = StateNotifierProvider<ToolOutputStateNotifier, ToolOutputState>(
  (ref) => ToolOutputStateNotifier(ref.watch(toolOutputRepositoryProvider)),
);

class ToolOutputState {
  final List<ToolOutputModel> outputs;
  final bool isLoading;
  final String? selectedToolId;

  const ToolOutputState({
    required this.outputs,
    required this.isLoading,
    this.selectedToolId,
  });

  ToolOutputState copyWith({
    List<ToolOutputModel>? outputs,
    bool? isLoading,
    String? selectedToolId,
  }) {
    return ToolOutputState(
      outputs: outputs ?? this.outputs,
      isLoading: isLoading ?? this.isLoading,
      selectedToolId: selectedToolId ?? this.selectedToolId,
    );
  }
}

class ToolOutputStateNotifier extends StateNotifier<ToolOutputState> {
  final ToolOutputRepository _repository;

  ToolOutputStateNotifier(this._repository)
      : super(const ToolOutputState(outputs: [], isLoading: true)) {
    _loadAllOutputs();
  }

  Future<void> _loadAllOutputs() async {
    state = state.copyWith(isLoading: true);
    try {
      final outputs = await _repository.getAllToolOutputs();
      state = state.copyWith(outputs: outputs, isLoading: false);
    } catch (e) {
      state = state.copyWith(outputs: [], isLoading: false);
    }
  }

  Future<void> loadByToolId(String toolId) async {
    state = state.copyWith(isLoading: true, selectedToolId: toolId);
    try {
      final outputs = await _repository.getToolOutputsByToolId(toolId);
      state = state.copyWith(outputs: outputs, isLoading: false);
    } catch (e) {
      state = state.copyWith(outputs: [], isLoading: false);
    }
  }

  Future<void> refresh() async {
    if (state.selectedToolId != null) {
      await loadByToolId(state.selectedToolId!);
    } else {
      await _loadAllOutputs();
    }
  }

  Future<String> createOutput({
    required String toolId,
    required String title,
    required String content,
    List<String> tags = const [],
    List<int> sourceRecordIds = const [],
    String? templateId,
  }) async {
    final id = await _repository.createToolOutput(
      toolId: toolId,
      title: title,
      content: content,
      tags: tags,
      sourceRecordIds: sourceRecordIds,
      templateId: templateId,
    );
    await refresh();
    return id;
  }

  Future<void> updateOutput({
    required String id,
    String? title,
    String? content,
    List<String>? tags,
    List<int>? sourceRecordIds,
    String? templateId,
  }) async {
    await _repository.updateToolOutput(
      id: id,
      title: title,
      content: content,
      tags: tags,
      sourceRecordIds: sourceRecordIds,
      templateId: templateId,
    );
    await refresh();
  }

  Future<void> deleteOutput(String id) async {
    await _repository.deleteToolOutput(id);
    await refresh();
  }

  Future<void> incrementUsageCount(String id) async {
    await _repository.incrementUsageCount(id);
    await refresh();
  }

  Future<List<ToolOutputModel>> search(String query) async {
    return await _repository.searchToolOutputs(query);
  }

  Future<List<ToolOutputModel>> query(ToolOutputQuery query) async {
    return await _repository.queryToolOutputs(query);
  }
}