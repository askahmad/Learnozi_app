import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _communityService = CommunityService();
  final _userService = UserService();
  String _selectedTag = 'All';

  List<CommunityPost> get _filteredPosts {
    final posts = _communityService.visiblePosts;
    if (_selectedTag == 'All') return posts;
    return posts.where((p) => p.subjectTag == _selectedTag).toList();
  }

  void _showNewPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String tag = 'Physics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Ask Community / Start Discussion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: tag,
                    decoration: InputDecoration(
                      labelText: 'Subject Tag',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Physics', 'Chemistry', 'Computer Science', 'Biology', 'General']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => tag = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Question / Topic Title',
                      hintText: 'e.g. Help understanding Carnot Engine efficiency',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Details / Context',
                      hintText: 'Describe where you are stuck or share your study note...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      if (title.isEmpty || content.isEmpty) return;

                      _communityService.createPost(
                        authorName: _userService.profile.name,
                        title: title,
                        content: content,
                        subjectTag: tag,
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Post to Community', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPostDetailsModal(CommunityPost post) {
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDetailState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post.subjectTag,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF4F46E5)),
                      ),
                    ),
                    Row(
                      children: [
                        // Flag post button (FR-09 & FR-11)
                        IconButton(
                          tooltip: 'Report / Flag inappropriate content',
                          icon: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444), size: 20),
                          onPressed: () {
                            _communityService.flagPost(post.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post flagged for admin review.')),
                            );
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Asked by ${post.authorName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 14),

                // Mark as resolved button
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setDetailState(() {
                          _communityService.toggleResolved(post.id);
                        });
                        setState(() {});
                      },
                      icon: Icon(
                        post.isResolved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: post.isResolved ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        size: 18,
                      ),
                      label: Text(
                        post.isResolved ? 'Marked as Resolved' : 'Mark as Resolved',
                        style: TextStyle(
                          fontSize: 12,
                          color: post.isResolved ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                const Text('Discussion & Peer Replies:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 10),

                // Replies list
                Expanded(
                  child: post.replies.isEmpty
                      ? const Center(
                          child: Text('No replies yet. Be the first peer to respond!', style: TextStyle(color: Color(0xFF94A3B8))),
                        )
                      : ListView.separated(
                          itemCount: post.replies.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = post.replies[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('${r.upvotes} upvotes', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(r.content, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Reply input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        decoration: InputDecoration(
                          hintText: 'Write a helpful reply or solution...',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                      onPressed: () {
                        final text = replyController.text.trim();
                        if (text.isEmpty) return;
                        setDetailState(() {
                          _communityService.addReply(post.id, _userService.profile.name, text);
                        });
                        replyController.clear();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Peer Community',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Collaborative doubt clearance hub (FR-09)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: Color(0xFF4F46E5)),
            onPressed: _showNewPostDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Physics', 'Chemistry', 'Computer Science', 'Biology', 'General'].map((tag) {
                  final isSel = _selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tag, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: const Color(0xFF4F46E5),
                      onSelected: (val) {
                        if (val) setState(() => _selectedTag = tag);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Posts Feed
          Expanded(
            child: posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('No Discussions in this Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showNewPostDialog,
                          child: const Text('Start First Discussion'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => _buildPostCard(posts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPostDetailsModal(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.subjectTag,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4F46E5)),
                  ),
                ),
                if (post.isResolved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Resolved',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By ${post.authorName}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
                Row(
                  children: [
                    const Icon(Icons.mode_comment_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('${post.replies.length} replies', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
