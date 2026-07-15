import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Renders the AI's answer text, which is Markdown that may contain LaTeX math
/// wrapped in `$...$`.
///
/// We teach flutter_markdown a tiny custom rule: any text between single dollar
/// signs is a "math" node, which we render with flutter_math_fork so equations
/// look beautiful. Everything else renders as normal Markdown (headings, bold,
/// lists, etc.).
class MathMarkdown extends StatelessWidget {
  final String data;

  const MathMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: true,
      // Register our custom inline math syntax + its renderer.
      inlineSyntaxes: [_MathInlineSyntax()],
      builders: {'math': _MathElementBuilder(theme)},
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        code: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Matches inline math delimited by single `$` signs, e.g. `$x^2 + 1$`.
class _MathInlineSyntax extends md.InlineSyntax {
  // Non-greedy match between two dollar signs (not escaped).
  _MathInlineSyntax() : super(r'\$([^$\n]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('math', match[1] ?? '');
    parser.addNode(element);
    return true;
  }
}

/// Turns a `math` node into a rendered equation using flutter_math_fork.
class _MathElementBuilder extends MarkdownElementBuilder {
  final ThemeData theme;
  _MathElementBuilder(this.theme);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tex = element.textContent;
    return Math.tex(
      tex,
      textStyle: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18),
      // If the LaTeX is malformed, show the raw text instead of crashing.
      onErrorFallback: (err) => Text(
        '\$$tex\$',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
    );
  }
}
