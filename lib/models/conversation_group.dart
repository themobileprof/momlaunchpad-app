import 'message.dart';

/// Groups messages into conversations based on time gaps
class ConversationGroup {
  final DateTime startTime;
  final List<Message> messages;

  ConversationGroup({
    required this.startTime,
    required this.messages,
  });

  /// Format date header (e.g., "Today", "Yesterday", "January 10, 2026")
  String get dateHeader {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(startTime.year, startTime.month, startTime.day);
    
    final difference = today.difference(messageDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekday[startTime.weekday - 1];
    } else {
      final month = ['January', 'February', 'March', 'April', 'May', 'June',
                     'July', 'August', 'September', 'October', 'November', 'December'];
      return '${month[startTime.month - 1]} ${startTime.day}, ${startTime.year}';
    }
  }

  /// Format start time (e.g., "2:30 PM")
  String get timeHeader {
    final hour = startTime.hour > 12 ? startTime.hour - 12 : (startTime.hour == 0 ? 12 : startTime.hour);
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Groups messages into conversations based on time gaps
/// Messages separated by more than 30 minutes start a new conversation
List<ConversationGroup> groupMessagesByConversation(List<Message> messages) {
  if (messages.isEmpty) return [];

  const conversationGapMinutes = 30;
  final groups = <ConversationGroup>[];
  var currentGroup = <Message>[messages.first];
  var groupStartTime = messages.first.timestamp;

  for (var i = 1; i < messages.length; i++) {
    final prevMessage = messages[i - 1];
    final currentMessage = messages[i];
    final gap = currentMessage.timestamp.difference(prevMessage.timestamp);

    if (gap.inMinutes > conversationGapMinutes) {
      // Start new conversation
      groups.add(ConversationGroup(
        startTime: groupStartTime,
        messages: List.from(currentGroup),
      ));
      currentGroup = [currentMessage];
      groupStartTime = currentMessage.timestamp;
    } else {
      // Continue current conversation
      currentGroup.add(currentMessage);
    }
  }

  // Add final group
  if (currentGroup.isNotEmpty) {
    groups.add(ConversationGroup(
      startTime: groupStartTime,
      messages: List.from(currentGroup),
    ));
  }

  return groups;
}
