import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_logger.dart';

class ExceptionHandlerService {
  static final ExceptionHandlerService _instance = ExceptionHandlerService._internal();
  
  factory ExceptionHandlerService() => _instance;
  
  ExceptionHandlerService._internal();

  final List<ErrorReport> _errorHistory = [];
  final int _maxHistorySize = 50;
  ValueNotifier<List<ErrorReport>> errorHistoryNotifier = ValueNotifier([]);
  
  void initialize() {
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final report = ErrorReport(
      error: details.exception,
      stackTrace: details.stack,
      context: details.context?.toString(),
      library: details.library,
      timestamp: DateTime.now(),
    );
    
    _addError(report);
    _logError(report);
    
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    final report = ErrorReport(
      error: error,
      stackTrace: stack,
      timestamp: DateTime.now(),
    );
    
    _addError(report);
    _logError(report);
    
    return true;
  }

  void _addError(ErrorReport report) {
    if (_errorHistory.length >= _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
    _errorHistory.add(report);
    errorHistoryNotifier.value = List.from(_errorHistory);
  }

  void _logError(ErrorReport report) {
    AppLogger().e('ExceptionHandler', '${report.error}\nStack: ${report.stackTrace}');
  }

  void handleException(Object error, {StackTrace? stackTrace, String? context}) {
    final report = ErrorReport(
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
      timestamp: DateTime.now(),
    );
    
    _addError(report);
    _logError(report);
  }

  List<ErrorReport> getErrorHistory() {
    return List.from(_errorHistory);
  }

  void clearErrorHistory() {
    _errorHistory.clear();
    errorHistoryNotifier.value = [];
  }

  void showErrorDialog(BuildContext context, Object error, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              const Text('Would you like to retry the operation?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ErrorReport {
  final Object error;
  final StackTrace stackTrace;
  final String? context;
  final String? library;
  final DateTime timestamp;

  ErrorReport({
    required this.error,
    required this.stackTrace,
    this.context,
    this.library,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'context': context,
      'library': library,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}