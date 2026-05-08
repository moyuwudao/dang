import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

final webdavSyncServiceProvider = Provider((ref) => WebDAVSyncService(ref));

class WebDAVConfig {
  final String url;
  final String username;
  final String password;
  final String remotePath;

  WebDAVConfig({
    required this.url,
    required this.username,
    required this.password,
    this.remotePath = '/changji',
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'username': username,
      'password': password,
      'remotePath': remotePath,
    };
  }

  factory WebDAVConfig.fromJson(Map<String, dynamic> json) {
    return WebDAVConfig(
      url: json['url'],
      username: json['username'],
      password: json['password'],
      remotePath: json['remotePath'] ?? '/changji',
    );
  }
}

class SyncStatus {
  final bool isSyncing;
  final String lastSyncTime;
  final int recordsSynced;
  final String? error;

  SyncStatus({
    required this.isSyncing,
    required this.lastSyncTime,
    required this.recordsSynced,
    this.error,
  });
}

class WebDAVSyncService {
  final Ref ref;
  WebDAVConfig? _config;
  bool _isSyncing = false;
  String _lastSyncTime = '从未同步';
  int _recordsSynced = 0;

  WebDAVSyncService(this.ref);

  void setConfig(WebDAVConfig config) {
    _config = config;
  }

  WebDAVConfig? get config => _config;

  SyncStatus get status => SyncStatus(
        isSyncing: _isSyncing,
        lastSyncTime: _lastSyncTime,
        recordsSynced: _recordsSynced,
      );

  webdav.Client _createClient() {
    final client = webdav.newClient(
      _config!.url,
      user: _config!.username,
      password: _config!.password,
      debug: false,
    );
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(30000);
    return client;
  }

  Future<bool> testConnection() async {
    if (_config == null) return false;

    try {
      final client = _createClient();
      await client.ping();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> sync() async {
    if (_isSyncing || _config == null) return;

    _isSyncing = true;

    try {
      await _ensureRemoteDirectory();

      final localRecords = await ref.read(recordRepositoryProvider).getAllRecords();
      final remoteRecords = await _fetchRemoteRecords();

      await _uploadNewRecords(localRecords, remoteRecords);
      await _downloadNewRecords(localRecords, remoteRecords);
      await _syncDeletions(localRecords, remoteRecords);

      _lastSyncTime = _formatDateTime(DateTime.now());
      _recordsSynced = localRecords.length;
    } catch (e) {
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> backupToWebDAV() async {
    if (_config == null) return;

    final records = await ref.read(recordRepositoryProvider).getAllRecords();
    final data = {
      'records': records.map((r) => r.toJson()).toList(),
      'backupTime': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    final content = utf8.encode(json.encode(data));
    final fileName = 'changji_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final client = _createClient();

    await client.write('${_config!.remotePath}/$fileName', content);
  }

  Future<void> restoreFromWebDAV(String fileName) async {
    if (_config == null) return;

    final client = _createClient();
    final data = await client.read('${_config!.remotePath}/$fileName');
    final jsonStr = utf8.decode(data);
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final recordsData = decoded['records'] as List<dynamic>;

    final repository = ref.read(recordRepositoryProvider);
    for (final recordData in recordsData) {
      final record = RecordModel.fromJson(recordData as Map<String, dynamic>);
      await repository.createRecord(
        type: record.type,
        content: record.content,
        audioPath: record.audioPath,
        imagePath: record.imagePath,
        tags: record.tags,
        transcriptionStatus: record.transcriptionStatus,
      );
    }
  }

  Future<List<RecordModel>> _fetchRemoteRecords() async {
    try {
      final client = _createClient();
      final data = await client.read('${_config!.remotePath}/records.json');
      final jsonStr = utf8.decode(data);
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return (decoded['records'] as List<dynamic>)
          .map((r) => RecordModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _uploadNewRecords(List<RecordModel> local, List<RecordModel> remote) async {
    final remoteIds = remote.map((r) => r.id).toSet();
    final newRecords = local.where((r) => !remoteIds.contains(r.id)).toList();

    if (newRecords.isEmpty) return;

    final allRemoteRecords = [...remote, ...newRecords];
    final data = {'records': allRemoteRecords.map((r) => r.toJson()).toList()};
    final content = utf8.encode(json.encode(data));
    final client = _createClient();

    await client.write('${_config!.remotePath}/records.json', content);
  }

  Future<void> _downloadNewRecords(List<RecordModel> local, List<RecordModel> remote) async {
    final localIds = local.map((r) => r.id).toSet();
    final newRecords = remote.where((r) => !localIds.contains(r.id)).toList();

    final repository = ref.read(recordRepositoryProvider);
    for (final record in newRecords) {
      await repository.createRecord(
        type: record.type,
        content: record.content,
        audioPath: record.audioPath,
        imagePath: record.imagePath,
        tags: record.tags,
        transcriptionStatus: record.transcriptionStatus,
      );
    }
  }

  Future<void> _syncDeletions(List<RecordModel> local, List<RecordModel> remote) async {
    final localIds = local.map((r) => r.id).toSet();
    final deletedRecords = remote.where((r) => !localIds.contains(r.id)).toList();

    if (deletedRecords.isEmpty) return;

    final remainingRecords = remote.where((r) => localIds.contains(r.id)).toList();
    final data = {'records': remainingRecords.map((r) => r.toJson()).toList()};
    final content = utf8.encode(json.encode(data));
    final client = _createClient();

    await client.write('${_config!.remotePath}/records.json', content);
  }

  Future<void> _ensureRemoteDirectory() async {
    final client = _createClient();
    try {
      await client.mkdirAll(_config!.remotePath);
    } catch (e) {
      // Directory may already exist, ignore error
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
