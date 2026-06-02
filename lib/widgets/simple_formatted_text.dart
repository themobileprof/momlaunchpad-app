import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Minimal rich text: **bold**, *italic*, bullets, and links.
class SimpleFormattedText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SimpleFormattedText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? AppTypography.bodyText.copyWith(color: context.appInk);
    final linkColor = context.appPrimary;
    final spans = _parseInline(text, baseStyle, linkColor);
    return RichText(text: TextSpan(children: spans));
  }

  List<InlineSpan> _parseInline(String input, TextStyle base, Color linkColor) {
    final lines = input.split('\n');
    final spans = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('• ')) {
        spans.add(TextSpan(text: '  • ', style: base));
        spans.addAll(_parseLine(line.replaceFirst(RegExp(r'^\s*[-•]\s*'), ''), base, linkColor));
      } else {
        spans.addAll(_parseLine(line, base, linkColor));
      }
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  List<InlineSpan> _parseLine(String line, TextStyle base, Color linkColor) {
    final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|\[[^\]]+\]\([^)]+\))');
    final spans = <InlineSpan>[];
    var start = 0;

    for (final match in pattern.allMatches(line)) {
      if (match.start > start) {
        spans.add(TextSpan(text: line.substring(start, match.start), style: base));
      }
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('*')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      } else {
        final linkMatch = RegExp(r'\[([^\]]+)\]\(([^)]+)\)').firstMatch(token);
        if (linkMatch != null) {
          final label = linkMatch.group(1)!;
          final url = linkMatch.group(2)!;
          spans.add(TextSpan(
            text: label,
            style: base.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // URLs open via platform handler in a future iteration.
                debugPrint('Open link: $url');
              },
          ));
        }
      }
      start = match.end;
    }

    if (start < line.length) {
      spans.add(TextSpan(text: line.substring(start), style: base));
    }
    return spans;
  }
}
