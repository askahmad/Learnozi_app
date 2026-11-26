import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../services/adaptive_service.dart';
import '../services/ai_tutor_service.dart';
import '../services/user_service.dart';
import '../services/quota_service.dart';
import '../utils/app_colors.dart';
import '../widgets/academic_markdown_view.dart';
import 'document_chat_screen.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _aiService = AiTutorService();
  final _userService = UserService();
  final _quotaService = QuotaService();
  final _adaptiveService = AdaptiveService();

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late String _selectedLanguage;
  late String _selectedLevel;
  String _selectedSubject = '';

  List<String> get _quickSuggestions {
    final isUrdu = _selectedLanguage == 'Urdu';
    final profile = _userService.profile;

    // 1. If student specifically selected a subject, prioritize that exact course syllabus
    if (_selectedSubject.isNotEmpty) {
      final sub = _selectedSubject.toLowerCase();
      if (sub.contains('database') || sub.contains('dbms') || sub.contains('sql')) {
        return isUrdu
            ? [
                'ڈیٹا بیس نارملائزیشن (1NF-3NF) مع مثال',
                'ACID خصوصیات اور ٹرانزیکشن مینجمنٹ',
                'SQL میں INNER اور LEFT JOIN میں فرق',
                'انڈیکسنگ (B-Tree) کا ڈیٹا بیس میں فائدہ',
              ]
            : [
                'Explain Normalization (1NF, 2NF, 3NF) with table',
                'ACID Properties in DBMS with banking scenario',
                'SQL INNER JOIN vs LEFT JOIN with query',
                'Primary Key vs Foreign Key constraints',
              ];
      } else if (sub.contains('data structures') || sub.contains('dsa')) {
        return isUrdu
            ? [
                'بائنری سرچ ٹری کا الگورتھم اور ٹائم کمپلیکسٹی',
                'اسٹیک اور کیو (Stack vs Queue) میں فرق',
                'کوئیک سورٹ اور مرج سورٹ کا موازنہ',
                'گراف میں بی ایف ایس اور ڈی ایف ایس (BFS vs DFS)',
              ]
            : [
                'Binary Search Tree insertion & Big-O Time Complexity',
                'Stack vs Queue implementation in C++',
                'Merge Sort vs Quick Sort comparison',
                'Graph BFS vs DFS traversal logic',
              ];
      } else if (sub.contains('operating systems') || sub.contains('os')) {
        return isUrdu
            ? [
                'پروسیس اور تھریڈ میں بنیادی فرق',
                'ڈیڈ لاک اور کاف مین کی 4 شرائط',
                'راؤنڈ روبن سی پی یو شیڈولنگ الگورتھم',
                'ورچوئل میموری اور پیجنگ کا طریقہ کار',
              ]
            : [
                'Difference between Process and Thread',
                'Explain Deadlock and 4 Coffman conditions',
                'Round Robin CPU scheduling calculation',
                'Virtual Memory & Paging mechanics',
              ];
      } else if (sub.contains('oop') || sub.contains('object oriented')) {
        return isUrdu
            ? [
                'او او پی کے چار بنیادی ستون مع کوڈ مثال',
                'پولیمورفزم اور میتھڈ اوور رائڈنگ',
                'کلاس اور آبجیکٹ میں امتحانی فرق',
              ]
            : [
                '4 Pillars of OOP with C# / C++ code',
                'Polymorphism: Overloading vs Overriding',
                'Abstract Class vs Interface with example',
              ];
      } else if (sub.contains('physics')) {
        return isUrdu
            ? [
                'نیوٹن کے قوانین کی امتحانی وضاحت',
                'سینٹری پیٹل فورس کا فارمولا اور اخذ Fc=mv²/r',
                'ورک انرجی تھیورم کا ثبوت',
                'فیراڈے کا قانون برائے الیکٹرو میگنیٹک انڈکشن',
              ]
            : [
                'Explain Newton\'s Laws with exam derivation',
                'Centripetal force derivation Fc = mv²/r',
                'Work-Energy Principle with proof',
                'Faraday\'s Law of Electromagnetic Induction',
              ];
      } else if (sub.contains('biology') || sub.contains('anatomy') || sub.contains('physiology')) {
        return isUrdu
            ? [
                'مائیٹوسس اور میوسس میں تفصیلی فرق',
                'ڈی این اے کی ساخت اور واٹسن کرک ماڈل',
                'نیوران میں ایکشن پوٹینشل کے مراحل',
                'اینٹی بائیوٹکس کے طریقہ کار اور اقسام',
              ]
            : [
                'Mitosis vs Meiosis stages and ploidy',
                'Action Potential phases in neurons',
                'DNA Double Helix & Watson-Crick Model',
                'Mechanisms of Action of Antibiotics',
              ];
      } else if (sub.contains('accounting') || sub.contains('finance') || sub.contains('commerce')) {
        return isUrdu
            ? [
                'ڈیبٹ اور کریڈٹ کے سنہری اصول مع مثالیں',
                'بیلنس شیٹ اور انکم اسٹیٹمنٹ کی تیاری',
                'بینک ری کنسیلیشن اسٹیٹمنٹ کا طریقہ',
                'ورکنگ کیپیٹل کا حساب لگانے کا فارمولا',
              ]
            : [
                'Golden Rules of Debit & Credit with Journal entries',
                'Balance Sheet vs Income Statement structure',
                'Bank Reconciliation Statement with examples',
                'Working Capital formula and ratio analysis',
              ];
      }
    }

    if (profile.educationType == EducationType.university) {
      final p = profile.program.toLowerCase();
      if (p.contains('computer') ||
          p.contains('software') ||
          p.contains('it') ||
          p.contains('ai') ||
          p.contains('data science')) {
        return isUrdu
            ? [
                'C# میں 5 کا پہاڑا (Table) پروگرام',
                'او او پی کے چار بنیادی ستون اور مثال',
                'ڈیٹا بیس نارملائزیشن (1NF-3NF) اور ACID',
                'آپریٹنگ سسٹم میں ڈیڈ لاک اور کاف مین کی 4 شرائط',
                'بائنری سرچ ٹری کا الگورتھم اور ٹائم کمپلیکسٹی',
              ]
            : [
                'Table of 5 in C# program',
                'OOP 4 Pillars with C# example',
                'Binary Search Tree algorithm & Big-O',
                'Database Normalization (1NF-3NF) & ACID',
                'What is Deadlock and Coffman conditions',
              ];
      } else if (p.contains('business') ||
          p.contains('bba') ||
          p.contains('accounting') ||
          p.contains('finance') ||
          p.contains('economics')) {
        return isUrdu
            ? [
                'ڈیبٹ اور کریڈٹ کے اصول مع بیلنس شیٹ',
                'مارکیٹنگ مکس (4 Ps) کی امتحانی وضاحت',
                'لیڈرشپ اور مینجمنٹ میں فرق',
                'SWOT اینالائسس کا طریقہ کار',
              ]
            : [
                'Golden Rules of Debit & Credit with Balance Sheet',
                'Marketing Mix (4 Ps) with case study',
                'Difference between Management & Leadership',
                'SWOT Analysis framework with example',
              ];
      } else if (p.contains('medical') ||
          p.contains('mbbs') ||
          p.contains('pharm') ||
          p.contains('dpt')) {
        return isUrdu
            ? [
                'مائیٹوسس اور میوسس میں تفصیلی فرق',
                'اینٹی بائیوٹکس کے طریقہ کار اور اقسام',
                'ڈی این اے کی ساخت اور واٹسن کرک ماڈل',
                'بلڈ پریشر ریگولیشن اور رینین اینجیوٹینسن سسٹم',
              ]
            : [
                'Mitosis vs Meiosis stages and ploidy',
                'Mechanisms of Action of Antibiotics',
                'DNA Double Helix & Watson-Crick Model',
                'Renin-Angiotensin System in BP regulation',
              ];
      }
    } else {
      // School / College
      final track = profile.schoolCourse.toLowerCase();
      if (track.contains('medical')) {
        return isUrdu
            ? [
                'مائیٹوسس اور میوسس میں بنیادی فرق',
                'ڈی این اے کی ساخت آسان الفاظ میں',
                'پودوں میں فوٹوسینتھیسس کا عمل',
                'اینزائم ایکشن کا لاک اینڈ کی ماڈل',
              ]
            : [
                'Difference between Mitosis and Meiosis',
                'Structure of DNA in simple steps',
                'Photosynthesis light vs dark reactions',
                'Enzyme action lock-and-key model',
              ];
      } else if (track.contains('engineering')) {
        return isUrdu
            ? [
                'نیوٹن کا تیسرا قانون مع امتحانی مثال',
                'دو درجی مساوات حل کرنے کا طریقہ',
                'سینٹری پیٹل فورس کا فارمولا اور اخذ',
                'ویکٹرز کا ڈاٹ اور کراس پروڈکٹ',
              ]
            : [
                'Explain Newton\'s Laws with exam derivation',
                'Solve quadratic equation by factorization',
                'Centripetal force derivation Fc = mv²/r',
                'Vector Dot Product vs Cross Product',
              ];
      } else if (track.contains('commerce') || track.contains('i.com')) {
        return isUrdu
            ? [
                'ڈیبٹ اور کریڈٹ کے اصول مع مثالیں',
                'جرنل سے لیجر بنانے کا طریقہ',
                'بینک ری کنسیلیشن اسٹیٹمنٹ کا مقصد',
              ]
            : [
                'Rules of Debit & Credit with journal entries',
                'How to prepare Ledger from Journal',
                'Bank Reconciliation Statement explained',
              ];
      }
    }

    // Default suggestions
    return isUrdu
        ? [
            'نیوٹن کا تیسرا قانون مع امتحانی مثال',
            'مصنوعی ذہانت (AI) کیا ہے؟',
            'مائیٹوسس اور میوسس میں بنیادی فرق',
            'دو درجی مساوات حل کرنے کا طریقہ',
          ]
        : [
            'Table of 5 in C# program',
            'What is Artificial Intelligence (AI)?',
            'Explain Newton\'s Laws with exam example',
            'OOP Principles with C# Example',
            'Solve quadratic equation by factorization',
          ];
  }

  final List<String> _baseLevels = const [
    'FSc / College',
    'Matric (9-10th)',
    'MDCAT / ECAT',
    'University',
    'CSS / PMS',
  ];

  List<String> get _availableLevels {
    final list = List<String>.from(_baseLevels);
    final profileLevel = _userService.profile.academicLevelString;
    if (profileLevel.isNotEmpty && !list.contains(profileLevel)) {
      list.insert(0, profileLevel);
    }
    if (!list.contains(_selectedLevel)) {
      list.insert(0, _selectedLevel);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onUserChanged);
    _selectedLanguage = _userService.profile.language;
    final profileLevel = _userService.profile.academicLevelString;
    _selectedLevel = profileLevel.isNotEmpty ? profileLevel : 'FSc / College';
    _resetWelcomeMessage();
    _restoreChatHistory();
  }

  Future<void> _restoreChatHistory() async {
    final saved = await _aiService.loadChatHistory();
    if (mounted && saved.isNotEmpty) {
      setState(() {
        _messages
          ..clear()
          ..addAll(saved);
      });
      _scrollToBottom();
    }
  }

  void _resetWelcomeMessage() {
    final isUrdu = _selectedLanguage == 'Urdu';
    final profile = _userService.profile;
    final name = profile.name.isNotEmpty ? profile.name : 'Student';
    final level = profile.academicLevelString;

    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text: isUrdu
            ? 'السلام علیکم $name! 🎓 میں آپ کا لرنوزی اے آئی اسٹڈی کمپینین ہوں۔\nآپ کے شعبے ($level) کے مطابق، اپنے نصاب سے کوئی بھی سوال اردو یا انگلش میں پوچھیں، میں امتحانی مثال، مکمل کوڈ یا فارمولے اور 3 نکاتی خلاصے کے ساتھ مرحلہ وار وضاحت کروں گا!'
            : 'Assalam-o-Alaikum $name! 🎓 I am your Learnozi AI Study Companion.\nCalibrated specifically for your curriculum ($level). Ask me any question from your syllabus in English or Urdu, and I\'ll provide step-by-step breakdowns, worked examples, and revision summaries!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _onUserChanged() {
    if (mounted && _selectedLanguage != _userService.profile.language) {
      setState(() {
        _selectedLanguage = _userService.profile.language;
        if (_messages.length <= 1) {
          _resetWelcomeMessage();
        }
      });
    }
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage([String? presetText]) async {
    final query = presetText ?? _textController.text.trim();
    if (query.isEmpty || _isLoading) return;

    if (!_quotaService.canMakeAiRequest()) {
      _showLimitReachedDialog();
      return;
    }

    _textController.clear();
    final priorHistory = List<ChatMessage>.from(_messages);
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Call Multi-tier AI API with full academic profile, active subject, weak topics & conversation history
      final responseText = await _aiService.askTutor(
        question: query,
        studentLevel: _selectedLevel,
        language: _selectedLanguage,
        activeSubject: _selectedSubject,
        profile: _userService.profile,
        weakTopics: _adaptiveService.weakTopics,
        conversationHistory: priorHistory,
      );

      if (!mounted) return;

      _quotaService.consumeAiRequest();

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMsg);
      });
      _aiService.saveChatHistory(_messages);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: _selectedLanguage == 'Urdu'
            ? 'معذرت، رابطہ مکمل نہیں ہو سکا۔ برائے مہربانی انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔'
            : 'Sorry, the request could not be completed. Please check your internet connection and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMsg);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Daily Limit Reached', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'You have reached your 15 free AI queries for today. Your quota resets at midnight to keep everything free of cost!',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLanguage == 'Urdu' ? 'اے آئی اسٹڈی ٹیوٹر' : 'AI Study Tutor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _selectedLanguage == 'Urdu' ? 'نصابی تفہیم اور امتحانی تیاری' : 'Syllabus & Exam Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Switcher Pill
          GestureDetector(
            onTap: () {
              final newLang = _selectedLanguage == 'English' ? 'Urdu' : 'English';
              _userService.updateProfile(language: newLang);
              setState(() {
                _selectedLanguage = newLang;
                if (_messages.length <= 1) {
                  _resetWelcomeMessage();
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newLang == 'Urdu' ? 'اردو زبان منتخب ہو گئی ہے' : 'Switched to English mode',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate_rounded, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 4),
                  Text(
                    _selectedLanguage == 'Urdu' ? 'اردو' : 'EN',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Sub-header Bar: Credits remaining & Level selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      'Credits: ${_quotaService.remainingAiRequests}/15 Free',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                      value: _availableLevels.contains(_selectedLevel)
                          ? _selectedLevel
                          : _availableLevels.first,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4F46E5), size: 18),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF4F46E5),
                      ),
                      items: _availableLevels.map((lvl) {
                        return DropdownMenuItem<String>(
                          value: lvl,
                          child: Text(lvl, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLevel = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Department Subject Filter Carousel
          _buildSubjectFilterBar(isDark),

          // Chat Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Learnozi AI is thinking...',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Suggestions Chips (when few messages)
          if (_messages.length <= 2)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ActionChip(
                    label: Text(
                      _quickSuggestions[i],
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                    ),
                    backgroundColor: const Color(0xFFEEF2FF),
                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendMessage(_quickSuggestions[i]),
                  );
                },
              ),
            ),

          const SizedBox(height: 6),

          // Bottom Input Bar (Text + Voice + Camera)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Document / PDF Attachment Icon
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF4F46E5), size: 22),
                  tooltip: 'Upload PDF Notes / Document',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DocumentChatScreen(autoOpenNewDialog: true),
                      ),
                    );
                  },
                ),
                // Voice Mic Button
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF64748B), size: 22),
                  tooltip: 'Voice Input in Urdu / English',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Voice input language set to $_selectedLanguage. Tap and hold to speak.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: _selectedLanguage == 'Urdu'
                          ? 'اردو یا انگلش میں سوال پوچھیں...'
                          : 'Ask any syllabus question...',
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button with gradient
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 40, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask Any Study Topic',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Computer Science, Math, Physics, Chemistry, Biology',
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Message Card
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rich Academic Response text (Markdown, Math & Urdu RTL aware)
                  AcademicMarkdownView(
                    text: msg.text,
                    baseStyle: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 8),

                  // Actions & Feedback Row (Thumbs up/down & Copy - FR-16)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              msg.feedback == 1 ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                              size: 16,
                              color: msg.feedback == 1 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                            ),
                            tooltip: 'Helpful answer',
                            onPressed: () {
                              setState(() => msg.feedback = (msg.feedback == 1 ? 0 : 1));
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              msg.feedback == -1 ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                              size: 16,
                              color: msg.feedback == -1 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                            ),
                            tooltip: 'Needs improvement',
                            onPressed: () {
                              setState(() => msg.feedback = (msg.feedback == -1 ? 0 : -1));
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
                        tooltip: 'Copy explanation',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Explanation copied to clipboard!'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic Department Subject Filter Carousel for targeted course-specific answers
  Widget _buildSubjectFilterBar(bool isDark) {
    final profile = _userService.profile;
    final recommended = profile.recommendedSubjects;
    final subjects = ['All Subjects', ...recommended];
    final isUrdu = _selectedLanguage == 'Urdu';

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: subjects.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == subjects.length) {
            // More subjects button
            return InkWell(
              onTap: _showCustomSubjectDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrdu ? 'دیگر مضامین' : 'More...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final subject = subjects[index];
          final isSelected = _selectedSubject == subject ||
              (subject == 'All Subjects' && _selectedSubject.isEmpty);
          final label = subject == 'All Subjects'
              ? (isUrdu ? 'تمام مضامین' : 'All Subjects')
              : subject;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedSubject = subject == 'All Subjects' ? '' : subject;
              });
              if (_selectedSubject.isNotEmpty) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isUrdu
                          ? 'اب اے آئی ٹیوٹر "$_selectedSubject" کے نصاب پر مرکوز ہے'
                          : 'Tutor calibrated for: $_selectedSubject',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCustomSubjectDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final allSubjects = UserProfile.academicSubjects;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Course / Subject for Targeted Tutoring',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allSubjects.length,
                  itemBuilder: (context, i) {
                    final s = allSubjects[i];
                    return ListTile(
                      title: Text(
                        s,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedSubject = s);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tutor calibrated for: $s'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
