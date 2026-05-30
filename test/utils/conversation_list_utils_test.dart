import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/models/conversation.dart';
import 'package:momlaunchpad_mobile/utils/conversation_list_utils.dart';

Conversation _conversation({
  required String id,
  required String title,
  required DateTime updatedAt,
  bool isStarred = false,
}) {
  return Conversation(
    id: id,
    userId: 'user-1',
    title: title,
    isStarred: isStarred,
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}

void main() {
  final now = DateTime(2026, 5, 30, 15, 0);

  test('isGenericConversationTitle detects placeholder titles', () {
    expect(isGenericConversationTitle('New conversation'), isTrue);
    expect(isGenericConversationTitle('Chat May 30, 3:00 PM'), isTrue);
    expect(isGenericConversationTitle('Morning sickness tips'), isFalse);
  });

  test('titleFromFirstMessage truncates long prompts', () {
    final long = 'a' * 60;
    expect(titleFromFirstMessage(long).endsWith('…'), isTrue);
    expect(titleFromFirstMessage('Is cramping normal at 20 weeks?'),
        'Is cramping normal at 20 weeks?');
  });

  test('groupConversationsByDate separates pinned and date buckets', () {
    final conversations = [
      _conversation(
        id: '1',
        title: 'Pinned chat',
        updatedAt: now.subtract(const Duration(days: 10)),
        isStarred: true,
      ),
      _conversation(
        id: '2',
        title: 'Today chat',
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      _conversation(
        id: '3',
        title: 'Yesterday chat',
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];

    final sections = groupConversationsByDate(conversations, now: now);

    expect(sections.length, 3);
    expect(sections[0].section, ConversationListSection.pinned);
    expect(sections[0].conversations.single.id, '1');
    expect(sections[1].section, ConversationListSection.today);
    expect(sections[2].section, ConversationListSection.yesterday);
  });
}
