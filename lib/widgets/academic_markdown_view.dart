import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transforms raw LaTeX equations into clean, human-readable Unicode mathematical expressions.
class AcademicMathSanitizer {
  static String clean(String input) {
    String s = input.trim();

    // Strip $$...$$ or $...$
    if (s.startsWith(r'$$') && s.endsWith(r'$$') && s.length >= 4) {
      s = s.substring(2, s.length - 2).trim();
    } else if (s.startsWith(r'$') && s.endsWith(r'$') && s.length >= 2) {
      s = s.substring(1, s.length - 1).trim();
    }

    // Replace \frac{numerator}{denominator} with (numerator) / (denominator)
    final fracReg = RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}');
    while (fracReg.hasMatch(s)) {
      s = s.replaceAllMapped(fracReg, (m) {
        final num = clean(m.group(1)!);
        final den = clean(m.group(2)!);
        final numStr = num.contains(' ') || num.contains('+') || num.contains('-') || num.contains('±')
            ? '($num)'
            : num;
        final denStr = den.contains(' ') || den.contains('+') || den.contains('-')
            ? '($den)'
            : den;
        return '$numStr / $denStr';
      });
    }

    // Replace \sqrt{arg} or \sqrt[n]{arg}
    s = s.replaceAllMapped(RegExp(r'\\sqrt\{([^{}]+)\}'), (m) => '√(${clean(m.group(1)!)} )');
    s = s.replaceAllMapped(RegExp(r'\\sqrt\[([^{}]+)\]\{([^{}]+)\}'), (m) => '${clean(m.group(1)!)}√(${clean(m.group(2)!)} )');

    // Mathematical symbols
    s = s.replaceAll(r'\pm', '±');
    s = s.replaceAll(r'\mp', '∓');
    s = s.replaceAll(r'\neq', '≠');
    s = s.replaceAll(r'\leq', '≤');
    s = s.replaceAll(r'\geq', '≥');
    s = s.replaceAll(r'\approx', '≈');
    s = s.replaceAll(r'\equiv', '≡');
    s = s.replaceAll(r'\times', '×');
    s = s.replaceAll(r'\cdot', '·');
    s = s.replaceAll(r'\div', '÷');
    s = s.replaceAll(r'\infty', '∞');
    s = s.replaceAll(r'\rightarrow', '→');
    s = s.replaceAll(r'\Rightarrow', '⇒');
    s = s.replaceAll(r'\degree', '°');
    s = s.replaceAll(r'\circ', '°');

    // Greek symbols
    s = s.replaceAll(r'\alpha', 'α');
    s = s.replaceAll(r'\beta', 'β');
    s = s.replaceAll(r'\gamma', 'γ');
    s = s.replaceAll(r'\theta', 'θ');
    s = s.replaceAll(r'\pi', 'π');
    s = s.replaceAll(r'\omega', 'ω');
    s = s.replaceAll(r'\lambda', 'λ');
    s = s.replaceAll(r'\mu', 'μ');
    s = s.replaceAll(r'\sigma', 'σ');
    s = s.replaceAll(r'\Delta', 'Δ');
    s = s.replaceAll(r'\Omega', 'Ω');

    // Superscripts
    s = s.replaceAllMapped(RegExp(r'\^\{([0-9a-zA-Z\+\-]+)\}'), (m) => _toSuperscript(m.group(1)!));
    s = s.replaceAllMapped(RegExp(r'\^([0-9a-zA-Z\+\-])'), (m) => _toSuperscript(m.group(1)!));

    // Subscripts
    s = s.replaceAllMapped(RegExp(r'_\{([0-9a-zA-Z\+\-]+)\}'), (m) => _toSubscript(m.group(1)!));
    s = s.replaceAllMapped(RegExp(r'_([0-9a-zA-Z\+\-])'), (m) => _toSubscript(m.group(1)!));

    // Remove text commands & spacing
    s = s.replaceAllMapped(RegExp(r'\\text\{([^{}]+)\}'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'\\mathbf\{([^{}]+)\}'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'\\mathrm\{([^{}]+)\}'), (m) => m.group(1)!);
    s = s.replaceAll(r'\left', '');
    s = s.replaceAll(r'\right', '');
    s = s.replaceAll(r'\,', ' ');
    s = s.replaceAll(r'\;', ' ');
    s = s.replaceAll(r'\quad', '   ');

