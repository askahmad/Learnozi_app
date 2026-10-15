import 'package:flutter/material.dart';
import '../services/document_service.dart';
import '../services/quota_service.dart';
import '../services/user_service.dart';

class DocumentChatScreen extends StatefulWidget {
  final String? initialDocId;
  const DocumentChatScreen({super.key, this.initialDocId});

  @override
  State<DocumentChatScreen> createState() => _DocumentChatScreenState();
}

class _DocumentChatScreenState extends State<DocumentChatScreen> {
  final _docService = DocumentService();
  final _quotaService = QuotaService();
  final _userService = UserService();

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedDocId;
  bool _isProcessing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (_docService.documents.isNotEmpty) {
      _selectedDocId = widget.initialDocId ?? _docService.documents.first.id;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  UploadedDoc? get _currentDoc {
    if (_selectedDocId == null) return null;
    try {
      return _docService.documents.firstWhere((d) => d.id == _selectedDocId);
    } catch (_) {
      return null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final query = _textController.text.trim();
    if (query.isEmpty || _selectedDocId == null || _isProcessing) return;

    if (!_quotaService.canMakeAiRequest()) {
      _showQuotaDialog();
      return;
    }

    _textController.clear();
    setState(() => _isProcessing = true);
    _scrollToBottom();

    await _docService.askDocumentChat(
      docId: _selectedDocId!,
      question: query,
      language: _userService.profile.language,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  void _showNewDocDialog() {
    final nameController = TextEditingController();
    final contentController = TextEditingController();

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.upload_file_rounded, color: Color(0xFF4F46E5)),
                          SizedBox(width: 8),
                          Text(
                            'Upload / Add Notes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste lecture notes or chapter summary (Max 5 MB). The AI tutor will extract key points and chat with it.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Document / Chapter Title',
                      hintText: 'e.g. Chapter 4: Chemical Bonding Notes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Paste Document / Notes Text',
                      hintText: 'Paste the content of your PDF, book excerpt, or lecture notes here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final content = contentController.text.trim();
                            if (name.isEmpty || content.isEmpty) return;

                            final byteSize = content.length; // 1 char approx 1 byte
                            if (byteSize > 5 * 1024 * 1024) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('File exceeds 5 MB limit. Please shorten content.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(ctx);
                            setState(() => _isUploading = true);

                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              final res = await _docService.summarizeDocument(
                                docName: name,
                                docText: content,
                                byteSize: byteSize,
                              );
                              final doc = res['document'] as UploadedDoc;
                              setState(() {
                                _selectedDocId = doc.id;
                                _isUploading = false;
                              });
                            } catch (e) {
                              setState(() => _isUploading = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Process & Summarize Document', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuotaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Daily Limit Reached'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have used all free AI requests for today. This helps ensure fair usage under our free tier.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _quotaService.getResetCountdownText(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Got It', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = _currentDoc;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Chat & Notes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Grounded strictly in your syllabus notes (FR-03)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Notes (Max 5MB)',
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5)),
            onPressed: _showNewDocDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Document Selector Tabs
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _docService.documents.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _docService.documents[i];
                final isSelected = d.id == _selectedDocId;
                return ChoiceChip(
                  label: Text(
                    d.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (val) {
                    if (val) setState(() => _selectedDocId = d.id);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Main Chat / Summary Area
          Expanded(
            child: doc == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Document Selected',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: _showNewDocDialog,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Add Document Notes'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Document Summary & Key Points Card
                      _buildSummaryCard(doc),
                      const SizedBox(height: 16),

                      // Document Usage Pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.data_usage_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                '${doc.totalCharacters} chars loaded • ${(doc.byteSize / 1024).toStringAsFixed(1)} KB (Max 5MB)',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chat Messages
                      ...doc.chatHistory.map((m) => _buildChatBubble(m)),

                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                              ),
                              SizedBox(width: 10),
                              Text('Consulting document text...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything covered in this document...',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      onPressed: _isProcessing ? null : _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(UploadedDoc doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 16, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Auto-Generated Summary & Key Points',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            doc.summary,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          const Text(
            'High-Yield Key Takeaways:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          ...doc.keyPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(DocChatMessage m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: m.isUser ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: m.isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !m.isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: m.isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: m.isUser ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (!m.isUser && m.charactersUsed > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Grounded in ${m.charactersUsed} doc characters',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
