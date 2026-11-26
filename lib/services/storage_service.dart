import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized local (SharedPreferences) + cloud (Firestore) persistence layer.
/// Gracefully degrades to no-op in unit tests where platform channels are absent.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init skipped: $e');
    }
  }

  /// Current storage scope: Firebase UID when signed in, otherwise 'demo'.
  String get currentScope {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return 'uid_${user.uid}';
    } catch (_) {}
    return 'demo';
  }

  String? get _activeUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String _scopedKey(String key, {bool global = false}) =>
      global ? 'learnozi_global_$key' : 'learnozi_${currentScope}_$key';

  /// Saves a JSON-encodable map or list locally, and optionally syncs to Firestore.
  Future<void> saveJson(
    String key,
    dynamic value, {
    bool global = false,
    bool syncToCloud = true,
  }) async {
    try {
      await init();
      final encoded = jsonEncode(value);
      await _prefs?.setString(_scopedKey(key, global: global), encoded);
    } catch (e) {
      debugPrint('Local save error ($key): $e');
    }

    if (syncToCloud && !global) {
      final uid = _activeUid;
      if (uid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('app_data')
              .doc(key)
              .set({
            'payload': value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Firestore sync error ($key): $e');
        }
      }
    }
  }

  /// Loads a JSON-decoded value from local cache (or Firestore if local is empty).
  Future<dynamic> loadJson(
    String key, {
    bool global = false,
    bool preferCloud = true,
  }) async {
    await init();
    final localRaw = _prefs?.getString(_scopedKey(key, global: global));

    if (!global && preferCloud) {
      final uid = _activeUid;
      if (uid != null) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('app_data')
              .doc(key)
              .get()
              .timeout(const Duration(seconds: 4));
          if (snap.exists && snap.data()?['payload'] != null) {
            final payload = snap.data()!['payload'];
            await _prefs?.setString(
              _scopedKey(key, global: false),
              jsonEncode(payload),
            );
            return payload;
          }
        } catch (e) {
          debugPrint('Firestore load fallback ($key): $e');
        }
      }
    }

    if (localRaw != null && localRaw.isNotEmpty) {
      try {
        return jsonDecode(localRaw);
      } catch (e) {
        debugPrint('Local JSON decode error ($key): $e');
      }
    }
    return null;
  }

  Future<void> saveBool(String key, bool value, {bool global = true}) async {
    try {
      await init();
      await _prefs?.setBool(_scopedKey(key, global: global), value);
    } catch (_) {}
  }

  Future<bool?> loadBool(String key, {bool global = true}) async {
    try {
      await init();
      return _prefs?.getBool(_scopedKey(key, global: global));
    } catch (_) {
      return null;
    }
  }
}
