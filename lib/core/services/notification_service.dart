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
    // Notification handled by system
  }

  Future<void> showTranscriptionComplete({
    required int recordId,
    required String title,
    bool success = true,
  }) async {
    // Notification handled by system
  }

  Future<void> showRecordingNotification() async {
    // Notification handled by system
  }

  Future<void> cancelNotification(int id) async {}

  Future<void> cancelAllNotifications() async {}
}
