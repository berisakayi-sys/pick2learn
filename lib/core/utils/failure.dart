/// A small, friendly error type used across services so the UI can show
/// clear messages instead of raw exceptions.
///
/// Beginners get a plain-language [message]; developers can still read the
/// original [cause] in logs.
class Failure implements Exception {
  final String message;
  final Object? cause;

  const Failure(this.message, {this.cause});

  /// A few common, ready-made failures with friendly wording.
  factory Failure.network([Object? cause]) => Failure(
        "Couldn't connect. Please check your internet and try again.",
        cause: cause,
      );

  factory Failure.noApiKey() => const Failure(
        'No AI key set yet. Add one in Settings to get explanations.',
      );

  factory Failure.camera([Object? cause]) => Failure(
        "Couldn't open the camera. Please allow camera access and try again.",
        cause: cause,
      );

  factory Failure.ocr([Object? cause]) => Failure(
        "Couldn't read text from that image. Try a clearer, well-lit photo.",
        cause: cause,
      );

  factory Failure.unknown([Object? cause]) => Failure(
        'Something went wrong. Please try again.',
        cause: cause,
      );

  @override
  String toString() => 'Failure: $message${cause != null ? ' ($cause)' : ''}';
}
