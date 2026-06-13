/// Result of POST /api/community/posts/:id/evaluate-for-me
class CommunityThreadEvaluation {
  final String conversationId;
  final String title;
  final String evaluationPreview;
  final int messageCount;
  final String scope;

  const CommunityThreadEvaluation({
    required this.conversationId,
    required this.title,
    required this.evaluationPreview,
    required this.messageCount,
    this.scope = 'discussion',
  });

  factory CommunityThreadEvaluation.fromJson(Map<String, dynamic> json) {
    return CommunityThreadEvaluation(
      conversationId: json['conversation_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Community thread review',
      evaluationPreview: json['evaluation_preview']?.toString() ?? '',
      messageCount: json['message_count'] as int? ?? 0,
      scope: json['scope']?.toString() ?? 'discussion',
    );
  }
}
