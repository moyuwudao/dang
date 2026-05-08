import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class PermissionService {
  static Future<PermissionStatus> checkPermission(Permission permission) async {
    final status = await permission.status;
    return _mapStatus(status);
  }

  static Future<PermissionStatus> requestPermission(Permission permission) async {
    final status = await permission.request();
    return _mapStatus(status);
  }

  static Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    final statuses = await permissions.request();
    return statuses.map((key, value) => MapEntry(key, _mapStatus(value)));
  }

  static PermissionStatus _mapStatus(permission_handler.PermissionStatus status) {
    switch (status) {
      case permission_handler.PermissionStatus.granted:
        return PermissionStatus.granted;
      case permission_handler.PermissionStatus.denied:
        return PermissionStatus.denied;
      case permission_handler.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case permission_handler.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      default:
        return PermissionStatus.denied;
    }
  }

  static bool shouldShowRationale(Permission permission) async {
    return await permission.shouldShowRequestRationale;
  }

  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Failed to open app settings: $e');
    }
  }

  static Future<bool> ensurePermissions(List<Permission> permissions) async {
    final statuses = await requestPermissions(permissions);
    
    for (final status in statuses.values) {
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> ensureMicrophonePermission() async {
    return await ensurePermissions([Permission.microphone]);
  }

  static Future<bool> ensureStoragePermission() async {
    return await ensurePermissions([Permission.storage]);
  }

  static Future<bool> ensureCameraPermission() async {
    return await ensurePermissions([Permission.camera]);
  }

  static Future<bool> ensureAllRequiredPermissions() async {
    return await ensurePermissions([
      Permission.microphone,
      Permission.storage,
    ]);
  }

  static PermissionStatus getStatusFromResult(bool granted) {
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }
}

class PermissionDeniedException implements Exception {
  final Permission permission;
  final PermissionStatus status;
  final String message;

  PermissionDeniedException({
    required this.permission,
    required this.status,
    required this.message,
  });

  @override
  String toString() => 'PermissionDeniedException: $message (status: $status)';
}