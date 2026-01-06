/// Chat utility functions

/// Check if message is small talk (instant response, no AI call)
bool isSmallTalk(String content) {
  final normalized = content.toLowerCase().trim();
  final smallTalkPatterns = [
    'hello',
    'hi',
    'hey',
    'thanks',
    'thank you',
    'bye',
    'goodbye',
    'how are you',
    'what\'s up',
    'sup',
  ];

  return smallTalkPatterns.any((pattern) => normalized.contains(pattern));
}

/// Check if message is a symptom report (high priority)
bool isSymptomReport(String content) {
  final normalized = content.toLowerCase().trim();
  final symptomPatterns = [
    'i have',
    'i\'m experiencing',
    'i feel',
    'i\'m feeling',
    'is it normal',
    'pain',
    'headache',
    'nauseous',
    'cramping',
    'bleeding',
    'spotting',
  ];

  return symptomPatterns.any((pattern) => normalized.contains(pattern));
}

/// Format message timestamp
String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
