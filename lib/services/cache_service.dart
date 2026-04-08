import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Box names
  static const String userBoxName = 'user_box';
  static const String profileBoxName = 'profile_box';
  static const String settingsBoxName = 'settings_box';
  static const String dashboardBoxName = 'dashboard_box';
  static const String noticesBoxName = 'notices_box';
  static const String scholarshipsBoxName = 'scholarships_box';
  static const String academicBoxName = 'academic_box';
  static const String attendanceBoxName = 'attendance_box';

  // TTL durations
  static const Duration userTTL = Duration(minutes: 30);
  static const Duration profileTTL = Duration(minutes: 15);
  static const Duration dashboardTTL = Duration(minutes: 10);
  static const Duration noticesTTL = Duration(hours: 1);
  static const Duration scholarshipsTTL = Duration(hours: 2);
  static const Duration academicTTL = Duration(minutes: 15);
  static const Duration attendanceTTL = Duration(minutes: 15);

  // Max entries per box (LRU eviction threshold)
  static const int _maxEntriesPerBox = 50;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Critical initialization for startup (minimal boxes).
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      // Only open critical boxes for routing
      await Future.wait([
        Hive.openBox(userBoxName),
        Hive.openBox(settingsBoxName),
      ]);
      _initialized = true;
      debugPrint('CacheService: Critical Hive boxes initialized');
    } catch (e) {
      debugPrint('CacheService: Hive Initialization Failed: $e');
      rethrow;
    }
  }

  /// Lazy-load the remaining boxes in the background.
  Future<void> initRemainingBoxes() async {
    if (!_initialized) await init();
    try {
      await Future.wait([
        Hive.openBox(profileBoxName),
        Hive.openBox(dashboardBoxName),
        Hive.openBox(noticesBoxName),
        Hive.openBox(scholarshipsBoxName),
        Hive.openBox(academicBoxName),
        Hive.openBox(attendanceBoxName),
      ]);
      debugPrint('CacheService: All remaining Hive boxes initialized');
    } catch (e) {
      debugPrint('CacheService: Error loading background boxes: $e');
    }
  }

  // ──────────────────────────────────────────────
  // TTL-aware put: stores value with a timestamp
  // ──────────────────────────────────────────────
  Future<void> put(String boxName, String key, dynamic value,
      {Duration? ttl}) async {
    try {
      if (!_initialized) await init();

      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);

      // Wrap value with timestamp for TTL checking
      // Sanitize data (recursively convert Timestamps to milliseconds)
      final sanitizedValue = _sanitizeData(value);
      final wrapper = {
        '_data': sanitizedValue,
        '_cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await box.put(key, wrapper);

      // LRU eviction: if box exceeds max entries, remove oldest
      if (box.length > _maxEntriesPerBox) {
        await _evictOldest(box);
      }
    } catch (e) {
      debugPrint('CacheService: Error putting in $boxName: $e');
    }
  }

  // ──────────────────────────────────────────────
  // TTL-aware get: returns null if data is expired
  // ──────────────────────────────────────────────
  dynamic get(String boxName, String key, {Duration? ttl}) {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        // Warning: This synchronous get will return null if the box isn't open yet.
        // This is safe for cache hits, but we trigger an async open for the next request.
        Hive.openBox(boxName).then((_) => debugPrint('CacheService: Box $boxName lazily opened'));
        return null;
      }
      final box = Hive.box(boxName);
      final raw = box.get(key);

      if (raw == null) return null;

      // Handle legacy data (not wrapped with TTL metadata)
      if (raw is! Map || !raw.containsKey('_data')) {
        return raw;
      }

      // TTL check
      if (ttl != null && raw.containsKey('_cachedAt')) {
        final cachedAt = raw['_cachedAt'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        if (age > ttl.inMilliseconds) {
          // Expired - delete and return null
          box.delete(key);
          return null;
        }
      }

      return raw['_data'];
    } catch (e) {
      debugPrint('CacheService: Error getting from $boxName: $e');
      return null;
    }
  }

  // Return age of cached item in seconds (to check for refresh cooldown)
  int getAgeSeconds(String boxName, String key) {
    try {
      if (!Hive.isBoxOpen(boxName)) return 999999;
      final box = Hive.box(boxName);
      final raw = box.get(key);
      if (raw == null || raw is! Map || !raw.containsKey('_cachedAt')) {
        return 999999;
      }
      final cachedAt = raw['_cachedAt'] as int;
      return (DateTime.now().millisecondsSinceEpoch - cachedAt) ~/ 1000;
    } catch (e) {
      return 999999;
    }
  }

  // Helper to determine if we should trigger a background refresh (cooldown)
  bool shouldRefresh(String boxName, String key, {Duration threshold = const Duration(minutes: 10)}) {
    final age = getAgeSeconds(boxName, key);
    return age > threshold.inSeconds;
  }

  // ──────────────────────────────────────────────
  // Generic Delete
  // ──────────────────────────────────────────────
  Future<void> delete(String boxName, String key) async {
    try {
      if (!_initialized) await init();
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);
      await box.delete(key);
    } catch (e) {
      debugPrint('CacheService: Error deleting from $boxName: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Clear All (for logout)
  // ──────────────────────────────────────────────
  Future<void> clearAll() async {
    try {
      if (!_initialized) await init();

      final boxNames = [
        userBoxName,
        profileBoxName,
        dashboardBoxName,
        noticesBoxName,
        scholarshipsBoxName,
        academicBoxName,
        attendanceBoxName,
      ];

      for (final name in boxNames) {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).clear();
        }
      }
      debugPrint('CacheService: All boxes cleared');
    } catch (e) {
      debugPrint('CacheService: Error clearing boxes: $e');
    }
  }

  // ──────────────────────────────────────────────
  // LRU Eviction: remove oldest entries when box is too large
  // ──────────────────────────────────────────────
  Future<void> _evictOldest(Box box) async {
    try {
      final entries = box.toMap();
      final sorted = entries.entries.toList()
        ..sort((a, b) {
          final aVal = a.value;
          final bVal = b.value;
          final aTime = (aVal is Map && aVal.containsKey('_cachedAt'))
              ? aVal['_cachedAt'] as int
              : 0;
          final bTime = (bVal is Map && bVal.containsKey('_cachedAt'))
              ? bVal['_cachedAt'] as int
              : 0;
          return aTime.compareTo(bTime);
        });

      // Remove oldest 20% of entries
      final removeCount = (sorted.length * 0.2).ceil();
      for (var i = 0; i < removeCount && i < sorted.length; i++) {
        await box.delete(sorted[i].key);
      }
      debugPrint('CacheService: Evicted $removeCount oldest entries');
    } catch (e) {
      debugPrint('CacheService: Eviction error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Sanitize data: recursively convert Firestore Timestamps to Hive-compatible values
  // ──────────────────────────────────────────────
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Timestamp) {
      // Convert to milliseconds since epoch
      return data.millisecondsSinceEpoch;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key, _sanitizeData(value)));
    }

    if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    }

    // Pass through other types (String, num, bool, DateTime - though Hive handles DateTime, 
    // it's safer to keep consistency if we ever move cache systems)
    return data;
  }

  // ──────────────────────────────────────────────
  // User Model Helpers (with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheUser(String uid, Map<String, dynamic> userData) async {
    await put(userBoxName, uid, userData, ttl: userTTL);
  }

  Map<String, dynamic>? getCachedUser(String uid) {
    final data = get(userBoxName, uid, ttl: userTTL);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Student Profile Helpers (with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheProfile(
    String profileId,
    Map<String, dynamic> profileData,
  ) async {
    await put(profileBoxName, profileId, profileData, ttl: profileTTL);
  }

  Map<String, dynamic>? getCachedProfile(String profileId) {
    final data = get(profileBoxName, profileId, ttl: profileTTL);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Dashboard Stats Helpers (with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheDashboardStats(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    await put(dashboardBoxName, '${userId}_stats', stats, ttl: dashboardTTL);
  }

  Map<String, dynamic>? getCachedDashboardStats(String userId) {
    final data = get(dashboardBoxName, '${userId}_stats', ttl: dashboardTTL);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Recent Activity Helpers (with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheRecentActivity(
    String userId,
    List<dynamic> activity,
  ) async {
    await put(dashboardBoxName, '${userId}_activity', activity,
        ttl: dashboardTTL);
  }

  List<dynamic>? getCachedRecentActivity(String userId) {
    final data =
        get(dashboardBoxName, '${userId}_activity', ttl: dashboardTTL);
    if (data == null) return null;
    return List<dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Notices Helpers (offline-first, with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheNotices(List<dynamic> notices) async {
    await put(noticesBoxName, 'all_notices', notices, ttl: noticesTTL);
  }

  List<dynamic>? getCachedNotices() {
    final data = get(noticesBoxName, 'all_notices', ttl: noticesTTL);
    if (data == null) return null;
    return List<dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Scholarships Helpers (offline-first, with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheScholarships(List<dynamic> scholarships) async {
    await put(scholarshipsBoxName, 'all_scholarships', scholarships,
        ttl: scholarshipsTTL);
  }

  List<dynamic>? getCachedScholarships() {
    final data =
        get(scholarshipsBoxName, 'all_scholarships', ttl: scholarshipsTTL);
    if (data == null) return null;
    return List<dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Academic Info Helpers (offline-first, with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheAcademicInfo(
    String studentUID,
    Map<String, dynamic> academicData,
  ) async {
    await put(academicBoxName, studentUID, academicData, ttl: academicTTL);
  }

  Map<String, dynamic>? getCachedAcademicInfo(String studentUID) {
    final data = get(academicBoxName, studentUID, ttl: academicTTL);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ──────────────────────────────────────────────
  // Attendance Helpers (with TTL)
  // ──────────────────────────────────────────────
  Future<void> cacheAttendanceReport(
    String studentUID,
    Map<String, dynamic> reportData,
  ) async {
    await put(attendanceBoxName, studentUID, reportData, ttl: attendanceTTL);
  }

  Map<String, dynamic>? getCachedAttendanceReport(String studentUID) {
    final data = get(attendanceBoxName, studentUID, ttl: attendanceTTL);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }
}
