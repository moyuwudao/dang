import 'dart:async';
import 'package:flutter/material.dart';

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
    debugPrint('安排转写任务: $recordId');
    // TODO: 实现前台转写逻辑
  }

  Future<void> scheduleRetryFailedTranscriptions() async {
    debugPrint('安排重试失败转写任务');
    // TODO: 实现批量重试逻辑
  }

  Future<void> cancelTask(String taskId) async {
    debugPrint('取消任务: $taskId');
  }
}
