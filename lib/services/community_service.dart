import 'package:flutter/foundation.dart';
import '../models/community_model.dart';

class CommunityService extends ChangeNotifier {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal() {
    _initSampleCommunity();
  }

  final List<CommunityPost> _posts = [];
  List<CommunityPost> get visiblePosts =>
      _posts.where((p) => !p.isHidden).toList();

  List<CommunityPost> get flaggedPosts =>
      _posts.where((p) => p.flagsCount > 0 && !p.isHidden).toList();

  int get totalCommunityPosts => _posts.length;

  void _initSampleCommunity() {
    final now = DateTime.now();
    _posts.addAll([
      CommunityPost(
        id: 'post_1',
        authorName: 'Fatima Noor (FSc Pre-Med)',
        title: 'How to easily remember the stages of Prophase 1 in Meiosis?',
        content: 'I always get confused between Leptotene, Zygotene, Pachytene, Diplotene, and Diakinesis. Is there any easy Urdu/English mnemonic that helped you in board exams?',
        subjectTag: 'Biology',
        timestamp: now.subtract(const Duration(hours: 4)),
        isResolved: true,
        upvotes: 8,
        flagsCount: 0,
        replies: [
          CommunityReply(
            id: 'rep_1',
            authorName: 'Usman Ali (MDCAT Aspirant)',
            content: 'Use this classic mnemonic: "Lazy Zebras Play Dirty Dance" (L-Z-P-D-D). In Urdu: "Larkay Zyada Parh Kar Pass Hotay Hain". Hope it helps!',
            timestamp: now.subtract(const Duration(hours: 3)),
            upvotes: 6,
          ),
        ],
      ),
      CommunityPost(
        id: 'post_2',
        authorName: 'Zainab Tariq (BSCS Semester 2)',
        title: 'Derivation of centripetal acceleration in rotational motion',
        content: 'Can someone verify if using the vector triangle method is acceptable in Punjab Board marking or do they require the calculus derivative limit approach?',
        subjectTag: 'Physics',
        timestamp: now.subtract(const Duration(hours: 9)),
        isResolved: false,
        upvotes: 5,
        flagsCount: 0,
        replies: [
          CommunityReply(
            id: 'rep_2',
            authorName: 'Ali Raza',
            content: 'In FSc Part 1 Physics (Punjab Board), the geometric delta-v vector triangle method given in textbook Chapter 5 is 100% accepted and carries full marks.',
            timestamp: now.subtract(const Duration(hours: 8)),
            upvotes: 4,
          ),
        ],
      ),
      CommunityPost(
        id: 'post_3',
        authorName: 'Anonymous Student',
        title: 'Paid assignment services promotion spam message',
        content: 'Contact this whatsapp number for cheating in online quizzes and exams guaranteed grades.',
        subjectTag: 'General',
        timestamp: now.subtract(const Duration(days: 1)),
        isResolved: false,
        upvotes: 0,
        flagsCount: 3, // Flagged for moderation
        isHidden: false,
        replies: [],
      ),
    ]);
  }

  void createPost({
    required String authorName,
    required String title,
    required String content,
    required String subjectTag,
  }) {
    _posts.insert(
      0,
      CommunityPost(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
        authorName: authorName,
        title: title,
        content: content,
        subjectTag: subjectTag,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addReply(String postId, String authorName, String content) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.replies.add(
      CommunityReply(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        authorName: authorName,
        content: content,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void toggleResolved(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.isResolved = !post.isResolved;
    notifyListeners();
  }

  void flagPost(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.flagsCount += 1;
    notifyListeners();
  }

  void upvotePost(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.upvotes += 1;
    notifyListeners();
  }

  // --- Admin Moderation Actions (FR-11) ---
  void adminHidePost(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.isHidden = true;
    notifyListeners();
  }

  void adminDismissFlags(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.flagsCount = 0;
    notifyListeners();
  }
}
