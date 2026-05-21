import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/record_repository.dart';
import 'app_logger.dart';

enum BackupContentType {
  records,
  apiConfigs,
}

class BackupOptions {
  final Set<BackupContentType> selectedTypes;
  final bool includeMedia;

  const BackupOptions({
    required this.selectedTypes,
    this.includeMedia = true,
  });

  bool get includeRecords => selectedTypes.contains(BackupContentType.records);
  bool get includeApiConfigs => selectedTypes.contains(BackupContentType.apiConfigs);
  bool get includeMediaFiles => includeRecords && includeMedia;

  static BackupOptions get full => const BackupOptions(
        selectedTypes: {
          BackupContentType.records,
          BackupContentType.apiConfigs,
        },
        includeMedia: true,
      );

  static BackupOptions get dataOnly => const BackupOptions(
        selectedTypes: {
          BackupContentType.records,
          BackupContentType.apiConfigs,
        },
        includeMedia: false,
      );

  static BackupOptions get recordsOnly => const BackupOptions(
        selectedTypes: {BackupContentType.records},
        includeMedia: false,
      );

  BackupOptions copyWith({
    Set<BackupContentType>? selectedTypes,
    bool? includeMedia,
  }) {
    return BackupOptions(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      includeMedia: includeMedia ?? this.includeMedia,
    );
  }
}

class BackupInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final int recordCount;
  final int fileSize;
  final String version;
  final BackupOptions options;

  BackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.recordCount,
    required this.fileSize,
    required this.version,
    BackupOptions? options,
  }) : options = options ?? BackupOptions.full;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'recordCount': recordCount,
        'fileSize': fileSize,
        'version': version,
        'options': {
          'selectedTypes': options.selectedTypes.map((t) => t.name).toList(),
          'includeMedia': options.includeMedia,
        },
      };

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as Map<String, dynamic>?;
    return BackupInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      recordCount: json['recordCount'] as int,
      fileSize: json['fileSize'] as int,
      version: json['version'] as String,
      options: optionsJson != null
          ? BackupOptions(
              selectedTypes: (optionsJson['selectedTypes'] as List<dynamic>?)
                      ?.map((e) => BackupContentType.values.firstWhere(
                            (t) => t.name == e,
                            orElse: () => BackupContentType.records,
                          ))
                      .toSet() ??
                  BackupOptions.full.selectedTypes,
              includeMedia: optionsJson['includeMedia'] as bool? ?? true,
            )
          : BackupOptions.full,
    );
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get contentDescription {
    final parts = <String>[];
    if (options.includeRecords) parts.add('记录');
    if (options.includeApiConfigs) parts.add('AI配置');
    if (options.includeMediaFiles) parts.add('媒体');
    return parts.join(' + ');
  }
}

class BackupResult {
  final bool success;
  final String? error;
  final BackupInfo? backupInfo;

  const BackupResult({
    required this.success,
    this.error,
    this.backupInfo,
  });
}

class RestoreResult {
  final bool success;
  final String? error;
  final int restoredRecordCount;

  const RestoreResult({
    required this.success,
    this.error,
    this.restoredRecordCount = 0,
  });
}

class BackupService {
  static const String _backupDirName = 'backups';
  static const String _backupIndexKey = 'backup_index_v2';
  static const String _backupVersion = '1.1.0';
  static const String _manifestFileName = 'manifest.json';
  static const String _databaseFileName = 'database.sqlite';
  static const String _prefsFileName = 'preferences.json';
  static const String _mediaDirName = 'media';

  static final List<String> _apiConfigKeys = [
    'api_config',
    'multi_api_config_v2',
    'transcription_config',
    'custom_ai_roles',
    'selected_ai_role',
    'custom_prompt_templates',
    'analysis_templates_v1',
    'auto_analysis_config',
  ];

  static Future<Directory> get _backupDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$_backupDirName');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  static Future<List<BackupInfo>> getBackupList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexJson = prefs.getString(_backupIndexKey);
      if (indexJson == null) return [];

