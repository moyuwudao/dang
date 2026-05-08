enum RecordType {
  audio,
  ocr,
  text,
}

enum TranscriptionStatus {
  none,
  pending,
  processing,
  success,
  failed,
}

class SupplementItem {
  final String id;
  final String type; // 'text', 'audio', 'image'
  final String content; // text content or file path
  final DateTime createdAt;
  final String? transcribedContent; // 音频转写后的文本或图片OCR文本

  const SupplementItem({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.transcribedContent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'transcribedContent': transcribedContent,
      };

  factory SupplementItem.fromJson(Map<String, dynamic> json) => SupplementItem(
        id: json['id'] as String,
        type: json['type'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        transcribedContent: json['transcribedContent'] as String?,
      );

  SupplementItem copyWith({
    String? id,
    String? type,
    String? content,
    DateTime? createdAt,
    String? transcribedContent,
  }) {
    return SupplementItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      transcribedContent: transcribedContent ?? this.transcribedContent,
    );
  }
}

class AiAnalysisResult {
  final String roleId;
  final String roleName;
  final String content;
  final DateTime createdAt;

  const AiAnalysisResult({
    required this.roleId,
    required this.roleName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      roleId: json['roleId'] as String,
      roleName: json['roleName'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class RecordModel {
  final int id;
  final RecordType type;
  final String? content;
  final String? audioPath;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final TranscriptionStatus transcriptionStatus;
  final String? transcriptionError;
  final bool isFavorite;
  final List<AiAnalysisResult> aiAnalysisResults;
  final List<SupplementItem> supplements;

  const RecordModel({
    required this.id,
    required this.type,
    this.content,
    this.audioPath,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.transcriptionStatus = TranscriptionStatus.none,
    this.transcriptionError,
    this.isFavorite = false,
    this.aiAnalysisResults = const [],
    this.supplements = const [],
  });

  RecordModel copyWith({
    int? id,
    RecordType? type,
    String? content,
    String? audioPath,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    TranscriptionStatus? transcriptionStatus,
    String? transcriptionError,
    bool? isFavorite,
    List<AiAnalysisResult>? aiAnalysisResults,
    List<SupplementItem>? supplements,
  }) {
    return RecordModel(
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
      aiAnalysisResults: aiAnalysisResults ?? this.aiAnalysisResults,
      supplements: supplements ?? this.supplements,
    );
  }

  String? get aiAnalysis =>
      aiAnalysisResults.isNotEmpty ? aiAnalysisResults.first.content : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'transcriptionStatus': transcriptionStatus.name,
      'transcriptionError': transcriptionError,
      'isFavorite': isFavorite,
      'aiAnalysisResults': aiAnalysisResults.map((r) => r.toJson()).toList(),
      'supplements': supplements.map((s) => s.toJson()).toList(),
    };
  }

  factory RecordModel.fromJson(Map<String, dynamic> json) {
    return RecordModel(
      id: json['id'] as int,
      type: RecordType.values.firstWhere((e) => e.name == json['type']),
      content: json['content'] as String?,
      audioPath: json['audioPath'] as String?,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      transcriptionStatus: TranscriptionStatus.values.firstWhere(
        (e) => e.name == json['transcriptionStatus'],
        orElse: () => TranscriptionStatus.none,
      ),
      transcriptionError: json['transcriptionError'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      aiAnalysisResults: (json['aiAnalysisResults'] as List<dynamic>? ?? [])
          .map((r) => AiAnalysisResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      supplements: (json['supplements'] as List<dynamic>? ?? [])
          .map((s) => SupplementItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiConfigModel {
  final int id;
  final String provider;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiConfigModel({
    required this.id,
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.model = 'whisper-1',
    required this.createdAt,
    required this.updatedAt,
  });
}
