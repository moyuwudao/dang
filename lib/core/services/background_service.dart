import 'dart:async';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> scheduleTranscription(int recordId) async {
    // TODO: 实现前台转写逻辑
  }

  Future<void> scheduleRetryFailedTranscriptions() async {
    // TODO: 实现批量重试逻辑
  }

  Future<void> cancelTask(String taskId) async {
    // TODO: 实现取消任务逻辑
  }
}
