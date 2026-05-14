// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RecordsTable extends Records with TableInfo<$RecordsTable, Record> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _transcriptionStatusMeta =
      const VerificationMeta('transcriptionStatus');
  @override
  late final GeneratedColumn<String> transcriptionStatus =
      GeneratedColumn<String>('transcription_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('none'));
  static const VerificationMeta _transcriptionErrorMeta =
      const VerificationMeta('transcriptionError');
  @override
  late final GeneratedColumn<String> transcriptionError =
      GeneratedColumn<String>('transcription_error', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _aiAnalysisMeta =
      const VerificationMeta('aiAnalysis');
  @override
  late final GeneratedColumn<String> aiAnalysis = GeneratedColumn<String>(
      'ai_analysis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supplementsMeta =
      const VerificationMeta('supplements');
  @override
  late final GeneratedColumn<String> supplements = GeneratedColumn<String>(
      'supplements', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
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
        isFavorite,
        aiAnalysis,
        supplements
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
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
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('ai_analysis')) {
      context.handle(
          _aiAnalysisMeta,
          aiAnalysis.isAcceptableOrUnknown(
              data['ai_analysis']!, _aiAnalysisMeta));
    }
    if (data.containsKey('supplements')) {
      context.handle(
          _supplementsMeta,
          supplements.isAcceptableOrUnknown(
              data['supplements']!, _supplementsMeta));
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
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      transcriptionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_status'])!,
      transcriptionError: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_error']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      aiAnalysis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_analysis']),
      supplements: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supplements'])!,
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }
}

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
  final String? aiAnalysis;
  final String supplements;
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
      required this.isFavorite,
      this.aiAnalysis,
      required this.supplements});
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
    if (!nullToAbsent || aiAnalysis != null) {
      map['ai_analysis'] = Variable<String>(aiAnalysis);
    }
    map['supplements'] = Variable<String>(supplements);
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      id: Value(id),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      tags: Value(tags),
      transcriptionStatus: Value(transcriptionStatus),
      transcriptionError: transcriptionError == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptionError),
      isFavorite: Value(isFavorite),
      aiAnalysis: aiAnalysis == null && nullToAbsent
          ? const Value.absent()
          : Value(aiAnalysis),
      supplements: Value(supplements),
    );
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
      aiAnalysis: serializer.fromJson<String?>(json['aiAnalysis']),
      supplements: serializer.fromJson<String>(json['supplements']),
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
      'aiAnalysis': serializer.toJson<String?>(aiAnalysis),
      'supplements': serializer.toJson<String>(supplements),
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
          bool? isFavorite,
          Value<String?> aiAnalysis = const Value.absent(),
          String? supplements}) =>
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
        aiAnalysis: aiAnalysis.present ? aiAnalysis.value : this.aiAnalysis,
        supplements: supplements ?? this.supplements,
      );
  Record copyWithCompanion(RecordsCompanion data) {
    return Record(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      transcriptionStatus: data.transcriptionStatus.present
          ? data.transcriptionStatus.value
          : this.transcriptionStatus,
      transcriptionError: data.transcriptionError.present
          ? data.transcriptionError.value
          : this.transcriptionError,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      aiAnalysis:
          data.aiAnalysis.present ? data.aiAnalysis.value : this.aiAnalysis,
      supplements:
          data.supplements.present ? data.supplements.value : this.supplements,
    );
  }

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
          ..write('isFavorite: $isFavorite, ')
          ..write('aiAnalysis: $aiAnalysis, ')
          ..write('supplements: $supplements')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      isFavorite,
      aiAnalysis,
      supplements);
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
          other.isFavorite == this.isFavorite &&
          other.aiAnalysis == this.aiAnalysis &&
          other.supplements == this.supplements);
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
  final Value<String?> aiAnalysis;
  final Value<String> supplements;
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
    this.aiAnalysis = const Value.absent(),
    this.supplements = const Value.absent(),
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
    this.aiAnalysis = const Value.absent(),
    this.supplements = const Value.absent(),
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
    Expression<String>? aiAnalysis,
    Expression<String>? supplements,
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
      if (transcriptionStatus != null)
        'transcription_status': transcriptionStatus,
      if (transcriptionError != null) 'transcription_error': transcriptionError,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (aiAnalysis != null) 'ai_analysis': aiAnalysis,
      if (supplements != null) 'supplements': supplements,
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
      Value<bool>? isFavorite,
      Value<String?>? aiAnalysis,
      Value<String>? supplements}) {
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
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      supplements: supplements ?? this.supplements,
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
    if (aiAnalysis.present) {
      map['ai_analysis'] = Variable<String>(aiAnalysis.value);
    }
    if (supplements.present) {
      map['supplements'] = Variable<String>(supplements.value);
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
          ..write('isFavorite: $isFavorite, ')
          ..write('aiAnalysis: $aiAnalysis, ')
          ..write('supplements: $supplements')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('whisper-1'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, provider, apiKey, baseUrl, model, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_configs';
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
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ApiConfigsTable createAlias(String alias) {
    return $ApiConfigsTable(attachedDatabase, alias);
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

  ApiConfigsCompanion toCompanion(bool nullToAbsent) {
    return ApiConfigsCompanion(
      id: Value(id),
      provider: Value(provider),
      apiKey: Value(apiKey),
      baseUrl: baseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUrl),
      model: Value(model),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
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
  ApiConfig copyWithCompanion(ApiConfigsCompanion data) {
    return ApiConfig(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      model: data.model.present ? data.model.value : this.model,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

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

class $ToolOutputsTable extends ToolOutputs
    with TableInfo<$ToolOutputsTable, ToolOutput> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToolOutputsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toolIdMeta = const VerificationMeta('toolId');
  @override
  late final GeneratedColumn<String> toolId = GeneratedColumn<String>(
      'tool_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _sourceRecordIdsMeta =
      const VerificationMeta('sourceRecordIds');
  @override
  late final GeneratedColumn<String> sourceRecordIds = GeneratedColumn<String>(
      'source_record_ids', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usageCountMeta =
      const VerificationMeta('usageCount');
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
      'usage_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        toolId,
        title,
        content,
        createdAt,
        updatedAt,
        tags,
        sourceRecordIds,
        templateId,
        usageCount,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tool_outputs';
  @override
  VerificationContext validateIntegrity(Insertable<ToolOutput> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tool_id')) {
      context.handle(_toolIdMeta,
          toolId.isAcceptableOrUnknown(data['tool_id']!, _toolIdMeta));
    } else if (isInserting) {
      context.missing(_toolIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
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
    if (data.containsKey('source_record_ids')) {
      context.handle(
          _sourceRecordIdsMeta,
          sourceRecordIds.isAcceptableOrUnknown(
              data['source_record_ids']!, _sourceRecordIdsMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    }
    if (data.containsKey('usage_count')) {
      context.handle(
          _usageCountMeta,
          usageCount.isAcceptableOrUnknown(
              data['usage_count']!, _usageCountMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ToolOutput map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToolOutput(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      toolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tool_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      sourceRecordIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_record_ids'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id']),
      usageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usage_count'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $ToolOutputsTable createAlias(String alias) {
    return $ToolOutputsTable(attachedDatabase, alias);
  }
}

class ToolOutput extends DataClass implements Insertable<ToolOutput> {
  final String id;
  final String toolId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String tags;
  final String sourceRecordIds;
  final String? templateId;
  final int usageCount;
  final bool isFavorite;
  const ToolOutput(
      {required this.id,
      required this.toolId,
      required this.title,
      required this.content,
      required this.createdAt,
      required this.updatedAt,
      required this.tags,
      required this.sourceRecordIds,
      this.templateId,
      required this.usageCount,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tool_id'] = Variable<String>(toolId);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['tags'] = Variable<String>(tags);
    map['source_record_ids'] = Variable<String>(sourceRecordIds);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['usage_count'] = Variable<int>(usageCount);
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  ToolOutputsCompanion toCompanion(bool nullToAbsent) {
    return ToolOutputsCompanion(
      id: Value(id),
      toolId: Value(toolId),
      title: Value(title),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      tags: Value(tags),
      sourceRecordIds: Value(sourceRecordIds),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      usageCount: Value(usageCount),
      isFavorite: Value(isFavorite),
    );
  }

  factory ToolOutput.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToolOutput(
      id: serializer.fromJson<String>(json['id']),
      toolId: serializer.fromJson<String>(json['toolId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      tags: serializer.fromJson<String>(json['tags']),
      sourceRecordIds: serializer.fromJson<String>(json['sourceRecordIds']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'toolId': serializer.toJson<String>(toolId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'tags': serializer.toJson<String>(tags),
      'sourceRecordIds': serializer.toJson<String>(sourceRecordIds),
      'templateId': serializer.toJson<String?>(templateId),
      'usageCount': serializer.toJson<int>(usageCount),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  ToolOutput copyWith(
          {String? id,
          String? toolId,
          String? title,
          String? content,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? tags,
          String? sourceRecordIds,
          Value<String?> templateId = const Value.absent(),
          int? usageCount,
          bool? isFavorite}) =>
      ToolOutput(
        id: id ?? this.id,
        toolId: toolId ?? this.toolId,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tags: tags ?? this.tags,
        sourceRecordIds: sourceRecordIds ?? this.sourceRecordIds,
        templateId: templateId.present ? templateId.value : this.templateId,
        usageCount: usageCount ?? this.usageCount,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  ToolOutput copyWithCompanion(ToolOutputsCompanion data) {
    return ToolOutput(
      id: data.id.present ? data.id.value : this.id,
      toolId: data.toolId.present ? data.toolId.value : this.toolId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      sourceRecordIds: data.sourceRecordIds.present
          ? data.sourceRecordIds.value
          : this.sourceRecordIds,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      usageCount:
          data.usageCount.present ? data.usageCount.value : this.usageCount,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToolOutput(')
          ..write('id: $id, ')
          ..write('toolId: $toolId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('sourceRecordIds: $sourceRecordIds, ')
          ..write('templateId: $templateId, ')
          ..write('usageCount: $usageCount, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, toolId, title, content, createdAt,
      updatedAt, tags, sourceRecordIds, templateId, usageCount, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolOutput &&
          other.id == this.id &&
          other.toolId == this.toolId &&
          other.title == this.title &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tags == this.tags &&
          other.sourceRecordIds == this.sourceRecordIds &&
          other.templateId == this.templateId &&
          other.usageCount == this.usageCount &&
          other.isFavorite == this.isFavorite);
}

class ToolOutputsCompanion extends UpdateCompanion<ToolOutput> {
  final Value<String> id;
  final Value<String> toolId;
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> tags;
  final Value<String> sourceRecordIds;
  final Value<String?> templateId;
  final Value<int> usageCount;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const ToolOutputsCompanion({
    this.id = const Value.absent(),
    this.toolId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.sourceRecordIds = const Value.absent(),
    this.templateId = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ToolOutputsCompanion.insert({
    required String id,
    required String toolId,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.tags = const Value.absent(),
    this.sourceRecordIds = const Value.absent(),
    this.templateId = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        toolId = Value(toolId),
        title = Value(title),
        content = Value(content),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ToolOutput> custom({
    Expression<String>? id,
    Expression<String>? toolId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? tags,
    Expression<String>? sourceRecordIds,
    Expression<String>? templateId,
    Expression<int>? usageCount,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (toolId != null) 'tool_id': toolId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tags != null) 'tags': tags,
      if (sourceRecordIds != null) 'source_record_ids': sourceRecordIds,
      if (templateId != null) 'template_id': templateId,
      if (usageCount != null) 'usage_count': usageCount,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ToolOutputsCompanion copyWith(
      {Value<String>? id,
      Value<String>? toolId,
      Value<String>? title,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? tags,
      Value<String>? sourceRecordIds,
      Value<String?>? templateId,
      Value<int>? usageCount,
      Value<bool>? isFavorite,
      Value<int>? rowid}) {
    return ToolOutputsCompanion(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      sourceRecordIds: sourceRecordIds ?? this.sourceRecordIds,
      templateId: templateId ?? this.templateId,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (toolId.present) {
      map['tool_id'] = Variable<String>(toolId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
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
    if (sourceRecordIds.present) {
      map['source_record_ids'] = Variable<String>(sourceRecordIds.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToolOutputsCompanion(')
          ..write('id: $id, ')
          ..write('toolId: $toolId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('sourceRecordIds: $sourceRecordIds, ')
          ..write('templateId: $templateId, ')
          ..write('usageCount: $usageCount, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $ApiConfigsTable apiConfigs = $ApiConfigsTable(this);
  late final $ToolOutputsTable toolOutputs = $ToolOutputsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [records, apiConfigs, toolOutputs];
}

typedef $$RecordsTableCreateCompanionBuilder = RecordsCompanion Function({
  Value<int> id,
  required String type,
  Value<String?> content,
  Value<String?> audioPath,
  Value<String?> imagePath,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> tags,
  Value<String> transcriptionStatus,
  Value<String?> transcriptionError,
  Value<bool> isFavorite,
  Value<String?> aiAnalysis,
  Value<String> supplements,
});
typedef $$RecordsTableUpdateCompanionBuilder = RecordsCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<String?> content,
  Value<String?> audioPath,
  Value<String?> imagePath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> tags,
  Value<String> transcriptionStatus,
  Value<String?> transcriptionError,
  Value<bool> isFavorite,
  Value<String?> aiAnalysis,
  Value<String> supplements,
});

class $$RecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptionError => $composableBuilder(
      column: $table.transcriptionError,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiAnalysis => $composableBuilder(
      column: $table.aiAnalysis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supplements => $composableBuilder(
      column: $table.supplements, builder: (column) => ColumnFilters(column));
}

class $$RecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionError => $composableBuilder(
      column: $table.transcriptionError,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiAnalysis => $composableBuilder(
      column: $table.aiAnalysis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supplements => $composableBuilder(
      column: $table.supplements, builder: (column) => ColumnOrderings(column));
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus, builder: (column) => column);

  GeneratedColumn<String> get transcriptionError => $composableBuilder(
      column: $table.transcriptionError, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get aiAnalysis => $composableBuilder(
      column: $table.aiAnalysis, builder: (column) => column);

  GeneratedColumn<String> get supplements => $composableBuilder(
      column: $table.supplements, builder: (column) => column);
}

class $$RecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecordsTable,
    Record,
    $$RecordsTableFilterComposer,
    $$RecordsTableOrderingComposer,
    $$RecordsTableAnnotationComposer,
    $$RecordsTableCreateCompanionBuilder,
    $$RecordsTableUpdateCompanionBuilder,
    (Record, BaseReferences<_$AppDatabase, $RecordsTable, Record>),
    Record,
    PrefetchHooks Function()> {
  $$RecordsTableTableManager(_$AppDatabase db, $RecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> transcriptionStatus = const Value.absent(),
            Value<String?> transcriptionError = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String?> aiAnalysis = const Value.absent(),
            Value<String> supplements = const Value.absent(),
          }) =>
              RecordsCompanion(
            id: id,
            type: type,
            content: content,
            audioPath: audioPath,
            imagePath: imagePath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            transcriptionStatus: transcriptionStatus,
            transcriptionError: transcriptionError,
            isFavorite: isFavorite,
            aiAnalysis: aiAnalysis,
            supplements: supplements,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            Value<String?> content = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> tags = const Value.absent(),
            Value<String> transcriptionStatus = const Value.absent(),
            Value<String?> transcriptionError = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String?> aiAnalysis = const Value.absent(),
            Value<String> supplements = const Value.absent(),
          }) =>
              RecordsCompanion.insert(
            id: id,
            type: type,
            content: content,
            audioPath: audioPath,
            imagePath: imagePath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            transcriptionStatus: transcriptionStatus,
            transcriptionError: transcriptionError,
            isFavorite: isFavorite,
            aiAnalysis: aiAnalysis,
            supplements: supplements,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecordsTable,
    Record,
    $$RecordsTableFilterComposer,
    $$RecordsTableOrderingComposer,
    $$RecordsTableAnnotationComposer,
    $$RecordsTableCreateCompanionBuilder,
    $$RecordsTableUpdateCompanionBuilder,
    (Record, BaseReferences<_$AppDatabase, $RecordsTable, Record>),
    Record,
    PrefetchHooks Function()>;
typedef $$ApiConfigsTableCreateCompanionBuilder = ApiConfigsCompanion Function({
  Value<int> id,
  required String provider,
  required String apiKey,
  Value<String?> baseUrl,
  Value<String> model,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ApiConfigsTableUpdateCompanionBuilder = ApiConfigsCompanion Function({
  Value<int> id,
  Value<String> provider,
  Value<String> apiKey,
  Value<String?> baseUrl,
  Value<String> model,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ApiConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ApiConfigsTable> {
  $$ApiConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ApiConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiConfigsTable> {
  $$ApiConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ApiConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiConfigsTable> {
  $$ApiConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ApiConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ApiConfigsTable,
    ApiConfig,
    $$ApiConfigsTableFilterComposer,
    $$ApiConfigsTableOrderingComposer,
    $$ApiConfigsTableAnnotationComposer,
    $$ApiConfigsTableCreateCompanionBuilder,
    $$ApiConfigsTableUpdateCompanionBuilder,
    (ApiConfig, BaseReferences<_$AppDatabase, $ApiConfigsTable, ApiConfig>),
    ApiConfig,
    PrefetchHooks Function()> {
  $$ApiConfigsTableTableManager(_$AppDatabase db, $ApiConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String> apiKey = const Value.absent(),
            Value<String?> baseUrl = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ApiConfigsCompanion(
            id: id,
            provider: provider,
            apiKey: apiKey,
            baseUrl: baseUrl,
            model: model,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String provider,
            required String apiKey,
            Value<String?> baseUrl = const Value.absent(),
            Value<String> model = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              ApiConfigsCompanion.insert(
            id: id,
            provider: provider,
            apiKey: apiKey,
            baseUrl: baseUrl,
            model: model,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ApiConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ApiConfigsTable,
    ApiConfig,
    $$ApiConfigsTableFilterComposer,
    $$ApiConfigsTableOrderingComposer,
    $$ApiConfigsTableAnnotationComposer,
    $$ApiConfigsTableCreateCompanionBuilder,
    $$ApiConfigsTableUpdateCompanionBuilder,
    (ApiConfig, BaseReferences<_$AppDatabase, $ApiConfigsTable, ApiConfig>),
    ApiConfig,
    PrefetchHooks Function()>;
typedef $$ToolOutputsTableCreateCompanionBuilder = ToolOutputsCompanion
    Function({
  required String id,
  required String toolId,
  required String title,
  required String content,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> tags,
  Value<String> sourceRecordIds,
  Value<String?> templateId,
  Value<int> usageCount,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$ToolOutputsTableUpdateCompanionBuilder = ToolOutputsCompanion
    Function({
  Value<String> id,
  Value<String> toolId,
  Value<String> title,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> tags,
  Value<String> sourceRecordIds,
  Value<String?> templateId,
  Value<int> usageCount,
  Value<bool> isFavorite,
  Value<int> rowid,
});

class $$ToolOutputsTableFilterComposer
    extends Composer<_$AppDatabase, $ToolOutputsTable> {
  $$ToolOutputsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toolId => $composableBuilder(
      column: $table.toolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceRecordIds => $composableBuilder(
      column: $table.sourceRecordIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));
}

class $$ToolOutputsTableOrderingComposer
    extends Composer<_$AppDatabase, $ToolOutputsTable> {
  $$ToolOutputsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toolId => $composableBuilder(
      column: $table.toolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceRecordIds => $composableBuilder(
      column: $table.sourceRecordIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));
}

class $$ToolOutputsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToolOutputsTable> {
  $$ToolOutputsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get toolId =>
      $composableBuilder(column: $table.toolId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get sourceRecordIds => $composableBuilder(
      column: $table.sourceRecordIds, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);
}

class $$ToolOutputsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ToolOutputsTable,
    ToolOutput,
    $$ToolOutputsTableFilterComposer,
    $$ToolOutputsTableOrderingComposer,
    $$ToolOutputsTableAnnotationComposer,
    $$ToolOutputsTableCreateCompanionBuilder,
    $$ToolOutputsTableUpdateCompanionBuilder,
    (ToolOutput, BaseReferences<_$AppDatabase, $ToolOutputsTable, ToolOutput>),
    ToolOutput,
    PrefetchHooks Function()> {
  $$ToolOutputsTableTableManager(_$AppDatabase db, $ToolOutputsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToolOutputsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToolOutputsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToolOutputsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> toolId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> sourceRecordIds = const Value.absent(),
            Value<String?> templateId = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ToolOutputsCompanion(
            id: id,
            toolId: toolId,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            sourceRecordIds: sourceRecordIds,
            templateId: templateId,
            usageCount: usageCount,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String toolId,
            required String title,
            required String content,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> tags = const Value.absent(),
            Value<String> sourceRecordIds = const Value.absent(),
            Value<String?> templateId = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ToolOutputsCompanion.insert(
            id: id,
            toolId: toolId,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            sourceRecordIds: sourceRecordIds,
            templateId: templateId,
            usageCount: usageCount,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ToolOutputsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ToolOutputsTable,
    ToolOutput,
    $$ToolOutputsTableFilterComposer,
    $$ToolOutputsTableOrderingComposer,
    $$ToolOutputsTableAnnotationComposer,
    $$ToolOutputsTableCreateCompanionBuilder,
    $$ToolOutputsTableUpdateCompanionBuilder,
    (ToolOutput, BaseReferences<_$AppDatabase, $ToolOutputsTable, ToolOutput>),
    ToolOutput,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$ApiConfigsTableTableManager get apiConfigs =>
      $$ApiConfigsTableTableManager(_db, _db.apiConfigs);
  $$ToolOutputsTableTableManager get toolOutputs =>
      $$ToolOutputsTableTableManager(_db, _db.toolOutputs);
}
