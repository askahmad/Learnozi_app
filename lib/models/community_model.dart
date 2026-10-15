class CommunityReply {
  final String id;
  final String authorName;
  final String content;
  final DateTime timestamp;
  int upvotes;

  CommunityReply({
    required this.id,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.upvotes = 0,
  });
}

class CommunityPost {
  final String id;
  final String authorName;
  final String title;
  final String content;
  final String subjectTag; // "Physics", "Chemistry", "CS", "Math", "General"
  final DateTime timestamp;
  bool isResolved;
  int upvotes;
  int flagsCount;
  bool isHidden;
  final List<CommunityReply> replies;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    required this.subjectTag,
    required this.timestamp,
    this.isResolved = false,
    this.upvotes = 0,
    this.flagsCount = 0,
    this.isHidden = false,
    List<CommunityReply>? replies,
  }) : replies = replies ?? [];
}
