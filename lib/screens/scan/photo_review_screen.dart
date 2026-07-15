import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../models/subject.dart';
import '../../providers/homework_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/image_service.dart';
import '../../widgets/subject_picker.dart';
import '../answer/answer_screen.dart';

/// After a photo is taken/uploaded/scanned, this screen:
///   1. shows the image,
///   2. runs cloud OCR to read the text (works on iOS 12.5.7 + web),
///   3. lets the user fix any misread text and pick a subject,
///   4. gets the step-by-step explanation.
class PhotoReviewScreen extends ConsumerStatefulWidget {
  final PickedImage image;

  const PhotoReviewScreen({super.key, required this.image});

  @override
  ConsumerState<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends ConsumerState<PhotoReviewScreen> {
  final _textController = TextEditingController();
  Subject _subject = Subject.general;
  bool _ocrRunning = true;
  bool _explaining = false;
  String? _ocrError;

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Sends the image to the AI vision service to extract its text.
  Future<void> _runOcr() async {
    setState(() {
      _ocrRunning = true;
      _ocrError = null;
    });

    final settings = ref.read(settingsProvider);
    try {
      final text = await ref.read(aiServiceProvider).extractTextFromImage(
            imageBytes: widget.image.bytes,
            mediaType: widget.image.mediaType,
            apiKey: settings.apiKey,
            model: settings.model,
          );
      if (!mounted) return;
      setState(() {
        _textController.text = text;
        _ocrRunning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrRunning = false;
        _ocrError = e.toString().replaceFirst('Failure: ', '');
      });
    }
  }

  /// Explains the (possibly edited) text.
  Future<void> _explain() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text to explain yet.')),
      );
      return;
    }

    setState(() => _explaining = true);
    try {
      final item = await ref.read(homeworkControllerProvider).createAndExplain(
            question: text,
            subject: _subject,
            imagePath: widget.image.savedPath,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AnswerScreen(item: item)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _explaining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Failure: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Read')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // The captured image preview.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: _buildImage(),
                  ),
                ),
                const SizedBox(height: 20),

                if (_ocrRunning)
                  _buildOcrLoading(theme)
                else ...[
                  Text('Subject', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SubjectPicker(
                    selected: _subject,
                    onChanged: (s) => setState(() => _subject = s),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Text we read', style: theme.textTheme.labelLarge),
                      TextButton.icon(
                        onPressed: _runOcr,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Re-scan'),
                      ),
                    ],
                  ),
                  if (_ocrError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_ocrError!,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _textController,
                    minLines: 4,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      hintText: 'The text from your photo appears here. '
                          'You can fix anything that was misread.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _explaining ? null : _explain,
                    icon: _explaining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_explaining ? 'Thinking…' : 'Explain This'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the picked image. Web has bytes only; other platforms may have a file.
  Widget _buildImage() {
    if (!kIsWeb &&
        widget.image.savedPath != null &&
        File(widget.image.savedPath!).existsSync()) {
      return Image.file(File(widget.image.savedPath!), fit: BoxFit.contain);
    }
    return Image.memory(widget.image.bytes, fit: BoxFit.contain);
  }

  Widget _buildOcrLoading(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Reading your homework…',
            style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text('This uses the internet so it works even on older devices.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
