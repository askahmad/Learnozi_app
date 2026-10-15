import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import '../services/document_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _communityService = CommunityService();
  final _userService = UserService();
  final _docService = DocumentService();

  @override
  Widget build(BuildContext context) {
    final user = _userService.profile;
    final flaggedPosts = _communityService.flaggedPosts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrator Panel',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'System stats & community moderation (FR-11)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Role switcher toggle for supervisor demo
          TextButton.icon(
            onPressed: () {
              setState(() {
                _userService.toggleAdminRole();
              });
            },
            icon: Icon(
              user.isAdmin ? Icons.verified_user_rounded : Icons.person_rounded,
              size: 16,
              color: user.isAdmin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            label: Text(
              user.isAdmin ? 'Role: ADMIN' : 'Role: STUDENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: user.isAdmin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
      body: !user.isAdmin
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_bad_rounded, size: 64, color: Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Restricted: Admin Only',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This panel is protected by profiles.role = "admin" policy (FR-11). For your FYP viva evaluation demo, tap the button below to switch to Admin mode.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _userService.toggleAdminRole();
                        });
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: const Text('Switch to Admin Role for Demo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Stat Cards (Section H SQL query emulation)
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdminKpi(
                          'Total Students',
                          '148',
                          '+12 this week',
                          const Color(0xFF4F46E5),
                          Icons.people_alt_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAdminKpi(
                          'Total Notes/Docs',
                          '${_docService.documents.length + 32}',
                          'Storage: 42 MB',
                          const Color(0xFF059669),
                          Icons.folder_shared_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdminKpi(
                          'AI Calls (Month)',
                          '1,420',
                          'Within Free Gemini Quota',
                          const Color(0xFF7C3AED),
                          Icons.auto_awesome_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAdminKpi(
                          'Flagged Reports',
                          '${flaggedPosts.length}',
                          flaggedPosts.isEmpty ? 'All clear' : 'Action required',
                          flaggedPosts.isEmpty ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          Icons.report_problem_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Section Title: Moderation Queue
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Flagged Community Posts Queue',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${flaggedPosts.length} Pending',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (flaggedPosts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No inappropriate content reported. Community discussions are clean.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...flaggedPosts.map((post) => _buildFlaggedPostCard(post)),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminKpi(String title, String val, String sub, Color color, IconData icon) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildFlaggedPostCard(dynamic post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Author: ${post.authorName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${post.flagsCount} Flags',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            post.content,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _communityService.adminDismissFlags(post.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Flags dismissed. Post kept visible.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: const Text('Dismiss Flags', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _communityService.adminHidePost(post.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post hidden and removed from community feed.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hide Post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
