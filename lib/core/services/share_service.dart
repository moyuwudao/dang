import 'package:share_plus/share_plus.dart';
import '../../../data/models/record_model.dart';

enum ShareTarget {
  system,
  feishuDoc,
  wecomDoc,
  wps,
  notion,
  other,
}

extension ShareTargetExtension on ShareTarget {
  String get name {
    switch (this) {
      case ShareTarget.system:
        return '系统分享';
      case ShareTarget.feishuDoc:
        return '飞书文档';
      case ShareTarget.wecomDoc:
        return '企业微信文档';
      case ShareTarget.wps:
        return 'WPS';
      case ShareTarget.notion:
        return 'Notion';
      case ShareTarget.other:
        return '其他应用';
    }
  }

  String get packageName {
    switch (this) {
      case ShareTarget.feishuDoc:
        return 'com.larksuite.suite';
      case ShareTarget.wecomDoc:
        return 'com.tencent.wework';
      case ShareTarget.wps:
        return 'cn.wps.moffice_eng';
      case ShareTarget.notion:
        return 'com.notionmobile';
      default:
        return '';
    }
  }
}

class ShareService {
  Future<void> shareRecord(RecordModel record, {ShareTarget target = ShareTarget.system}) async {
    final shareText = _formatShareContent(record);
    
    if (target == ShareTarget.system || target == ShareTarget.other) {
      await Share.share(shareText, subject: _formatSubject(record));
    } else {
      await Share.share(
        shareText,
        subject: _formatSubject(record),
        sharePositionOrigin: null,
      );
    }
  }

  Future<void> shareAsMarkdown(RecordModel record) async {
    final markdownText = _formatAsMarkdown(record);
    await Share.share(markdownText, subject: _formatSubject(record));
  }

  Future<void> shareAsPlainText(RecordModel record) async {
    final plainText = _formatAsPlainText(record);
    await Share.share(plainText, subject: _formatSubject(record));
  }

  String _formatShareContent(RecordModel record) {
    return _formatAsMarkdown(record);
  }

  String _formatAsMarkdown(RecordModel record) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${_formatDate(record.createdAt)}');
    buffer.writeln();
    
    if (record.tags.isNotEmpty) {
      buffer.writeln('**标签**: ${record.tags.map((t) => '#$t').join(' ')}');
      buffer.writeln();
    }
    
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
    buffer.writeln('**类型**: $typeText');
    buffer.writeln();
    
    buffer.writeln('---');
    buffer.writeln();
    
    if (record.content != null && record.content!.isNotEmpty) {
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
        buffer.writeln('### ${supplement.type == 'audio' ? '🎤 录音补充' : supplement.type == 'image' ? '📷 图片补充' : '📝 文本补充'}');
        buffer.writeln();
        buffer.writeln('> ${supplement.content}');
        
        if (supplement.transcribedContent != null && supplement.transcribedContent!.isNotEmpty) {
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
    buffer.writeln('*来自畅记 App*');
    
    return buffer.toString();
  }

  String _formatAsPlainText(RecordModel record) {
    final buffer = StringBuffer();
    
    buffer.writeln(_formatDate(record.createdAt));
    buffer.writeln();
    
    if (record.tags.isNotEmpty) {
      buffer.writeln('标签: ${record.tags.join(' ')}');
      buffer.writeln();
    }
    
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
    buffer.writeln();
    buffer.writeln('----------');
    buffer.writeln();
    
    if (record.content != null && record.content!.isNotEmpty) {
      buffer.writeln(record.content);
      buffer.writeln();
    }
    
    if (record.aiAnalysis != null && record.aiAnalysis!.isNotEmpty) {
      buffer.writeln('----------');
      buffer.writeln();
      buffer.writeln('AI 分析');
      buffer.writeln();
      buffer.writeln(record.aiAnalysis);
      buffer.writeln();
    }
    
    if (record.supplements.isNotEmpty) {
      buffer.writeln('----------');
      buffer.writeln();
      buffer.writeln('补充内容');
      buffer.writeln();
      
      for (final supplement in record.supplements) {
        buffer.writeln('${supplement.type == 'audio' ? '录音' : supplement.type == 'image' ? '图片' : '文本'}补充:');
        buffer.writeln(supplement.content);
        
        if (supplement.transcribedContent != null && supplement.transcribedContent!.isNotEmpty) {
          buffer.writeln('转写内容:');
          buffer.writeln(supplement.transcribedContent);
        }
        buffer.writeln();
      }
    }
    
    buffer.writeln('----------');
    buffer.writeln('来自畅记 App');
    
    return buffer.toString();
  }

  String _formatSubject(RecordModel record) {
    return '畅记分享 - ${_formatDate(record.createdAt)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<ShareTarget> getAvailableTargets() {
    return [
      ShareTarget.system,
      ShareTarget.feishuDoc,
      ShareTarget.wecomDoc,
      ShareTarget.wps,
      ShareTarget.notion,
    ];
  }
}
