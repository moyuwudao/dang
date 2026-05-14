import 'package:flutter/material.dart';

class RichTextController extends TextEditingController {
  List<Set<String>> _formats = [];
  Set<String> _typingFormat = {};

  RichTextController({String? text}) : super(text: text) {
    _syncFormats();
  }

  void _syncFormats() {
    while (_formats.length < text.length) {
      _formats.add(Set<String>.from(_typingFormat));
    }
    while (_formats.length > text.length) {
      _formats.removeLast();
    }
  }

  static const Set<String> _headingFormats = {'h1', 'h2'};
  static const Set<String> _inlineFormats = {
    'bold',
    'italic',
    'underline',
    'strikethrough',
    'code'
  };
  static const Set<String> _listFormats = {'ordered', 'unordered'};

  Set<String> get typingFormat => Set<String>.from(_typingFormat);

  void applyTypingFormatToPosition(int position) {
    if (position <= 0 || _formats.isEmpty) return;
    final idx = position - 1;
    if (idx < _formats.length) {
      _formats[idx] = Set<String>.from(_typingFormat);
    }
  }

  void toggleFormat(String format, int start, int end) {
    if (text.isEmpty || start < 0 || end < 0) return;
    final s = start.clamp(0, text.length - 1);
    final e = end.clamp(1, text.length);
    if (s >= e) return;

    bool allHave = true;
    for (int i = s; i < e; i++) {
      if (i >= _formats.length || !_formats[i].contains(format)) {
        allHave = false;
        break;
      }
    }

    for (int i = s; i < e; i++) {
      if (i < _formats.length) {
        if (allHave) {
          _formats[i].remove(format);
        } else {
          if (_headingFormats.contains(format)) {
            _formats[i].removeAll(_headingFormats);
            _formats[i].removeAll(_listFormats);
            _formats[i].removeAll(_inlineFormats);
          } else if (_listFormats.contains(format)) {
            _formats[i].removeAll(_listFormats);
            _formats[i].removeAll(_headingFormats);
            _formats[i].removeAll(_inlineFormats);
          } else if (_inlineFormats.contains(format)) {
            _formats[i].removeAll(_headingFormats);
            _formats[i].removeAll(_listFormats);
          }
          _formats[i].add(format);
        }
      }
    }
    if (e > 0 && e <= _formats.length) {
      _typingFormat = Set<String>.from(_formats[e - 1]);
    }
    notifyListeners();
  }

  Set<String> getFormatsAt(int position) {
    if (position <= 0 || _formats.isEmpty)
      return Set<String>.from(_typingFormat);
    if (position > _formats.length) return Set<String>.from(_typingFormat);
    return Set<String>.from(_formats[position - 1]);
  }

  void setTypingFormat(String format) {
    if (_typingFormat.contains(format)) {
      _typingFormat.remove(format);
    } else {
      if (_headingFormats.contains(format)) {
        _typingFormat.removeAll(_headingFormats);
        _typingFormat.removeAll(_listFormats);
        _typingFormat.removeAll(_inlineFormats);
      } else if (_listFormats.contains(format)) {
        _typingFormat.removeAll(_listFormats);
        _typingFormat.removeAll(_headingFormats);
        _typingFormat.removeAll(_inlineFormats);
      } else if (_inlineFormats.contains(format)) {
        _typingFormat.removeAll(_headingFormats);
        _typingFormat.removeAll(_listFormats);
      }
      _typingFormat.add(format);
    }
    notifyListeners();
  }

  void clearFormats(int start, int end) {
    final s = start.clamp(0, text.length - 1);
    final e = end.clamp(1, text.length);
    if (s >= e) return;
    for (int i = s; i < e && i < _formats.length; i++) {
      _formats[i].clear();
    }
    _typingFormat.clear();
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    final newText = newValue.text;
    if (oldText != newText) {
      _handleTextChange(oldText, newText);
    }
    super.value = newValue;
  }

