import 'dart:async';
import 'package:flutter/foundation.dart';

class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final List<Type> retryOnExceptions;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryOnExceptions = const [],
  });

  static const defaultConfig = RetryConfig();
  static const aggressiveConfig = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 15),
  );
}

class NetworkRetryService {
  static final NetworkRetryService _instance = NetworkRetryService._internal();
  
  factory NetworkRetryService() => _instance;
  
  NetworkRetryService._internal();

  final Map<String, int> _retryCounts = {};
  final Map<String, DateTime> _lastRetryTimes = {};

  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.defaultConfig,
    String? operationKey,
    void Function(int attempt, Duration delay)? onRetry,
    bool Function(Object error)? shouldRetry,
  }) async {
    final key = operationKey ?? operation.hashCode.toString();
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt <= config.maxRetries) {
      try {
        final result = await operation();
        _resetRetryCount(key);
        return result;
      } catch (error) {
        attempt++;
        
        if (attempt > config.maxRetries) {
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        if (config.retryOnExceptions.isNotEmpty) {
          final errorType = error.runtimeType;
          final shouldRetryOnType = config.retryOnExceptions.any(
            (type) => errorType == type || errorType.isSubtypeOf(type),
          );
          if (!shouldRetryOnType) {
            rethrow;
          }
        }

        onRetry?.call(attempt, delay);
        
        await Future.delayed(delay);
        
        delay = (delay * config.backoffMultiplier).clamp(
          config.initialDelay,
          config.maxDelay,
        );
        
        _updateRetryCount(key);
      }
    }

    throw Exception('Max retries exceeded');
  }

  void _updateRetryCount(String key) {
    _retryCounts[key] = (_retryCounts[key] ?? 0) + 1;
    _lastRetryTimes[key] = DateTime.now();
  }

  void _resetRetryCount(String key) {
    _retryCounts.remove(key);
    _lastRetryTimes.remove(key);
  }

  int getRetryCount(String key) {
    return _retryCounts[key] ?? 0;
  }

  DateTime? getLastRetryTime(String key) {
    return _lastRetryTimes[key];
  }

  void resetAllRetries() {
    _retryCounts.clear();
    _lastRetryTimes.clear();
  }
}

extension TypeCheck on Type {
  bool isSubtypeOf(Type other) {
    if (this == other) return true;
    
    try {
      final thisType = this.toString();
      final otherType = other.toString();
      
      if (thisType.startsWith('$other<') || thisType.startsWith('$other ')) {
        return true;
      }
      
      return false;
    } catch (_) {
      return false;
    }
  }
}