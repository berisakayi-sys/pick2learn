import 'dart:async';

import 'package:flutter/material.dart';

/// A simple, friendly study timer (Pomodoro-style).
///
/// The student picks a focus length, presses start, and watches a circular
/// countdown. When focus ends it automatically suggests a short break.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Preset focus/break lengths in minutes the user can choose from.
  static const _focusPresets = [15, 25, 45, 60];
  static const _breakMinutes = 5;

  int _focusMinutes = 25;
  bool _isBreak = false;
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _totalSeconds =
          (_isBreak ? _breakMinutes : _focusMinutes) * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds <= 1) {
          _onComplete();
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  /// When a session ends, switch between focus and break automatically.
  void _onComplete() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isBreak = !_isBreak;
      _totalSeconds = (_isBreak ? _breakMinutes : _focusMinutes) * 60;
      _remainingSeconds = _totalSeconds;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBreak
            ? 'Nice work! Time for a $_breakMinutes-minute break. ☕'
            : 'Break over — ready to focus again? 📚'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String get _timeText {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : 1 - (_remainingSeconds / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        _isBreak ? theme.colorScheme.tertiary : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Focus / break label.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isBreak ? 'Break time' : 'Focus time',
                      style: theme.textTheme.labelLarge?.copyWith(color: accent),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // The circular countdown.
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 12,
                            backgroundColor:
                                accent.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        Text(
                          _timeText,
                          style: theme.textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Start/Pause + Reset controls.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggle,
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? 'Pause' : 'Start'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.stop),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Focus-length presets (disabled while running or on break).
                  if (!_isBreak) ...[
                    Text('Focus length', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _focusPresets.map((m) {
                        return ChoiceChip(
                          label: Text('$m min'),
                          selected: _focusMinutes == m,
                          onSelected: _running
                              ? null
                              : (_) {
                                  setState(() => _focusMinutes = m);
                                  _reset();
                                },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
