import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/record_model.dart';
import 'app_logger.dart';

class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final String? recordId;
  final bool isCompleted;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledTime,
    this.recordId,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'recordId': recordId,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Reminder fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      recordId: json['recordId'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ReminderService {
  static const String _remindersKey = 'reminders';
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<Reminder> _reminders = [];
  Timer? _checkTimer;

  Future<void> init() async {
    await _initializeNotifications();
    await _loadReminders();
    _startReminderChecker();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);
    
    if (remindersJson != null) {
      try {
        final data = (jsonDecode(remindersJson) as List);
        _reminders.clear();
        _reminders.addAll(data.map((item) => Reminder.fromJson(item)).toList());
        
        _reminders.removeWhere((r) => r.isCompleted || r.scheduledTime.isBefore(DateTime.now()));
        
        await _saveReminders();
      } catch (e) {
        AppLogger().e('Reminder', 'Failed to load reminders: $e');
      }
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, jsonString);
  }

  void _startReminderChecker() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkReminders();
    });
    _checkReminders();
  }

  Future<void> _checkReminders() async {
    final now = DateTime.now();
    
    for (final reminder in _reminders) {
      if (!reminder.isCompleted && 
          reminder.scheduledTime.isBefore(now.add(const Duration(minutes: 1))) &&
          reminder.scheduledTime.isAfter(now.subtract(const Duration(minutes: 1)))) {
        await _showNotification(reminder);
        await markAsCompleted(reminder.id);
      }
    }
  }

  Future<void> _showNotification(Reminder reminder) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Reminders for todo items',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      int.parse(reminder.id),
      reminder.title,
      reminder.description,
      notificationDetails,
    );
  }

  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _saveReminders();
  }

  Future<void> markAsCompleted(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isCompleted: true);
      await _saveReminders();
    }
  }

  Future<void> removeReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
  }

  List<Reminder> getActiveReminders() {
    return _reminders.where((r) => !r.isCompleted).toList();
  }

  List<Reminder> getRemindersForRecord(String recordId) {
    return _reminders.where((r) => r.recordId == recordId && !r.isCompleted).toList();
  }

  Future<void> scheduleReminderFromTodo(TodoItem todo) async {
    if (todo.dueDate != null) {
      final reminder = Reminder(
        id: todo.id,
        title: todo.text,
        description: todo.priority != null ? '优先级: ${_priorityToString(todo.priority!)}' : null,
        scheduledTime: todo.dueDate!,
        recordId: todo.recordId,
        createdAt: DateTime.now(),
      );
      await addReminder(reminder);
    }
  }

  String _priorityToString(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return '高';
      case TodoPriority.medium:
        return '中';
      case TodoPriority.low:
        return '低';
    }
  }

  Future<void> dispose() async {
    _checkTimer?.cancel();
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});