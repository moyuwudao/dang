import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelString {
    switch (level) {
      case LogLevel.debug:
        return 'D';
      case LogLevel.info:
        return 'I';
      case LogLevel.warning:
        return 'W';
      case LogLevel.error:
        return 'E';
    }
  }

  String get displayText => '[$formattedTime] [$levelString/$tag] $message';
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const int _maxEntries = 100;
  final List<LogEntry> _entries = [];
  final List<void Function(LogEntry)> _listeners = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void addListener(void Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  void _notify(LogEntry entry) {
    for (final listener in _listeners) {
      try {
        listener(entry);
      } catch (e) {
        debugPrint('AppLogger: 监听器回调异常: $e');
      }
    }
  }

  void _addEntry(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    _notify(entry);
  }

  void d(String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.debug,
      tag: tag,
      message: message,
    );
    _addEntry(entry);
    debugPrint(entry.displayText);
  }

  void i(String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      tag: tag,
      message: message,
    );
    _addEntry(entry);
    debugPrint(entry.displayText);
  }

  void w(String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      tag: tag,
      message: message,
    );
    _addEntry(entry);
    debugPrint(entry.displayText);
  }

  void e(String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      tag: tag,
      message: message,
    );
    _addEntry(entry);
    debugPrint(entry.displayText);
  }

  void clear() {
    _entries.clear();
  }

  String exportAll() {
    return _entries.map((e) => e.displayText).join('\n');
  }

  List<LogEntry> filterByLevel(LogLevel level) {
    return _entries.where((e) => e.level.index >= level.index).toList();
  }

  List<LogEntry> filterByTag(String tag) {
    return _entries.where((e) => e.tag == tag).toList();
  }

  List<LogEntry> search(String keyword) {
    final lower = keyword.toLowerCase();
    return _entries.where((e) =>
      e.message.toLowerCase().contains(lower) ||
      e.tag.toLowerCase().contains(lower)
    ).toList();
  }
}
