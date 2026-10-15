import 'package:flutter/foundation.dart';

class QuotaService extends ChangeNotifier {
  static final QuotaService _instance = QuotaService._internal();
  factory QuotaService() => _instance;
  QuotaService._internal();

  static const int maxDailyAiRequests = 15;
  static const int maxDailyDocUploads = 3;
  static const int maxFileSizeMb = 5;

  int _usedAiRequestsToday = 2;
  int _usedDocUploadsToday = 0;
  DateTime _lastDate = DateTime.now();

  int get remainingAiRequests {
    _checkDailyReset();
    return (maxDailyAiRequests - _usedAiRequestsToday).clamp(0, maxDailyAiRequests);
  }

  int get remainingDocUploads {
    _checkDailyReset();
    return (maxDailyDocUploads - _usedDocUploadsToday).clamp(0, maxDailyDocUploads);
  }

  bool canMakeAiRequest() {
    _checkDailyReset();
    return _usedAiRequestsToday < maxDailyAiRequests;
  }

  bool canUploadDocument() {
    _checkDailyReset();
    return _usedDocUploadsToday < maxDailyDocUploads;
  }

  void consumeAiRequest() {
    _checkDailyReset();
    if (_usedAiRequestsToday < maxDailyAiRequests) {
      _usedAiRequestsToday++;
      notifyListeners();
    }
  }

  void consumeDocUpload() {
    _checkDailyReset();
    if (_usedDocUploadsToday < maxDailyDocUploads) {
      _usedDocUploadsToday++;
      notifyListeners();
    }
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _lastDate.day || now.month != _lastDate.month || now.year != _lastDate.year) {
      _usedAiRequestsToday = 0;
      _usedDocUploadsToday = 0;
      _lastDate = now;
      notifyListeners();
    }
  }

  String getResetCountdownText() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return 'Resets in ${hours}h ${minutes}m (Midnight)';
  }
}
