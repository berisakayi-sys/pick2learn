import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_expressions/math_expressions.dart';

import '../../core/utils/responsive.dart';
import '../../models/subject.dart';
import '../../providers/homework_provider.dart';
import '../answer/answer_screen.dart';

/// A friendly calculator that evaluates typed math expressions instantly and
/// can also send the expression to the AI for a full step-by-step explanation.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  bool _explaining = false;

  /// The calculator button layout. Some keys are "actions" (C, ⌫, =).
  static const _keys = [
    ['C', '(', ')', '⌫'],
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '-'],
    ['0', '.', '=', '+'],
  ];

  void _onKey(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expression = '';
          _result = '';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          break;
        case '=':
          _evaluate();
          break;
        default:
          _expression += key;
          _liveEvaluate();
      }
    });
  }

  /// Converts the pretty symbols to ones the parser understands.
  String _normalized(String input) =>
      input.replaceAll('×', '*').replaceAll('÷', '/');

  /// Tries to evaluate as the user types; silently ignores incomplete input.
  void _liveEvaluate() {
    try {
      final value = _compute(_expression);
      _result = value;
    } catch (_) {
      _result = ''; // Not a complete expression yet.
    }
  }

  void _evaluate() {
    try {
      _result = _compute(_expression);
    } catch (_) {
      _result = 'Not a valid expression';
    }
  }

  /// Parses and evaluates a math expression, returning a tidy string.
  String _compute(String raw) {
    if (raw.trim().isEmpty) return '';
    final parser = GrammarParser();
    final exp = parser.parse(_normalized(raw));
    final result = exp.evaluate(EvaluationType.REAL, ContextModel()) as double;
    // Show integers without a trailing ".0".
    if (result == result.roundToDouble()) {
      return result.toInt().toString();
    }
    return result.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '');
  }

  /// Sends the current expression to the AI for a worked, step-by-step solution.
  Future<void> _explainWithAi() async {
    if (_expression.trim().isEmpty) return;
    setState(() => _explaining = true);
    try {
      final item = await ref.read(homeworkControllerProvider).createAndExplain(
            question: 'Solve step by step: ${_normalized(_expression)}',
            subject: Subject.math,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AnswerScreen(item: item)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Failure: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _explaining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Math Calculator')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // The display: expression on top, live result below.
                Expanded(
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _expression.isEmpty ? '0' : _expression,
                            style: theme.textTheme.displaySmall,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // "Explain with AI" shortcut.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: OutlinedButton.icon(
                    onPressed: _explaining ? null : _explainWithAi,
                    icon: _explaining
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Explain step by step with AI'),
                  ),
                ),
                const SizedBox(height: 8),
                // The keypad.
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: _keys
                        .map((row) => Row(
                              children: row
                                  .map((key) => _CalcButton(
                                        label: key,
                                        onTap: () => _onKey(key),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single calculator key. Operators and actions get accent colors.
class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CalcButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAction = ['C', '⌫', '='].contains(label);
    final isOperator = ['+', '-', '×', '÷', '(', ')'].contains(label);

    Color bg;
    Color fg;
    if (label == '=') {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else if (isAction) {
      bg = theme.colorScheme.errorContainer;
      fg = theme.colorScheme.onErrorContainer;
    } else if (isOperator) {
      bg = theme.colorScheme.secondaryContainer;
      fg = theme.colorScheme.onSecondaryContainer;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      fg = theme.colorScheme.onSurface;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: fg, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
