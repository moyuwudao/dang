import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/record_model.dart';

enum ExportFormat {
  markdown,
  plainText,
  json,
}

extension ExportFormatExtension on ExportFormat {
  String get name {
    switch (this) {
      case ExportFormat.markdown:
        return 'Markdown';
      case ExportFormat.plainText:
        return '纯文本';
      case ExportFormat.json:
        return 'JSON';
    }
  }

  String get extension {
    switch (this) {
      case ExportFormat.markdown:
        return '.md';
      case ExportFormat.plainText:
        return '.txt';
      case ExportFormat.json:
        return '.json';
    }
  }
}

class ExportService {
  Future<String> exportRecord(
    RecordModel record, {
    ExportFormat format = ExportFormat.markdown,
  }) async {
    final content = _formatContent(record, format);
    final path = await _getExportPath(record, format);
    await File(path).writeAsString(content);
    return path;
  }

  Future<String> exportAllRecords(
    List<RecordModel> records, {
    ExportFormat format = ExportFormat.markdown,
  }) async {
    final content = _formatAllRecords(records, format);
    final path = await _getExportPathForAll(format);
    await File(path).writeAsString(content);
    return path;
  }

  String _formatContent(RecordModel record, ExportFormat format) {
    switch (format) {
      case ExportFormat.markdown:
        return _formatAsMarkdown(record);
      case ExportFormat.plainText:
        return _formatAsPlainText(record);
      case ExportFormat.json:
        return _formatAsJson(record);
    }
  }

  String _formatAsMarkdown(RecordModel record) {
    final buffer = StringBuffer();

    buffer.writeln('# ${_formatDate(record.createdAt)}');
    buffer.writeln();

    buffer.writeln('## 基本信息');
    buffer.writeln();
    String typeText;
    switch (record.type) {
      case RecordType.audio:
        typeText = '语音记录';
        break;
      case RecordType.ocr:
        typeText = 'OCR识别';
        break;
      case RecordType.text:
        typeText = '文本记录';
        break;
    }
    buffer.writeln('- **类型**: $typeText');
    buffer.writeln('- **状态**: ${_getStatusText(record.transcriptionStatus)}');
    buffer.writeln('- **收藏**: ${record.isFavorite ? '是' : '否'}');

    if (record.tags.isNotEmpty) {
      buffer.writeln('- **标签**: ${record.tags.map((t) => '#$t').join(' ')}');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    if (record.content != null && record.content!.isNotEmpty) {
      buffer.writeln('## 转写内容');
      buffer.writeln();
      buffer.writeln(record.content);
      buffer.writeln();
    }

    if (record.aiAnalysis != null && record.aiAnalysis!.isNotEmpty) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## AI 分析');
      buffer.writeln();
      buffer.writeln(record.aiAnalysis);
      buffer.writeln();
    }

    if (record.supplements.isNotEmpty) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## 补充内容');
      buffer.writeln();

      for (final supplement in record.supplements) {
        buffer.writeln(
            '### ${supplement.type == 'audio' ? '🎤 录音补充' : supplement.type == 'image' ? '📷 图片补充' : '📝 文本补充'}');
        buffer.writeln();
        buffer.writeln('> ${supplement.content}');

        if (supplement.transcribedContent != null &&
            supplement.transcribedContent!.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('**转写内容**:');
          buffer.writeln();
          buffer.writeln(supplement.transcribedContent);
        }
        buffer.writeln();
      }
    }

    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('*导出时间: ${_formatDate(DateTime.now())}*');
    buffer.writeln('*来自畅记 App*');

