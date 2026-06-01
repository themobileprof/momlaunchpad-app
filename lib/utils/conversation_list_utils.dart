import '../models/conversation.dart';

/// Sidebar sections — familiar from ChatGPT/Claude, tuned for mobile.
enum ConversationListSection {
  pinned,
  today,
  yesterday,
  lastSevenDays,
  older,
}

class ConversationSection {
  final ConversationListSection section;
  final String label;
  final List<Conversation> conversations;

  const ConversationSection({
    required this.section,
    required this.label,
    required this.conversations,
  });
}

const defaultConversationTitle = 'New conversation';

/// Titles that should be replaced after the user's first message.
bool isGenericConversationTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return true;
  if (t == defaultConversationTitle || t == 'New Conversation') return true;
  if (t.startsWith('Chat ')) return true;
  return false;
}

/// Short title from the first user message (ChatGPT-style auto naming).
String titleFromFirstMessage(String content) {
  final cleaned = content.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return defaultConversationTitle;
  if (cleaned.length <= 48) return cleaned;
  return '${cleaned.substring(0, 45)}…';
}

String conversationDisplayTitle(String title) {
  if (title.trim().isEmpty) return defaultConversationTitle;
  if (isGenericConversationTitle(title)) return defaultConversationTitle;
  return title.trim();
}

/// e.g. "Active today · 2:30 PM", "Active yesterday", "Active Mon · Jan 12"
String conversationActivityLabel(DateTime updatedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final updatedLocal = updatedAt.toLocal();
  final updatedDay = DateTime(
    updatedLocal.year,
    updatedLocal.month,
    updatedLocal.day,
  );
  final today = DateTime(reference.year, reference.month, reference.day);
  final difference = today.difference(updatedDay).inDays;

  final time = _formatTime(updatedLocal);

  if (difference == 0) return 'Active today · $time';
  if (difference == 1) return 'Active yesterday · $time';
  if (difference < 7) {
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return 'Active ${weekdays[updatedLocal.weekday - 1]} · $time';
  }

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return 'Active ${months[updatedLocal.month - 1]} ${updatedLocal.day}';
}

String sectionLabel(ConversationListSection section) {
  switch (section) {
    case ConversationListSection.pinned:
      return 'Pinned';
    case ConversationListSection.today:
      return 'Today';
    case ConversationListSection.yesterday:
      return 'Yesterday';
    case ConversationListSection.lastSevenDays:
      return 'Previous 7 days';
    case ConversationListSection.older:
      return 'Older';
  }
}

ConversationListSection sectionForDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(reference.year, reference.month, reference.day);
  final difference = today.difference(day).inDays;

  if (difference == 0) return ConversationListSection.today;
  if (difference == 1) return ConversationListSection.yesterday;
  if (difference < 7) return ConversationListSection.lastSevenDays;
  return ConversationListSection.older;
}

/// Groups conversations for the sidebar: pinned first, then by last activity.
List<ConversationSection> groupConversationsByDate(
  List<Conversation> conversations, {
  DateTime? now,
}) {
  if (conversations.isEmpty) return [];

  final sorted = List<Conversation>.from(conversations)
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final pinned = sorted.where((c) => c.isStarred).toList();
  final unpinned = sorted.where((c) => !c.isStarred).toList();

  final sections = <ConversationSection>[];

  if (pinned.isNotEmpty) {
    sections.add(ConversationSection(
      section: ConversationListSection.pinned,
      label: sectionLabel(ConversationListSection.pinned),
      conversations: pinned,
    ));
  }

  ConversationListSection? currentSection;
  final currentItems = <Conversation>[];

  void flush() {
    final section = currentSection;
    if (section == null || currentItems.isEmpty) return;
    sections.add(ConversationSection(
      section: section,
      label: sectionLabel(section),
      conversations: List.from(currentItems),
    ));
    currentItems.clear();
  }

  for (final conversation in unpinned) {
    final section = sectionForDate(conversation.updatedAt, now: now);
    if (currentSection != section) {
      flush();
      currentSection = section;
    }
    currentItems.add(conversation);
  }
  flush();

  return sections;
}

String _formatTime(DateTime date) {
  final hour = date.hour > 12
      ? date.hour - 12
      : (date.hour == 0 ? 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
