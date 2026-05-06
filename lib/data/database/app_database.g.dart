// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// DriftDatabaseGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Record extends DataClass implements Insertable<Record> {
  final int id;
  final String type;
  final String? content;
  final String? audioPath;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String tags;
  final String transcriptionStatus;
  final String? transcriptionError;
  final bool isFavorite;
  const Record(
      {required this.id,
      required this.type,
      this.content,
      this.audioPath,
      this.imagePath,
      required this.createdAt,
      required this.updatedAt,
      required this.tags,
      required this.transcriptionStatus,
      this.transcriptionError,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['tags'] = Variable<String>(tags);
    map['transcription_status'] = Variable<String>(transcriptionStatus);
    if (!nullToAbsent || transcriptionError != null) {
      map['transcription_error'] = Variable<String>(transcriptionError);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  factory Record.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Record(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      tags: serializer.fromJson<String>(json['tags']),
      transcriptionStatus:
          serializer.fromJson<String>(json['transcriptionStatus']),
      transcriptionError:
          serializer.fromJson<String?>(json['transcriptionError']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'audioPath': serializer.toJson<String?>(audioPath),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'tags': serializer.toJson<String>(tags),
      'transcriptionStatus': serializer.toJson<String>(transcriptionStatus),
      'transcriptionError': serializer.toJson<String?>(transcriptionError),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  Record copyWith(
          {int? id,
          String? type,
          Value<String?> content = const Value.absent(),
          Value<String?> audioPath = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          String? tags,
          String? transcriptionStatus,
          Value<String?> transcriptionError = const Value.absent(),
          bool? isFavorite}) =>
      Record(
        id: id ?? this.id,
        type: type ?? this.type,
        content: content.present ? content.value : this.content,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tags: tags ?? this.tags,
        transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
        transcriptionError: transcriptionError.present
            ? transcriptionError.value
            : this.transcriptionError,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  @override
  String toString() {
    return (StringBuffer('Record(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('audioPath: $audioPath, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('transcriptionError: $transcriptionError, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, content, audioPath, imagePath,
      createdAt, updatedAt, tags, transcriptionStatus, transcriptionError, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Record &&
          other.id == this.id &&
          other.type == this.type &&
          other.content == this.content &&
          other.audioPath == this.audioPath &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tags == this.tags &&
          other.transcriptionStatus == this.transcriptionStatus &&
          other.transcriptionError == this.transcriptionError &&
          other.isFavorite == this.isFavorite);
}

class RecordsCompanion extends UpdateCompanion<Record> {
  final Value<int> id;
  final Value<String> type;
  final Value<String?> content;
  final Value<String?> audioPath;
  final Value<String?> imagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> tags;
  final Value<String> transcriptionStatus;
  final Value<String?> transcriptionError;
  final Value<bool> isFavorite;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.transcriptionError = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.content = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.imagePath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.tags = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.transcriptionError = const Value.absent(),
    this.isFavorite = const Value.absent(),
  })  : type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Record> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? audioPath,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? tags,
    Expression<String>? transcriptionStatus,
    Expression<String>? transcriptionError,
    Expression<bool>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (audioPath != null) 'audio_path': audioPath,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tags != null) 'tags': tags,
      if (transcriptionStatus != null) 'transcription_status': transcriptionStatus,
      if (transcriptionError != null) 'transcription_error': transcriptionError,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  RecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String?>? content,
      Value<String?>? audioPath,
      Value<String?>? imagePath,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? tags,
      Value<String>? transcriptionStatus,
      Value<String?>? transcriptionError,
      Value<bool>? isFavorite}) {
    return RecordsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      audioPath: audioPath ?? this.audioPath,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      transcriptionError: transcriptionError ?? this.transcriptionError,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (transcriptionStatus.present) {
      map['transcription_status'] = Variable<String>(transcriptionStatus.value);
    }
    if (transcriptionError.present) {
      map['transcription_error'] = Variable<String>(transcriptionError.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('audioPath: $audioPath, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('transcriptionError: $transcriptionError, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, Record> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  final VerificationMeta _audioPathMeta = const VerificationMeta('audioPath');
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  final VerificationMeta _imagePathMeta = const VerificationMeta('imagePath');
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  final VerificationMeta _tagsMeta = const VerificationMeta('tags');
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  final VerificationMeta _transcriptionStatusMeta =
      const VerificationMeta('transcriptionStatus');
  late final GeneratedColumn<String> transcriptionStatus =
      GeneratedColumn<String>('transcription_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('pending'));
  final VerificationMeta _transcriptionErrorMeta =
      const VerificationMeta('transcriptionError');
  late final GeneratedColumn<String> transcriptionError =
      GeneratedColumn<String>('transcription_error', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  final VerificationMeta _isFavoriteMeta = const VerificationMeta('isFavorite');
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        content,
        audioPath,
        imagePath,
        createdAt,
        updatedAt,
        tags,
        transcriptionStatus,
        transcriptionError,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? 'records';
  @override
  String get actualTableName => 'records';
  @override
  VerificationContext validateIntegrity(Insertable<Record> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('transcription_status')) {
      context.handle(
          _transcriptionStatusMeta,
          transcriptionStatus.isAcceptableOrUnknown(
              data['transcription_status']!, _transcriptionStatusMeta));
    }
    if (data.containsKey('transcription_error')) {
      context.handle(
          _transcriptionErrorMeta,
          transcriptionError.isAcceptableOrUnknown(
              data['transcription_error']!, _transcriptionErrorMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(_isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Record map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Record(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      createdAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      transcriptionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_status'])!,
      transcriptionError: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_error']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }
}

class ApiConfig extends DataClass implements Insertable<ApiConfig> {
  final int id;
  final String provider;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ApiConfig(
      {required this.id,
      required this.provider,
      required this.apiKey,
      this.baseUrl,
      required this.model,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider'] = Variable<String>(provider);
    map['api_key'] = Variable<String>(apiKey);
    if (!nullToAbsent || baseUrl != null) {
      map['base_url'] = Variable<String>(baseUrl);
    }
    map['model'] = Variable<String>(model);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiConfig(
      id: serializer.fromJson<int>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      model: serializer.fromJson<String>(json['model']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'provider': serializer.toJson<String>(provider),
      'apiKey': serializer.toJson<String>(apiKey),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'model': serializer.toJson<String>(model),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ApiConfig copyWith(
          {int? id,
          String? provider,
          String? apiKey,
          Value<String?> baseUrl = const Value.absent(),
          String? model,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ApiConfig(
        id: id ?? this.id,
        provider: provider ?? this.provider,
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
        model: model ?? this.model,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('ApiConfig(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('apiKey: $apiKey, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, provider, apiKey, baseUrl, model, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiConfig &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.apiKey == this.apiKey &&
          other.baseUrl == this.baseUrl &&
          other.model == this.model &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ApiConfigsCompanion extends UpdateCompanion<ApiConfig> {
  final Value<int> id;
  final Value<String> provider;
  final Value<String> apiKey;
  final Value<String?> baseUrl;
  final Value<String> model;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ApiConfigsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.model = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ApiConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String provider,
    required String apiKey,
    this.baseUrl = const Value.absent(),
    this.model = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : provider = Value(provider),
        apiKey = Value(apiKey),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ApiConfig> custom({
    Expression<int>? id,
    Expression<String>? provider,
    Expression<String>? apiKey,
    Expression<String>? baseUrl,
    Expression<String>? model,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (apiKey != null) 'api_key': apiKey,
      if (baseUrl != null) 'base_url': baseUrl,
      if (model != null) 'model': model,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ApiConfigsCompanion copyWith(
      {Value<int>? id,
      Value<String>? provider,
      Value<String>? apiKey,
      Value<String?>? baseUrl,
      Value<String>? model,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ApiConfigsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiConfigsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('apiKey: $apiKey, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ApiConfigsTable extends ApiConfigs
    with TableInfo<$ApiConfigsTable, ApiConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiConfigsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _providerMeta = const VerificationMeta('provider');
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  final VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  final VerificationMeta _baseUrlMeta = const VerificationMeta('baseUrl');
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  final VerificationMeta _modelMeta = const VerificationMeta('model');
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('whisper-1'));
  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, provider, apiKey, baseUrl, model, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? 'api_configs';
  @override
  String get actualTableName => 'api_configs';
  @override
  VerificationContext validateIntegrity(Insertable<ApiConfig> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiConfig(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key'])!,
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      createdAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ApiConfigsTable createAlias(String alias) {
    return $ApiConfigsTable(attachedDatabase, alias);
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $RecordsTable records = $RecordsTable(this);
  late final $ApiConfigsTable apiConfigs = $ApiConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [records, apiConfigs];
}