    return buffer.toString();
  }

  String _formatAsPlainText(RecordModel record) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 40);
    buffer.writeln(_formatDate(record.createdAt));
    buffer.writeln('=' * 40);
    buffer.writeln();

    String typeText;
    switch (record.type) {
      case RecordType.audio:
        typeText = '语音记录';
        break;
      case RecordType.ocr:
        typeText = 'OCR识别';
        break;
      case RecordType.text:
        typeText = '文本记录';
        break;
    }
    buffer.writeln('类型: $typeText');
    buffer.writeln('状态: ${_getStatusText(record.transcriptionStatus)}');
    buffer.writeln('收藏: ${record.isFavorite ? '是' : '否'}');

    if (record.tags.isNotEmpty) {
      buffer.writeln('标签: ${record.tags.join(' ')}');
    }

    buffer.writeln();
    buffer.writeln('-' * 40);
    buffer.writeln();

    if (record.content != null && record.content!.isNotEmpty) {
      buffer.writeln('转写内容:');
      buffer.writeln();
      buffer.writeln(record.content);
      buffer.writeln();
    }

    if (record.aiAnalysis != null && record.aiAnalysis!.isNotEmpty) {
      buffer.writeln('-' * 40);
      buffer.writeln();
      buffer.writeln('AI 分析:');
      buffer.writeln();
      buffer.writeln(record.aiAnalysis);
      buffer.writeln();
    }

    if (record.supplements.isNotEmpty) {
      buffer.writeln('-' * 40);
      buffer.writeln();
      buffer.writeln('补充内容:');
      buffer.writeln();

      for (final supplement in record.supplements) {
        buffer.writeln(
            '${supplement.type == 'audio' ? '录音' : supplement.type == 'image' ? '图片' : '文本'}补充:');
        buffer.writeln(supplement.content);

        if (supplement.transcribedContent != null &&
            supplement.transcribedContent!.isNotEmpty) {
          buffer.writeln('转写内容:');
          buffer.writeln(supplement.transcribedContent);
        }
        buffer.writeln();
      }
    }

    buffer.writeln('=' * 40);
    buffer.writeln('导出时间: ${_formatDate(DateTime.now())}');
    buffer.writeln('来自畅记 App');

    return buffer.toString();
  }

  String _formatAsJson(RecordModel record) {
    final data = {
      'id': record.id,
      'type': record.type.name,
      'content': record.content,
      'audioPath': record.audioPath,
      'imagePath': record.imagePath,
      'createdAt': record.createdAt.toIso8601String(),
      'updatedAt': record.updatedAt.toIso8601String(),
      'tags': record.tags,
      'transcriptionStatus': record.transcriptionStatus.name,
      'transcriptionError': record.transcriptionError,
      'isFavorite': record.isFavorite,
      'aiAnalysis': record.aiAnalysis,
      'supplements': record.supplements
          .map((s) => {
                'id': s.id,
                'type': s.type,
                'content': s.content,
                'transcribedContent': s.transcribedContent,
                'createdAt': s.createdAt.toIso8601String(),
              })
          .toList(),
    };

    return _prettyJson(data);
  }

  String _formatAllRecords(List<RecordModel> records, ExportFormat format) {
    switch (format) {
      case ExportFormat.markdown:
        return _formatAllAsMarkdown(records);
      case ExportFormat.plainText:
        return _formatAllAsPlainText(records);
      case ExportFormat.json:
        return _formatAllAsJson(records);
    }
  }

  String _formatAllAsMarkdown(List<RecordModel> records) {
    final buffer = StringBuffer();

    buffer.writeln('# 畅记 - 全部记录导出');
    buffer.writeln();
    buffer.writeln('> 共 ${records.length} 条记录');
    buffer.writeln();
    buffer.writeln('导出时间: ${_formatDate(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      buffer.writeln('## ${i + 1}. ${_formatDate(record.createdAt)}');
      buffer.writeln();
      String typeText;
      switch (record.type) {
        case RecordType.audio:
          typeText = '语音';
          break;
        case RecordType.ocr:
          typeText = 'OCR';
          break;
        case RecordType.text:
          typeText = '文本';
          break;
      }
      buffer.writeln('- **类型**: $typeText');
      buffer.writeln('- **状态**: ${_getStatusText(record.transcriptionStatus)}');

      if (record.content != null && record.content!.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(record.content!.length > 200
            ? record.content!.substring(0, 200) + '...'
            : record.content);
      }

      if (i < records.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _formatAllAsPlainText(List<RecordModel> records) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('畅记 - 全部记录导出');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln('共 ${records.length} 条记录');
    buffer.writeln('导出时间: ${_formatDate(DateTime.now())}');
    buffer.writeln();

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      buffer.writeln('-' * 60);
      buffer.writeln('${i + 1}. ${_formatDate(record.createdAt)}');
      String typeText;
      switch (record.type) {
        case RecordType.audio:
          typeText = '语音';
          break;
        case RecordType.ocr:
          typeText = 'OCR';
          break;
        case RecordType.text:
          typeText = '文本';
          break;
      }
      buffer.writeln('类型: $typeText');
      buffer.writeln('状态: ${_getStatusText(record.transcriptionStatus)}');

      if (record.content != null && record.content!.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(record.content!.length > 200
            ? record.content!.substring(0, 200) + '...'
            : record.content);
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _formatAllAsJson(List<RecordModel> records) {
    final data = records
        .map((record) => {
              'id': record.id,
              'type': record.type.name,
              'content': record.content,
              'audioPath': record.audioPath,
              'imagePath': record.imagePath,
              'createdAt': record.createdAt.toIso8601String(),
              'updatedAt': record.updatedAt.toIso8601String(),
              'tags': record.tags,
              'transcriptionStatus': record.transcriptionStatus.name,
              'isFavorite': record.isFavorite,
            })
        .toList();

    return _prettyJson(
        {'records': data, 'exportTime': DateTime.now().toIso8601String()});
  }

  Future<String> _getExportPath(RecordModel record, ExportFormat format) async {
    final dir = await getExternalStorageDirectory();
    final fileName =
        '畅记_${_formatDateForFileName(record.createdAt)}${format.extension}';
    return '${dir!.path}/$fileName';
  }

  Future<String> _getExportPathForAll(ExportFormat format) async {
    final dir = await getExternalStorageDirectory();
    final fileName =
        '畅记_全部记录_${_formatDateForFileName(DateTime.now())}${format.extension}';
    return '${dir!.path}/$fileName';
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForFileName(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour}${date.minute}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待转写';
      case 'processing':
        return '转写中';
      case 'success':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }

  String _prettyJson(Map<String, dynamic> data) {
    return _jsonEncode(data, indent: 2);
  }

  String _jsonEncode(dynamic data, {int indent = 0}) {
    if (data is Map) {
      final items = data.entries.map((e) {
        final key = '"${e.key}"';
        final value = _jsonEncode(e.value, indent: indent + 2);
        return '${' ' * indent}$key: $value';
      }).join(',\n');
      return '{\n$items\n${' ' * (indent - 2)}}';
    } else if (data is List) {
      final items = data
          .map((e) =>
              '${' ' * (indent + 2)}${_jsonEncode(e, indent: indent + 2)}')
          .join(',\n');
      return '[\n$items\n${' ' * (indent - 2)}]';
    } else if (data is String) {
      return '"$data"';
    } else if (data == null) {
      return 'null';
    } else {
      return data.toString();
    }
  }
}
