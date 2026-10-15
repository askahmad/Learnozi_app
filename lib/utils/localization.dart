class AppLocale {
  static const Map<String, Map<String, String>> _strings = {
    'English': {
      'app_title': 'Learnozi',
      'welcome': 'Welcome back,',
      'ask_tutor': 'Ask AI Tutor',
      'doc_chat': 'Document Notes Chat',
      'quiz_mock': 'AI Quiz & Mock Test',
      'study_tools': 'Study Tools & Timer',
      'weak_topics': 'Weak Topics Diagnostic',
      'flashcards': 'SM-2 Flashcards',
      'planner': 'Study Planner',
      'timer': 'Focus Pomodoro',
      'community': 'Student Community',
      'analytics': 'Analytics Dashboard',
      'admin_panel': 'Admin Moderation',
      'history': 'Past History',
      'badges': 'Badges & Streaks',
      'quota_remaining': 'Credits Remaining',
      'sign_out': 'Sign Out',
      'daily_limit_warn': 'Daily Limit Reached',
      'urdu_toggle': 'Urdu Mode',
    },
    'Urdu': {
      'app_title': 'لرنوزی',
      'welcome': 'خوش آمدید،',
      'ask_tutor': 'اے آئی ٹیوٹر سے پوچھیں',
      'doc_chat': 'دستاویز و نوٹس چیٹ',
      'quiz_mock': 'کوئز اور امتحانی ٹیسٹ',
      'study_tools': 'مطالعہ کے ٹولز اور ٹائمر',
      'weak_topics': 'کمزور موضوعات کی تشخیص',
      'flashcards': 'فلیش کارڈز',
      'planner': 'اسٹڈی پلانر اور شیڈول',
      'timer': 'پومودورو فوکس ٹائمر',
      'community': 'طلباء کی کمیونٹی فورم',
      'analytics': 'کارکردگی کا ڈیش بورڈ',
      'admin_panel': 'ایڈمن پینل',
      'history': 'ماضی کی ہسٹری',
      'badges': 'بیجز اور سٹریکس',
      'quota_remaining': 'باقی ماندہ کوٹہ',
      'sign_out': 'لاگ آؤٹ',
      'daily_limit_warn': 'روزانہ کی حد مکمل ہو گئی ہے',
      'urdu_toggle': 'اردو موڈ فعال ہے',
    },
  };

  static String t(String key, String lang) {
    return _strings[lang]?[key] ?? _strings['English']?[key] ?? key;
  }
}
