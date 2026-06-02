import 'package:flutter/material.dart';
import '../models/symptom.dart';
import '../screens/chat_screen.dart';

/// Opens the chat conversation where a symptom was first reported.
Future<void> openSymptomSourceChat(BuildContext context, Symptom symptom) async {
  if (!symptom.hasSourceChat) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        conversationId: symptom.conversationId!,
        conversationTitle: 'Chat about ${symptom.symptomTypeName.toLowerCase()}',
      ),
    ),
  );
}

/// Link button shown when a symptom is tied to a source chat message.
class SymptomSourceChatLink extends StatelessWidget {
  final Symptom symptom;
  final EdgeInsetsGeometry? padding;

  const SymptomSourceChatLink({
    super.key,
    required this.symptom,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!symptom.hasSourceChat) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => openSymptomSourceChat(context, symptom),
        icon: Icon(Icons.chat_bubble_outline, size: 16),
        label: const Text('View source chat'),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: padding ?? EdgeInsets.zero,
        ),
      ),
    );
  }
}
