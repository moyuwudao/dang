
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../../../data/models/tool_output_model.dart';

final toolOutputStateProvider = AsyncNotifierProvider<ToolOutputStateNotifier, ToolOutputState>(
  () => ToolOutputStateNotifier(),
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

class ToolOutputStateNotifier extends AsyncNotifier<ToolOutputState> {
  ToolOutputRepository get _repository => ref.read(toolOutputRepositoryProvider);

  @override
  Future<ToolOutputState> build() async {
    return _loadAllOutputs();
  }

  Future<ToolOutputState> _loadAllOutputs() async {
    try {
      final outputs = await _repository.getAllToolOutputs();
      return ToolOutputState(outputs: outputs, isLoading: false);
    } catch (e) {
      return const ToolOutputState(outputs: [], isLoading: false);
    }
  }

  Future<void> loadByToolId(String toolId) async {
    state = const AsyncLoading();
    try {
      final outputs = await _repository.getToolOutputsByToolId(toolId);
      state = AsyncData(ToolOutputState(outputs: outputs, isLoading: false, selectedToolId: toolId));
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    if (currentState?.selectedToolId != null) {
      await loadByToolId(currentState!.selectedToolId!);
    } else {
      state = AsyncData(await _loadAllOutputs());
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
