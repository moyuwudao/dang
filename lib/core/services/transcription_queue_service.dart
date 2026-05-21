import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/record_model.dart';
import '../../data/repositories/record_repository.dart';
import '../services/transcription_service.dart';
import 'app_logger.dart';
import 'storage_service.dart';
import 'role_service.dart';

final transcriptionQueueProvider = Provider<TranscriptionQueueService>((ref) {
  final service = TranscriptionQueueService(
    ref.watch(transcriptionServiceProvider),
    ref.watch(recordRepositoryProvider),
    ref,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class TranscriptionQueueService {
  final TranscriptionService _transcriptionService;
  final RecordRepository _recordRepository;
  final Ref _ref;
  
  final List<int> _queue = [];
  bool _isProcessing = false;
  StreamSubscription? _pendingRecordsSubscription;

  TranscriptionQueueService(this._transcriptionService, this._recordRepository, this._ref);

  void start() {
    _resetStuckRecords();
    _listenForPendingRecords();
    _processNext();
  }

  /// 重置卡住的记录（上次异常退出遗留的 processing 状态）
  Future<void> _resetStuckRecords() async {
    try {
      final records = await _recordRepository.getAllRecords();
      final stuckRecords = records.where((r) =>
        r.transcriptionStatus == TranscriptionStatus.processing
      ).toList();

      if (stuckRecords.isNotEmpty) {
        AppLogger().w('TranscriptionQueue', 'Found ${stuckRecords.length} stuck records, resetting to pending');
        for (final record in stuckRecords) {
          await _recordRepository.updateTranscriptionStatus(
            record.id,
            TranscriptionStatus.pending,
            null,
          );
        }
      }
    } catch (e) {
      AppLogger().e('TranscriptionQueue', 'Failed to reset stuck records: $e');
    }
  }

  void stop() {
    _pendingRecordsSubscription?.cancel();
    _pendingRecordsSubscription = null;
    _isProcessing = false;
  }

  void dispose() {
    _pendingRecordsSubscription?.cancel();
    _pendingRecordsSubscription = null;
    _isProcessing = false;
    _queue.clear();
  }

  void _listenForPendingRecords() {
    _pendingRecordsSubscription?.cancel();
    
    _pendingRecordsSubscription = _recordRepository.watchAllRecords().listen((records) {
      final pendingIds = records
          .where((r) => r.transcriptionStatus == TranscriptionStatus.pending)
          .map((r) => r.id)
          .toList();
      
      for (final id in pendingIds) {
        if (!_queue.contains(id) && id != _queue.firstOrNull) {
          _queue.add(id);
        }
      }
      
      _processNext();
    });
  }

  Future<void> addToQueue(int recordId) async {
    if (!_queue.contains(recordId)) {
      _queue.add(recordId);
    }
    await _processNext();
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    final recordId = _queue.removeAt(0);

    try {
      AppLogger().i('TranscriptionQueue', 'Processing: recordId=$recordId');
      
      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.processing,
        null,
      );

      final record = await _recordRepository.getRecordById(recordId);
      if (record == null) {
        throw Exception('记录不存在');
      }
      if (record.audioPath == null || record.audioPath!.isEmpty) {
        throw Exception('音频文件路径不存在');
      }

      final result = await _transcriptionService.transcribeAudio(
        record.audioPath!,
        onProgress: (step, detail) {
          AppLogger().d('TranscriptionQueue', 'Progress [$step]: $detail');
        },
      );

      await _recordRepository.updateRecordContent(recordId, result);
      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.success,
        null,
      );

      AppLogger().i('TranscriptionQueue', 'Transcription completed: recordId=$recordId');

      // 转写成功后，检查是否需要自动AI分析
      await _triggerAutoAnalysis(recordId);
    } catch (e) {
      AppLogger().e('TranscriptionQueue', 'Transcription failed: recordId=$recordId, error=$e');
      
      await _recordRepository.updateTranscriptionStatus(
        recordId,
        TranscriptionStatus.failed,
        e.toString(),
      );
    } finally {
      _isProcessing = false;
      _processNext();
    }
  }

  Future<void> _triggerAutoAnalysis(int recordId) async {
    try {
      final config = await StorageService.getAutoAnalysisConfig();
      if (!config.enabled || config.defaultRoleId.isEmpty) {
        return;
      }

      final roles = await RoleService.getAllRoles();
      if (roles.isEmpty) {
        return;
      }
      final role = roles.firstWhere(
        (r) => r.id == config.defaultRoleId,
        orElse: () => roles.first,
      );

      final record = await _recordRepository.getRecordById(recordId);
      if (record == null || (record.content ?? '').isEmpty) {
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('=== 原始转写文本 ===');
      buffer.writeln(record.content ?? '');

      if (record.supplements.isNotEmpty) {
        buffer.writeln('\n\n=== 补充内容 ===');
        for (final supplement in record.supplements) {
          buffer.writeln(
              '\n--- ${supplement.type == 'audio' ? '录音补充' : supplement.type == 'image' ? '图片补充' : '文本补充'} [${supplement.createdAt}] ---');
          if (supplement.type == 'text') {
            buffer.writeln(supplement.content);
          } else if (supplement.transcribedContent != null &&
              supplement.transcribedContent!.isNotEmpty) {
            buffer.writeln(supplement.transcribedContent);
          }
        }
      }

      final result = await _transcriptionService.analyzeText(
        buffer.toString(),
        systemPrompt: role.systemPrompt,
      );

      final analysisResult = AiAnalysisResult(
        roleId: role.id,
        roleName: role.name,
        content: result,
        createdAt: DateTime.now(),
      );

      await _recordRepository.addAiAnalysis(recordId, analysisResult);
      AppLogger().i('TranscriptionQueue', 'Auto analysis completed for record $recordId');
    } catch (e) {
      AppLogger().e('TranscriptionQueue', 'Auto analysis failed for record $recordId: $e');
    }
  }

  int get queueLength => _queue.length;
  bool get isProcessing => _isProcessing;
}