    return s.trim();
  }

  static String _toSuperscript(String str) {
    const map = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽', ')': '⁾',
      'n': 'ⁿ', 'i': 'ⁱ', 'x': 'ˣ', 'y': 'ʸ', 'a': 'ᵃ', 'b': 'ᵇ',
    };
    return str.split('').map((c) => map[c] ?? c).join();
  }

  static String _toSubscript(String str) {
    const map = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      '+': '₊', '-': '₋', '=': '₌', '(': '₍', ')': '₎',
      'a': 'ₐ', 'e': 'ₑ', 'o': 'ₒ', 'x': 'ₓ', 'i': 'ᵢ', 'j': 'ⱼ',
    };
    return str.split('').map((c) => map[c] ?? c).join();
  }
}

/// Rich academic markdown and LaTeX-aware view widget.
/// Parses Headings, Code Blocks, Formulas, Bullet/Numbered Lists,
/// Dividers, Bold/Italic formatting and guarantees Urdu RTL and English LTR alignment.
class AcademicMarkdownView extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final bool selectable;

  const AcademicMarkdownView({
    super.key,
    required this.text,
    this.baseStyle,
    this.selectable = true,
  });

  static bool isUrduText(String str) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = baseStyle ??
        TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
        );

    final blocks = _parseBlocks(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks.map((b) => _renderBlock(context, b, defaultStyle, isDark)).toList(),
    );
  }

  Widget _renderBlock(BuildContext context, _Block block, TextStyle defaultStyle, bool isDark) {
    switch (block.type) {
      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            height: 16,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        );

      case _BlockType.code:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFF334155),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      block.language.isNotEmpty ? block.language.toUpperCase() : 'CODE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: block.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard!'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                          SizedBox(width: 4),
                          Text('Copy', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  block.content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
              ),
            ],
          ),
        );

      case _BlockType.formula:
        final cleanFormula = AcademicMathSanitizer.clean(block.content);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.6) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.functions_rounded, size: 16, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Center(
                  child: SelectableText(
                    cleanFormula,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF3730A3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case _BlockType.heading:
        final cleanH = _sanitizeInlineMath(block.content);
        final isUrdu = isUrduText(cleanH);
        final hStyle = defaultStyle.copyWith(
          fontSize: block.level == 1 ? 16.5 : (block.level == 2 ? 15.5 : 14.5),
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
          height: 1.4,
        );

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText.rich(
                    _buildInlineSpans(cleanH, hStyle, isDark),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        );

      case _BlockType.listItem:
        final cleanBody = _sanitizeInlineMath(block.content);
        final isUrdu = isUrduText(cleanBody);
        final itemStyle = defaultStyle.copyWith(
          height: isUrdu ? 1.65 : 1.5,
        );

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    top: 2,
                    right: isUrdu ? 0 : 8,
                    left: isUrdu ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    block.marker,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText.rich(
                    _buildInlineSpans(cleanBody, itemStyle, isDark),
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        );

      case _BlockType.paragraph:
        final cleanP = _sanitizeInlineMath(block.content);
        final isUrdu = isUrduText(cleanP);
        final pStyle = defaultStyle.copyWith(
          height: isUrdu ? 1.65 : 1.5,
        );

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SelectableText.rich(
              _buildInlineSpans(cleanP, pStyle, isDark),
              textAlign: isUrdu ? TextAlign.right : TextAlign.left,
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        );
    }
  }

  /// Sanitizes inline $math$ occurrences into clean unicode
  static String _sanitizeInlineMath(String text) {
    final reg = RegExp(r'\$([^\$]+)\$');
    return text.replaceAllMapped(reg, (m) {
      final rawMath = m.group(1)!;
      return AcademicMathSanitizer.clean(rawMath);
    });
  }

  /// Parses inline bold (**text**), italic (*text*), inline code (`code`), and clean text.
  TextSpan _buildInlineSpans(String rawText, TextStyle baseStyle, bool isDark) {
    final spans = <InlineSpan>[];
    // Regex matching bold, code, italic
    final pattern = RegExp(r'(\*\*[^*]+\*\*)|(`[^`]+`)|(\*[^*]+\*)');
    int lastEnd = 0;

    for (final match in pattern.allMatches(rawText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: rawText.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final matched = match.group(0)!;
      if (matched.startsWith('**') && matched.endsWith('**') && matched.length >= 4) {
        final inner = matched.substring(2, matched.length - 2);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ));
      } else if (matched.startsWith('`') && matched.endsWith('`') && matched.length >= 2) {
        final inner = matched.substring(1, matched.length - 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: Text(
              inner,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * 0.9 : 12,
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      } else if (matched.startsWith('*') && matched.endsWith('*') && matched.length >= 2) {
        final inner = matched.substring(1, matched.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Parses text into structured blocks
  List<_Block> _parseBlocks(String fullText) {
    final blocks = <_Block>[];
    final lines = fullText.split('\n');

    bool inCodeBlock = false;
    String codeLang = '';
    final codeBuffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Code block start/end
      if (trimmed.startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeLang = trimmed.substring(3).trim();
          codeBuffer.clear();
        } else {
          inCodeBlock = false;
          blocks.add(_Block(
            type: _BlockType.code,
            content: codeBuffer.toString().trimRight(),
            language: codeLang,
          ));
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.writeln(line);
        continue;
      }

      if (trimmed.isEmpty) {
        continue;
      }

      // Horizontal Divider
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        blocks.add(const _Block(type: _BlockType.divider, content: ''));
        continue;
      }

      // Display math formula ($$...$$ or lines starting with $$)
      if (trimmed.startsWith(r'$$') && trimmed.endsWith(r'$$') && trimmed.length > 2) {
        blocks.add(_Block(type: _BlockType.formula, content: trimmed));
        continue;
      }

      // Standalone formula line detection (e.g. \frac, \sqrt, or pure equation)
      if (trimmed.contains(r'\frac') ||
          trimmed.contains(r'\sqrt') ||
          (trimmed.startsWith(r'$$') && !trimmed.endsWith(r'$$'))) {
        // Collect multi-line display formula if open
        if (trimmed.startsWith(r'$$')) {
          final formBuf = StringBuffer(trimmed.substring(2));
          while (i + 1 < lines.length && !lines[i + 1].contains(r'$$')) {
            i++;
            formBuf.writeln(lines[i]);
          }
          if (i + 1 < lines.length && lines[i + 1].contains(r'$$')) {
            i++;
            final last = lines[i].replaceAll(r'$$', '');
            formBuf.writeln(last);
          }
          blocks.add(_Block(type: _BlockType.formula, content: formBuf.toString()));
          continue;
        } else {
          // Single line formula
          blocks.add(_Block(type: _BlockType.formula, content: trimmed));
          continue;
        }
      }

      // Headings
      if (trimmed.startsWith('#')) {
        int level = 0;
        while (level < trimmed.length && trimmed[level] == '#') {
          level++;
        }
        if (level > 0 && level <= 6 && trimmed.length > level && trimmed[level] == ' ') {
          blocks.add(_Block(
            type: _BlockType.heading,
            content: trimmed.substring(level).trim(),
            level: level,
          ));
          continue;
        }
      }

      // List Items (1. item, * item, - item)
      final listMatch = RegExp(r'^(\d+[\.\)]|\*|-|•)\s+(.*)$').firstMatch(trimmed);
      if (listMatch != null) {
        final marker = listMatch.group(1)!;
        final content = listMatch.group(2)!;
        blocks.add(_Block(
          type: _BlockType.listItem,
          content: content,
          marker: marker,
        ));
        continue;
      }

      // Regular Paragraph
      blocks.add(_Block(
        type: _BlockType.paragraph,
        content: trimmed,
      ));
    }

    return blocks;
  }
}

enum _BlockType {
  paragraph,
  heading,
  listItem,
  code,
  formula,
  divider,
}

class _Block {
  final _BlockType type;
  final String content;
  final int level;
  final String marker;
  final String language;

  const _Block({
    required this.type,
    required this.content,
    this.level = 1,
    this.marker = '•',
    this.language = '',
  });
}