  void _handleTextChange(String oldText, String newText) {
    if (oldText.isEmpty && newText.isNotEmpty) {
      _formats =
          List.generate(newText.length, (_) => Set<String>.from(_typingFormat));
      return;
    }
    if (newText.isEmpty) {
      _formats = [];
      return;
    }

    int prefixLen = 0;
    final minLen =
        oldText.length < newText.length ? oldText.length : newText.length;
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    int suffixLen = 0;
    while (suffixLen < minLen - prefixLen &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final deletedCount = oldText.length - prefixLen - suffixLen;
    final insertedCount = newText.length - prefixLen - suffixLen;

    if (deletedCount > 0) {
      final removeEnd = (prefixLen + deletedCount).clamp(0, _formats.length);
      if (prefixLen < _formats.length && prefixLen < removeEnd) {
        _formats.removeRange(prefixLen, removeEnd);
      }
    }

    if (insertedCount > 0) {
      for (int i = 0; i < insertedCount; i++) {
        _formats.insert(prefixLen + i, Set<String>.from(_typingFormat));
      }
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    _syncFormats();

    if (text.isEmpty || _formats.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final spans = <TextSpan>[];
    int i = 0;
    while (i < text.length) {
      final formats = i < _formats.length ? _formats[i] : <String>{};
      int j = i + 1;
      while (j < text.length &&
          j < _formats.length &&
          _sameFormats(formats, _formats[j])) {
        j++;
      }
      spans.add(TextSpan(
        text: text.substring(i, j),
        style: _applyFormats(style, formats),
      ));
      i = j;
    }

    return TextSpan(children: spans, style: style);
  }

  bool _sameFormats(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  TextStyle _applyFormats(TextStyle? base, Set<String> formats) {
    var style = base ?? const TextStyle();
    var decorations = <TextDecoration>[];

    if (formats.contains('h1')) {
      style = style.copyWith(
          fontSize: 24, fontWeight: FontWeight.w800, height: 1.4);
    } else if (formats.contains('h2')) {
      style = style.copyWith(
          fontSize: 20, fontWeight: FontWeight.w700, height: 1.35);
    } else {
      if (formats.contains('bold')) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
    }
    if (formats.contains('italic')) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (formats.contains('underline')) {
      decorations.add(TextDecoration.underline);
    }
    if (formats.contains('strikethrough')) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (formats.contains('code')) {
      style = style.copyWith(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: const Color(0xFFF5F5F5),
      );
    }

    if (decorations.isNotEmpty) {
      style = style.copyWith(
        decoration: TextDecoration.combine(decorations),
        decorationColor: style.color,
        decorationThickness: 2.0,
      );
    }

    return style;
  }

  String serialize() {
    if (_formats.isEmpty || _formats.every((f) => f.isEmpty)) {
      return text;
    }

    final segments = <String>[];
    int i = 0;
    while (i < _formats.length) {
      final fmt = _formats[i];
      int len = 1;
      while (
          i + len < _formats.length && _sameFormats(fmt, _formats[i + len])) {
        len++;
      }
      if (fmt.isNotEmpty) {
        segments.add('$len:${fmt.join('+')}');
      } else {
        segments.add('$len:');
      }
      i += len;
    }

    return '${text}\x00${segments.join('|')}';
  }

  static (String, List<Set<String>>) deserialize(String stored) {
    final idx = stored.indexOf('\x00');
    if (idx < 0) {
      return (stored, List.generate(stored.length, (_) => <String>{}));
    }

    final plainText = stored.substring(0, idx);
    final fmtStr = stored.substring(idx + 1);

    final formats =
        List<Set<String>>.generate(plainText.length, (_) => <String>{});

    if (fmtStr.isNotEmpty) {
      int pos = 0;
      for (final seg in fmtStr.split('|')) {
        final colonIdx = seg.indexOf(':');
        if (colonIdx < 0) continue;
        final len = int.tryParse(seg.substring(0, colonIdx)) ?? 0;
        final fmtStr = seg.substring(colonIdx + 1);
        final fmts = fmtStr.isEmpty ? <String>{} : fmtStr.split('+').toSet();
        for (int i = 0; i < len && pos + i < formats.length; i++) {
          formats[pos + i] = Set<String>.from(fmts);
        }
        pos += len;
      }
    }

    return (plainText, formats);
  }

  void loadFromSerialized(String stored) {
    final (plainText, formats) = deserialize(stored);
    text = plainText;
    _formats = formats;
    _typingFormat = {};
    notifyListeners();
  }

  String getPlainText() {
    final idx = text.indexOf('\x00');
    if (idx >= 0) {
      return text.substring(0, idx);
    }
    return text;
  }
}