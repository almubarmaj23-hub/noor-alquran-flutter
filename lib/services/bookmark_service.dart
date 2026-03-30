import 'package:shared_preferences/shared_preferences.dart';

/// Bookmark service for saving last reading position
class BookmarkService {
  static const String _lastPageKey = 'last_mushaf_page';
  static const String _lastSurahKey = 'last_surah_id';
  static const String _lastAyahKey = 'last_ayah_number';
  static const String _lastSurahNameKey = 'last_surah_name';
  static const String _lastReadTimeKey = 'last_read_time';

  // Save last mushaf page
  static Future<void> saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPageKey, page);
    await prefs.setString(_lastReadTimeKey, DateTime.now().toIso8601String());
  }

  // Get last mushaf page
  static Future<int> getLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPageKey) ?? 1;
  }

  // Save last reading position (surah + ayah)
  static Future<void> saveLastReading(int surahId, int ayahNumber, String surahName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSurahKey, surahId);
    await prefs.setInt(_lastAyahKey, ayahNumber);
    await prefs.setString(_lastSurahNameKey, surahName);
    await prefs.setString(_lastReadTimeKey, DateTime.now().toIso8601String());
  }

  // Get last reading position
  static Future<Map<String, dynamic>> getLastReading() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'surahId': prefs.getInt(_lastSurahKey) ?? 0,
      'ayahNumber': prefs.getInt(_lastAyahKey) ?? 0,
      'surahName': prefs.getString(_lastSurahNameKey) ?? '',
      'lastReadTime': prefs.getString(_lastReadTimeKey) ?? '',
      'lastPage': prefs.getInt(_lastPageKey) ?? 1,
    };
  }

  // Check if there is a saved bookmark
  static Future<bool> hasBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_lastSurahKey) || prefs.containsKey(_lastPageKey);
  }

  // Format time ago
  static String formatTimeAgo(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final time = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
    } catch (_) {
      return '';
    }
  }
}
