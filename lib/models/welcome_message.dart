/// Daily personalized welcome message from the backend.
class WelcomeMessage {
  final String message;
  final DateTime cacheDate;
  final String source;

  const WelcomeMessage({
    required this.message,
    required this.cacheDate,
    required this.source,
  });

  factory WelcomeMessage.fromJson(Map<String, dynamic> json) {
    return WelcomeMessage(
      message: json['message'] as String,
      cacheDate: DateTime.parse(json['cache_date'] as String),
      source: json['source'] as String? ?? 'gemini',
    );
  }

  bool get isFromGemini => source == 'gemini' || source == 'cache';
}
