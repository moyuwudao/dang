import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MarkdownViewer extends StatelessWidget {
  final String content;
  final TextStyle? baseStyle;

  const MarkdownViewer({
    super.key,
    required this.content,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = baseStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          height: 1.7,
          color: AppColors.textPrimary,
        );

    final widgets = _parseMarkdown(content, defaultStyle, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Widget> _parseMarkdown(
    String text,
    TextStyle? baseStyle,
    BuildContext context,
  ) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    final buffer = <String>[];
    var inCodeBlock = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        if (inCodeBlock) {
          widgets.add(_buildCodeBlock(buffer.join('\n'), context));
          buffer.clear();
          inCodeBlock = false;
        } else {
          if (buffer.isNotEmpty) {
            widgets.addAll(
              _buildParagraphs(buffer.join('\n'), baseStyle, context),
            );
            buffer.clear();
          }
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        buffer.add(line);
        continue;
      }

      if (line.trim().isEmpty) {
        if (buffer.isNotEmpty) {
          widgets.addAll(
            _buildParagraphs(buffer.join('\n'), baseStyle, context),
          );
          buffer.clear();
        }
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      buffer.add(line);
    }

    if (buffer.isNotEmpty) {
      if (inCodeBlock) {
        widgets.add(_buildCodeBlock(buffer.join('\n'), context));
      } else {
        widgets.addAll(
          _buildParagraphs(buffer.join('\n'), baseStyle, context),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildParagraphs(
    String text,
    TextStyle? baseStyle,
    BuildContext context,
  ) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    var inList = false;
    var listItems = <Widget>[];
    var isOrdered = false;

    for (final line in lines) {
      final trimmed = line.trim();

      final todoMatch = RegExp(r'^- \[( |x)\] (.+)').firstMatch(trimmed);
      if (todoMatch != null) {
        if (!inList) {
          inList = true;
          listItems = [];
        }
        final isChecked = todoMatch.group(1) == 'x';
        final content = todoMatch.group(2)!;
        listItems.add(
          _buildTodoItem(content, isChecked, baseStyle, context),
        );
        continue;
      }

      final bulletMatch = RegExp(r'^[-*] (.+)').firstMatch(trimmed);
      if (bulletMatch != null) {
        if (!inList || isOrdered) {
          if (inList) {
            widgets.add(_buildList(listItems, isOrdered));
          }
          inList = true;
          isOrdered = false;
          listItems = [];
        }
        listItems.add(
          _buildBulletItem(bulletMatch.group(1)!, baseStyle, context),
        );
        continue;
      }

      final orderedMatch = RegExp(r'^\d+\. (.+)').firstMatch(trimmed);
      if (orderedMatch != null) {
        if (!inList || !isOrdered) {
          if (inList) {
            widgets.add(_buildList(listItems, isOrdered));
          }
          inList = true;
          isOrdered = true;
          listItems = [];
        }
        final number = RegExp(r'^(\d+)\.').firstMatch(trimmed)!.group(1)!;
        listItems.add(
          _buildOrderedItem(orderedMatch.group(1)!, number, baseStyle, context),
        );
        continue;
      }

      if (inList) {
        widgets.add(_buildList(listItems, isOrdered));
        inList = false;
        listItems = [];
      }

      if (trimmed.startsWith('> ')) {
        widgets.add(
          _buildQuote(trimmed.substring(2), baseStyle, context),
        );
        continue;
      }

      if (trimmed.startsWith('### ')) {
        widgets.add(
          _buildHeading(trimmed.substring(4), 3, context),
        );
        continue;
      }
      if (trimmed.startsWith('## ')) {
        widgets.add(
          _buildHeading(trimmed.substring(3), 2, context),
        );
        continue;
      }
      if (trimmed.startsWith('# ')) {
        widgets.add(
          _buildHeading(trimmed.substring(2), 1, context),
        );
        continue;
      }

      if (trimmed == '---' || trimmed == '***') {
        widgets.add(const Divider(height: 32));
        continue;
      }

      widgets.add(
        _buildRichText(line, baseStyle, context),
      );
    }

    if (inList) {
      widgets.add(_buildList(listItems, isOrdered));
    }

    return widgets;
  }

  Widget _buildRichText(
      String text, TextStyle? baseStyle, BuildContext context) {
    final spans = _parseInlineStyles(text, baseStyle);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          children: spans,
          style: baseStyle,
        ),
      ),
    );
  }

  List<InlineSpan> _parseInlineStyles(String text, TextStyle? baseStyle) {
    final spans = <InlineSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      final patterns = [
        _InlinePattern(
          RegExp(r'\*\*\*(.+?)\*\*\*'),
          (s) => s.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        _InlinePattern(
          RegExp(r'\*\*(.+?)\*\*'),
          (s) => s.copyWith(fontWeight: FontWeight.bold),
        ),
        _InlinePattern(
          RegExp(r'\*(.+?)\*'),
          (s) => s.copyWith(fontStyle: FontStyle.italic),
        ),
        _InlinePattern(
          RegExp(r'~~(.+?)~~'),
          (s) => s.copyWith(
            decoration: TextDecoration.lineThrough,
            color: AppColors.textTertiary,
          ),
        ),
        _InlinePattern(
          RegExp(r'<u>(.+?)</u>'),
          (s) => s.copyWith(decoration: TextDecoration.underline),
        ),
        _InlinePattern(
          RegExp(r'`(.+?)`'),
          (s) => s.copyWith(
            fontFamily: 'monospace',
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.purple,
          ),
        ),
        _InlinePattern(
          RegExp(r'\[(.+?)\]\((.+?)\)'),
          (s) => s.copyWith(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
          isLink: true,
        ),
      ];

      _InlineMatch? bestMatch;
      for (final pattern in patterns) {
        final match = pattern.regex.firstMatch(remaining);
        if (match != null) {
          if (bestMatch == null || match.start < bestMatch.match.start) {
            bestMatch = _InlineMatch(match, pattern);
          }
        }
      }

      if (bestMatch == null) {
        spans.add(TextSpan(text: remaining, style: baseStyle));
        break;
      }

      if (bestMatch.match.start > 0) {
        spans.add(
          TextSpan(
            text: remaining.substring(0, bestMatch.match.start),
            style: baseStyle,
          ),
        );
      }

      if (bestMatch.pattern.isLink) {
        spans.add(
          TextSpan(
            text: bestMatch.match.group(1),
            style:
                bestMatch.pattern.styleBuilder(baseStyle ?? const TextStyle()),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: bestMatch.match.group(1),
            style:
                bestMatch.pattern.styleBuilder(baseStyle ?? const TextStyle()),
          ),
        );
      }

      remaining = remaining.substring(bestMatch.match.end);
    }

    return spans;
  }

  Widget _buildHeading(String text, int level, BuildContext context) {
    final sizes = {1: 24.0, 2: 20.0, 3: 18.0};
    final fontSize = sizes[level] ?? 16.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildQuote(String text, TextStyle? baseStyle, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: _buildRichText(text, baseStyle, context),
    );
  }

  Widget _buildCodeBlock(String code, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppColors.darkTextPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletItem(
    String text,
    TextStyle? baseStyle,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(child: _buildRichText(text, baseStyle, context)),
        ],
      ),
    );
  }

  Widget _buildOrderedItem(
    String text,
    String number,
    TextStyle? baseStyle,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: baseStyle?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: _buildRichText(text, baseStyle, context)),
        ],
      ),
    );
  }

  Widget _buildTodoItem(
    String text,
    bool isChecked,
    TextStyle? baseStyle,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isChecked ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: _buildRichText(
              text,
              isChecked
                  ? baseStyle?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textTertiary,
                    )
                  : baseStyle,
              context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Widget> items, bool ordered) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}

class _InlinePattern {
  final RegExp regex;
  final TextStyle Function(TextStyle) styleBuilder;
  final bool isLink;

  _InlinePattern(this.regex, this.styleBuilder, {this.isLink = false});
}

class _InlineMatch {
  final RegExpMatch match;
  final _InlinePattern pattern;

  _InlineMatch(this.match, this.pattern);
}