      final List<dynamic> index = jsonDecode(indexJson);
      return index
          .map((e) => BackupInfo.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger().e('Backup', 'Failed to get backup list: $e');
      return [];
    }
  }

  static Future<BackupResult> createBackup({
    String? name,
    BackupOptions? options,
  }) async {
    try {
      final backupOptions = options ?? BackupOptions.full;
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      final backupName = name ?? '备份 ${DateTime.now().toString().substring(0, 19)}';
      final backupDir = await _backupDir;
      final tempDir = Directory('${backupDir.path}/$backupId');
      await tempDir.create(recursive: true);

      final database = AppDatabase();
      final repository = RecordRepository(database);

      final records = await repository.getAllRecords();
      final recordCount = backupOptions.includeRecords ? records.length : 0;

      final manifest = {
        'version': _backupVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'name': backupName,
        'recordCount': recordCount,
        'options': {
          'selectedTypes': backupOptions.selectedTypes.map((t) => t.name).toList(),
          'includeMedia': backupOptions.includeMedia,
        },
        'appVersion': '1.0.0',
      };

      await File('${tempDir.path}/$_manifestFileName')
          .writeAsString(jsonEncode(manifest));

      if (backupOptions.includeRecords || backupOptions.includeApiConfigs) {
        final dbPath = await AppDatabase.getDatabasePath();
        await File(dbPath).copy('${tempDir.path}/$_databaseFileName');
      }

      if (backupOptions.includeApiConfigs) {
        final prefs = await SharedPreferences.getInstance();
        final prefsData = <String, dynamic>{};

        for (final key in prefs.getKeys()) {
          if (key == _backupIndexKey) continue;

          if (_apiConfigKeys.contains(key)) {
            final value = prefs.get(key);
            if (value != null) {
              prefsData[key] = value;
            }
          }
        }

        if (prefsData.isNotEmpty) {
          await File('${tempDir.path}/$_prefsFileName')
              .writeAsString(jsonEncode(prefsData));
        }
      }

      if (backupOptions.includeMediaFiles) {
        final mediaDir = Directory('${tempDir.path}/$_mediaDirName');
        await mediaDir.create();

        for (final record in records) {
          if (record.audioPath != null) {
            final audioFile = File(record.audioPath!);
            if (await audioFile.exists()) {
              final fileName = record.audioPath!.split('/').last;
              await audioFile.copy('${mediaDir.path}/$fileName');
            }
          }
          if (record.imagePath != null) {
            final imageFile = File(record.imagePath!);
            if (await imageFile.exists()) {
              final fileName = record.imagePath!.split('/').last;
              await imageFile.copy('${mediaDir.path}/$fileName');
            }
          }
          for (final supplement in record.supplements) {
            if (supplement.type == 'audio' || supplement.type == 'image') {
              final file = File(supplement.content);
              if (await file.exists()) {
                final fileName = supplement.content.split('/').last;
                await file.copy('${mediaDir.path}/$fileName');
              }
            }
          }
        }
      }

      final archive = Archive();
      await _addDirectoryToArchive(archive, tempDir, '');

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) {
        await tempDir.delete(recursive: true);
        return BackupResult(success: false, error: '备份压缩失败');
      }

      final zipFile = File('${backupDir.path}/$backupId.zip');
      await zipFile.writeAsBytes(zipData);

      await tempDir.delete(recursive: true);

      final fileSize = await zipFile.length();

      final backupInfo = BackupInfo(
        id: backupId,
        name: backupName,
        createdAt: DateTime.now(),
        recordCount: recordCount,
        fileSize: fileSize,
        version: _backupVersion,
        options: backupOptions,
      );

      await _addToIndex(backupInfo);

      return BackupResult(success: true, backupInfo: backupInfo);
    } catch (e, stack) {
      AppLogger().e('Backup', 'Failed to create backup: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  static Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    await for (final entity in dir.list(recursive: false)) {
      final relativePath = basePath.isEmpty
          ? entity.path.split('/').last
          : '$basePath/${entity.path.split('/').last}';

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, relativePath);
      }
    }
  }

  static Future<RestoreResult> restoreBackup(
    String backupId, {
    BackupOptions? options,
  }) async {
    try {
      final backupDir = await _backupDir;
      final zipFile = File('${backupDir.path}/$backupId.zip');

      if (!await zipFile.exists()) {
        return const RestoreResult(
          success: false,
          error: '备份文件不存在',
        );
      }

      final tempDir = Directory('${backupDir.path}/restore_$backupId');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final outputFile = File('${tempDir.path}/${file.name}');
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }

      final manifestFile = File('${tempDir.path}/$_manifestFileName');
      if (!await manifestFile.exists()) {
        await tempDir.delete(recursive: true);
        return const RestoreResult(
          success: false,
          error: '无效的备份文件：缺少清单文件',
        );
      }

      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final version = manifest['version'] as String?;
      if (version == null || version != _backupVersion) {
        AppLogger().w('Backup', 'Version mismatch: $version vs $_backupVersion');
      }

      final manifestOptions = manifest['options'] as Map<String, dynamic>?;
      final backupOptions = manifestOptions != null
          ? BackupOptions(
              selectedTypes: (manifestOptions['selectedTypes'] as List<dynamic>?)
                      ?.map((e) => BackupContentType.values.firstWhere(
                            (t) => t.name == e,
                            orElse: () => BackupContentType.records,
                          ))
                      .toSet() ??
                  BackupOptions.full.selectedTypes,
              includeMedia: manifestOptions['includeMedia'] as bool? ?? true,
            )
          : BackupOptions.full;

      final restoreOptions = options ?? backupOptions;

      if (restoreOptions.includeRecords || restoreOptions.includeApiConfigs) {
        final dbBackupFile = File('${tempDir.path}/$_databaseFileName');
        if (await dbBackupFile.exists()) {
          final dbPath = await AppDatabase.getDatabasePath();
          final dbFile = File(dbPath);
          if (await dbFile.exists()) {
            await dbFile.delete();
          }
          await dbBackupFile.copy(dbPath);
        }
      }

      if (restoreOptions.includeApiConfigs) {
        final prefsFile = File('${tempDir.path}/$_prefsFileName');
        if (await prefsFile.exists()) {
          final prefsData =
              jsonDecode(await prefsFile.readAsString()) as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();

          for (final entry in prefsData.entries) {
            final key = entry.key;
            final value = entry.value;

            if (!_apiConfigKeys.contains(key)) continue;

            if (value is String) {
              await prefs.setString(key, value);
            } else if (value is int) {
              await prefs.setInt(key, value);
            } else if (value is double) {
              await prefs.setDouble(key, value);
            } else if (value is bool) {
              await prefs.setBool(key, value);
            } else if (value is List) {
              await prefs.setStringList(
                  key, value.whereType<String>().toList());
            }
          }
        }
      }

      if (restoreOptions.includeMediaFiles) {
        final mediaDir = Directory('${tempDir.path}/$_mediaDirName');
        if (await mediaDir.exists()) {
          final appDir = await getApplicationDocumentsDirectory();
          final targetMediaDir = Directory('${appDir.path}/media');
          if (!await targetMediaDir.exists()) {
            await targetMediaDir.create(recursive: true);
          }

          await for (final entity in mediaDir.list()) {
            if (entity is File) {
              final fileName = entity.path.split('/').last;
              await entity.copy('${targetMediaDir.path}/$fileName');
            }
          }
        }
      }

      await tempDir.delete(recursive: true);

      final restoredCount = manifest['recordCount'] as int? ?? 0;

      return RestoreResult(
        success: true,
        restoredRecordCount: restoredCount,
      );
    } catch (e, stack) {
      AppLogger().e('Backup', 'Failed to restore backup: $e');
      return RestoreResult(success: false, error: e.toString());
    }
  }

  static Future<bool> deleteBackup(String backupId) async {
    try {
      final backupDir = await _backupDir;
      final zipFile = File('${backupDir.path}/$backupId.zip');
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final index = await getBackupList();
      final newIndex = index.where((b) => b.id != backupId).toList();
      await _saveIndex(newIndex);

      return true;
    } catch (e) {
      AppLogger().e('Backup', 'Failed to delete backup: $e');
      return false;
    }
  }

  static Future<String?> exportBackup(String backupId) async {
    try {
      final backupDir = await _backupDir;
      final zipFile = File('${backupDir.path}/$backupId.zip');
      if (!await zipFile.exists()) return null;

      return zipFile.path;
    } catch (e) {
      AppLogger().e('Backup', 'Failed to export backup: $e');
      return null;
    }
  }

  static Future<RestoreResult> importBackup(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        return const RestoreResult(
          success: false,
          error: '文件不存在',
        );
      }

      final backupDir = await _backupDir;
      final backupId = 'imported_${DateTime.now().millisecondsSinceEpoch}';
      final zipFile = File('${backupDir.path}/$backupId.zip');
      await sourceFile.copy(zipFile.path);

      final fileSize = await zipFile.length();

      final tempDir = Directory('${backupDir.path}/import_$backupId');
      await tempDir.create(recursive: true);

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile && file.name == _manifestFileName) {
          final manifest =
              jsonDecode(utf8.decode(file.content as List<int>)) as Map<String, dynamic>;
          final recordCount = manifest['recordCount'] as int? ?? 0;
          final name = manifest['name'] as String? ?? '导入的备份';

          final optionsJson = manifest['options'] as Map<String, dynamic>?;
          final options = optionsJson != null
              ? BackupOptions(
                  selectedTypes: (optionsJson['selectedTypes'] as List<dynamic>?)
                          ?.map((e) => BackupContentType.values.firstWhere(
                                (t) => t.name == e,
                                orElse: () => BackupContentType.records,
                              ))
                          .toSet() ??
                      BackupOptions.full.selectedTypes,
                  includeMedia: optionsJson['includeMedia'] as bool? ?? true,
                )
              : BackupOptions.full;

          final backupInfo = BackupInfo(
            id: backupId,
            name: name,
            createdAt: DateTime.now(),
            recordCount: recordCount,
            fileSize: fileSize,
            version: manifest['version'] as String? ?? _backupVersion,
            options: options,
          );

          await _addToIndex(backupInfo);
          await tempDir.delete(recursive: true);

          return RestoreResult(
            success: true,
            restoredRecordCount: recordCount,
          );
        }
      }

      await tempDir.delete(recursive: true);
      await zipFile.delete();
      return const RestoreResult(
        success: false,
        error: '无效的备份文件',
      );
    } catch (e, stack) {
      AppLogger().e('Backup', 'Failed to import backup: $e');
      return RestoreResult(success: false, error: e.toString());
    }
  }

  static Future<void> _addToIndex(BackupInfo backupInfo) async {
    final index = await getBackupList();
    index.removeWhere((b) => b.id == backupInfo.id);
    index.add(backupInfo);
    await _saveIndex(index);
  }

  static Future<void> _saveIndex(List<BackupInfo> index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _backupIndexKey,
      jsonEncode(index.map((b) => b.toJson()).toList()),
    );
  }
}
