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

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'upvotes': upvotes,
  };

  factory CommunityReply.fromJson(Map<String, dynamic> json) => CommunityReply(
    id: json['id'] ?? '',
    authorName: json['authorName'] ?? '',
    content: json['content'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'title': title,
    'content': content,
    'subjectTag': subjectTag,
    'timestamp': timestamp.toIso8601String(),
    'isResolved': isResolved,
    'upvotes': upvotes,
    'flagsCount': flagsCount,
    'isHidden': isHidden,
    'replies': replies.map((r) => r.toJson()).toList(),
  };

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: json['id'] ?? '',
    authorName: json['authorName'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    subjectTag: json['subjectTag'] ?? 'General',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    isResolved: json['isResolved'] ?? false,
    upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
    flagsCount: (json['flagsCount'] as num?)?.toInt() ?? 0,
    isHidden: json['isHidden'] ?? false,
    replies: (json['replies'] as List?)
            ?.map((r) => CommunityReply.fromJson(Map<String, dynamic>.from(r)))
            .toList() ??
        [],
  );
}
