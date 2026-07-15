import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/failure.dart';
import '../models/chat_message.dart';
import '../models/subject.dart';

/// Talks to the cloud AI (Anthropic Claude) to do two jobs:
///
///  1. **Read a homework photo** (vision OCR) — works on every platform,
///     including iOS 12.5.7 and Web, because the heavy lifting happens in the
///     cloud, not on the device.
///  2. **Explain answers step by step**, and answer follow-up questions.
///
/// Everything is wrapped so the UI only ever sees friendly [Failure] errors.
///
/// NOTE: This uses a user-supplied API key stored on the device (see Settings).
/// For a production app you'd normally proxy these calls through your own
/// backend so the key never ships in the client — but a direct key keeps this
/// example simple and fully self-contained.
class AiService {
  final http.Client _client;

  AiService({http.Client? client}) : _client = client ?? http.Client();

  /// Reads printed or handwritten text from an image.
  ///
  /// [imageBytes] is the raw photo; [mediaType] is e.g. "image/jpeg".
  /// Returns the extracted text (best effort).
  Future<String> extractTextFromImage({
    required List<int> imageBytes,
    required String mediaType,
    required String apiKey,
    required String model,
  }) async {
    if (apiKey.trim().isEmpty) throw Failure.noApiKey();

    final base64Image = base64Encode(imageBytes);

    const instruction =
        'You are an OCR engine for a homework helper app. Read ALL the text '
        'in this image exactly as written, preserving line breaks, numbers, '
        'and math symbols. If it is a worksheet, keep question numbers. '
        'Return ONLY the text you see — no commentary, no explanations.';

    final body = {
      'model': model,
      'max_tokens': 1500,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Image,
              },
            },
            {'type': 'text', 'text': instruction},
          ],
        },
      ],
    };

    final text = await _postAndReadText(body, apiKey);
    if (text.trim().isEmpty) throw Failure.ocr();
    return text.trim();
  }

  /// Produces the first, full explanation for a homework question.
  ///
  /// When [showOnlyAnswer] is true, the model returns just the final answer.
  /// Otherwise it returns a clear, step-by-step explanation tuned for the
  /// given [subject] and a beginner audience.
  Future<String> explainQuestion({
    required String question,
    required Subject subject,
    required bool showOnlyAnswer,
    required String apiKey,
    required String model,
  }) async {
    if (apiKey.trim().isEmpty) throw Failure.noApiKey();

    final system = _buildSystemPrompt(subject, showOnlyAnswer);

    final body = {
      'model': model,
      'max_tokens': 2000,
      'system': system,
      'messages': [
        {'role': 'user', 'content': question},
      ],
    };

    return _postAndReadText(body, apiKey);
  }

  /// Answers a follow-up question, given the full prior conversation so the
  /// model has context of what was already explained.
  Future<String> askFollowUp({
    required List<ChatMessage> history,
    required String followUp,
    required Subject subject,
    required bool showOnlyAnswer,
    required String apiKey,
    required String model,
  }) async {
    if (apiKey.trim().isEmpty) throw Failure.noApiKey();

    final system = _buildSystemPrompt(subject, showOnlyAnswer);

    // Convert our ChatMessage history into the API's message format.
    final messages = history
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList()
      ..add({'role': 'user', 'content': followUp});

    final body = {
      'model': model,
      'max_tokens': 2000,
      'system': system,
      'messages': messages,
    };

    return _postAndReadText(body, apiKey);
  }

  // --- Internals ---------------------------------------------------------

  /// Builds the "system prompt" — the instructions that shape how the AI
  /// answers. This is where the teaching style and subject awareness live.
  String _buildSystemPrompt(Subject subject, bool showOnlyAnswer) {
    final subjectName =
        subject == Subject.general ? 'school homework' : subject.label;

    if (showOnlyAnswer) {
      return 'You are Pick2Learn, a friendly homework helper for students. '
          'The topic is $subjectName. Give ONLY the final answer, as briefly '
          'as possible. Use LaTeX between \$ signs for any math.';
    }

    return '''
You are Pick2Learn, a patient, encouraging homework tutor for students of all ages.
The topic is $subjectName.

How to answer:
- Explain the answer STEP BY STEP so the student learns, not just copies.
- Start with a one-sentence summary of what the question is asking.
- Number each step and keep language simple and beginner-friendly.
- Show your work. For math/science, write equations using LaTeX between \$ signs
  (for example: \$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$).
- End with a short "**Final answer:**" line.
- If the question is unclear, make a reasonable assumption and say so.
- Keep it accurate and honest. If you are unsure, say what you're unsure about.
- Use short Markdown headings and bullet points where helpful.
''';
  }

  /// Sends the request and returns the assistant's text, converting any
  /// failure (network, auth, rate limit, bad response) into a [Failure].
  Future<String> _postAndReadText(
      Map<String, dynamic> body, String apiKey) async {
    http.Response res;
    try {
      res = await _client.post(
        Uri.parse(AppConstants.anthropicBaseUrl),
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': AppConstants.anthropicVersion,
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw Failure.network(e);
    }

    if (res.statusCode == 401) {
      throw const Failure('Your AI key was rejected. Check it in Settings.');
    }
    if (res.statusCode == 429) {
      throw const Failure('Too many requests right now. Please wait a moment.');
    }
    if (res.statusCode >= 400) {
      throw Failure('AI service error (${res.statusCode}). Please try again.',
          cause: res.body);
    }

    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final content = decoded['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw Failure.unknown('Empty response');
      }
      // Concatenate all text blocks in the response.
      final buffer = StringBuffer();
      for (final block in content) {
        if (block is Map && block['type'] == 'text') {
          buffer.write(block['text'] as String? ?? '');
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure.unknown(e);
    }
  }

  void dispose() => _client.close();
}
