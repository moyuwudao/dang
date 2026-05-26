import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
  File? _logFile;
  bool _fileInitialized = false;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  Future<void> _ensureFile() async {
    if (_fileInitialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/app.log');
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      } else {
        await _loadFromFile();
      }
      _fileInitialized = true;
    } catch (e) {
      debugPrint('AppLogger: 初始化日志文件失败: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      if (_logFile == null) return;
      final content = await _logFile!.readAsString();
      final lines = content.split('\n').where((l) => l.isNotEmpty).toList();
      final loaded = lines.length > _maxEntries
          ? lines.sublist(lines.length - _maxEntries)
          : lines;
      for (final line in loaded) {
        final entry = _parseLogLine(line);
        if (entry != null) _entries.add(entry);
      }
    } catch (e) {
      debugPrint('AppLogger: 从文件加载日志失败: $e');
    }
  }

  LogEntry? _parseLogLine(String line) {
    try {
      final match = RegExp(r'\[(\d{2}):(\d{2}):(\d{2})\.(\d{3})\] \[([DIWE])\/([^\]]+)\] (.+)').firstMatch(line);
      if (match == null) return null;
      final h = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final s = int.parse(match.group(3)!);
      final ms = int.parse(match.group(4)!);
      final levelStr = match.group(5)!;
      final tag = match.group(6)!;
      final message = match.group(7)!;
      final now = DateTime.now();
      final timestamp = DateTime(now.year, now.month, now.day, h, m, s, ms);
      final level = switch (levelStr) {
        'D' => LogLevel.debug,
        'I' => LogLevel.info,
        'W' => LogLevel.warning,
        'E' => LogLevel.error,
        _ => LogLevel.debug,
      };
      return LogEntry(timestamp: timestamp, level: level, tag: tag, message: message);
    } catch (e) {
      return null;
    }
  }

  Future<void> _writeToFile(String text) async {
    await _ensureFile();
    if (_logFile != null) {
      try {
        await _logFile!.writeAsString('$text\n', mode: FileMode.append);
      } catch (e) {
        debugPrint('AppLogger: 写入日志文件失败: $e');
      }
    }
  }

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
    _writeToFile(entry.displayText);
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
    _ensureFile().then((_) {
      if (_logFile != null) {
        _logFile!.writeAsString('');
      }
    });
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
