enum RecordType {
  audio,
  ocr,
}

enum TranscriptionStatus {
  pending,
  processing,
  success,
  failed,
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

  const RecordModel({
    required this.id,
    required this.type,
    this.content,
    this.audioPath,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.transcriptionStatus = TranscriptionStatus.pending,
    this.transcriptionError,
    this.isFavorite = false,
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
