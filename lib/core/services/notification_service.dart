import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> showTranscriptionProgress({
    required int recordId,
    required String title,
    required int progress,
    required int total,
  }) async {
    debugPrint('转写进度: $title ($progress/$total)');
  }

  Future<void> showTranscriptionComplete({
    required int recordId,
    required String title,
    bool success = true,
  }) async {
    debugPrint('转写完成: $title - ${success ? "成功" : "失败"}');
  }

  Future<void> showRecordingNotification() async {
    debugPrint('正在录音...');
  }

  Future<void> cancelNotification(int id) async {}

  Future<void> cancelAllNotifications() async {}
}
