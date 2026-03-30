import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranService {
  static const String _quranBaseUrl = 'https://api.alquran.cloud/v1';
  static const String _tafsirBaseUrl =
      'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir';

  // Tafsir editions available - Arabic and English
  static const List<TafsirEdition> tafsirEditions = [
    // === التفاسير العربية ===
    TafsirEdition(
      id: 'ar-tafsir-ibn-kathir',
      name: 'تفسير ابن كثير',
      author: 'الحافظ ابن كثير',
      description: 'تفسير القرآن العظيم - من أشهر كتب التفسير بالمأثور',
      color: 0xFF1B5E20,
      icon: 'book',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafsir-al-tabari',
      name: 'تفسير الطبري',
      author: 'الإمام الطبري',
      description: 'جامع البيان عن تأويل آي القرآن - أعظم كتب التفسير بالمأثور',
      color: 0xFF0D47A1,
      icon: 'history_edu',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafseer-al-qurtubi',
      name: 'تفسير القرطبي',
      author: 'الإمام القرطبي',
      description: 'الجامع لأحكام القرآن - أفضل تفسير فقهي للقرآن',
      color: 0xFF4A148C,
      icon: 'gavel',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafseer-al-saddi',
      name: 'تفسير السعدي',
      author: 'الشيخ عبدالرحمن السعدي',
      description: 'تيسير الكريم الرحمن في تفسير كلام المنان',
      color: 0xFFE65100,
      icon: 'auto_stories',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafsir-al-baghawi',
      name: 'تفسير البغوي',
      author: 'الإمام البغوي',
      description: 'معالم التنزيل - من أفضل كتب التفسير بالمأثور',
      color: 0xFF880E4F,
      icon: 'menu_book',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafsir-al-wasit',
      name: 'التفسير الوسيط',
      author: 'محمد سيد طنطاوي',
      description: 'التفسير الوسيط للقرآن الكريم',
      color: 0xFF006064,
      icon: 'school',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafsir-muyassar',
      name: 'التفسير الميسر',
      author: 'مجمع الملك فهد',
      description: 'التفسير الميسر - سهل العبارة واضح المعنى',
      color: 0xFF33691E,
      icon: 'lightbulb',
      language: 'ar',
    ),
    TafsirEdition(
      id: 'ar-tafseer-tanwir-al-miqbas',
      name: 'تنوير المقباس',
      author: 'منسوب لابن عباس',
      description: 'تنوير المقباس من تفسير ابن عباس',
      color: 0xFF3E2723,
      icon: 'wb_sunny',
      language: 'ar',
    ),
    // === التفاسير الإنجليزية ===
    TafsirEdition(
      id: 'en-al-jalalayn',
      name: 'تفسير الجلالين (إنجليزي)',
      author: 'جلال الدين المحلي والسيوطي',
      description: 'Tafsir al-Jalalayn - The most famous concise tafsir, translated to English',
      color: 0xFF263238,
      icon: 'summarize',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-tafisr-ibn-kathir',
      name: 'ابن كثير (إنجليزي)',
      author: 'الحافظ ابن كثير',
      description: 'Abridged Tafsir Ibn Kathir - English translation of the renowned tafsir',
      color: 0xFF1A237E,
      icon: 'translate',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-tafsir-ibn-abbas',
      name: 'تفسير ابن عباس (إنجليزي)',
      author: 'عبدالله بن عباس',
      description: 'Tafsir Ibn Abbas - English translation attributed to the great companion',
      color: 0xFF4E342E,
      icon: 'person',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-al-qushairi-tafsir',
      name: 'تفسير القشيري (إنجليزي)',
      author: 'الإمام القشيري',
      description: 'Lataif al-Isharat - Qushayri\'s mystical Quran commentary in English',
      color: 0xFF5D4037,
      icon: 'self_improvement',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-kashani-tafsir',
      name: 'تفسير الكاشاني (إنجليزي)',
      author: 'عبدالرزاق الكاشاني',
      description: 'Kashani\'s Tafsir - Spiritual and mystical Quran interpretation in English',
      color: 0xFF37474F,
      icon: 'spa',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-tafsir-al-tustari',
      name: 'تفسير التستري (إنجليزي)',
      author: 'سهل بن عبدالله التستري',
      description: 'Tafsir al-Tustari - One of the earliest Sufi commentaries, translated to English',
      color: 0xFF455A64,
      icon: 'psychology',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-kashf-al-asrar-tafsir',
      name: 'كشف الأسرار (إنجليزي)',
      author: 'الميبدي',
      description: 'Kashf al-Asrar - Unveiling the Secrets, a comprehensive Persian tafsir in English',
      color: 0xFF795548,
      icon: 'visibility',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-asbab-al-nuzul-by-al-wahidi',
      name: 'أسباب النزول (إنجليزي)',
      author: 'الإمام الواحدي',
      description: 'Asbab al-Nuzul - Occasions of revelation by al-Wahidi, essential companion text',
      color: 0xFF6D4C41,
      icon: 'history',
      language: 'en',
    ),
    TafsirEdition(
      id: 'en-tafsir-maarif-ul-quran',
      name: 'معارف القرآن (إنجليزي)',
      author: 'المفتي محمد شفيع',
      description: 'Ma\'ariful Quran - Comprehensive modern tafsir by Mufti Muhammad Shafi in English',
      color: 0xFF546E7A,
      icon: 'menu_book',
      language: 'en',
    ),
  ];

  /// Fetch Quran text for a specific surah
  static Future<List<Ayah>> fetchSurahText(int surahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_quranBaseUrl/surah/$surahNumber/ar.alafasy'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final ayahs = data['data']['ayahs'] as List;
          return ayahs.map((a) => Ayah.fromJson(a)).toList();
        }
      }
    } catch (_) {}

    // Fallback: try quran-uthmani edition
    try {
      final response = await http.get(
        Uri.parse('$_quranBaseUrl/surah/$surahNumber/quran-uthmani'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final ayahs = data['data']['ayahs'] as List;
          return ayahs.map((a) => Ayah.fromJson(a)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch tafsir for a specific surah from a specific edition
  static Future<List<TafsirAyah>> fetchTafsir(
      String editionId, int surahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_tafsirBaseUrl/$editionId/$surahNumber.json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The API returns an object with ayahs array or similar structure
        if (data is Map) {
          // Handle different response formats
          List<dynamic>? ayahsList;
          if (data.containsKey('ayahs')) {
            ayahsList = data['ayahs'] as List?;
          } else if (data.containsKey('result')) {
            ayahsList = data['result'] as List?;
          } else if (data.containsKey('ayah')) {
            ayahsList = data['ayah'] as List?;
          }
          if (ayahsList != null) {
            return ayahsList.map((a) => TafsirAyah.fromJson(a)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch tafsir for a specific ayah
  static Future<String?> fetchAyahTafsir(
      String editionId, int surahNumber, int ayahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_tafsirBaseUrl/$editionId/$surahNumber/$ayahNumber.json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          return data['text'] as String? ?? data['tafsir'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch word-by-word data for Quran ayah
  static Future<List<Map<String, dynamic>>> fetchWordByWord(int surahNumber, int ayahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.quran.com/api/v4/verses/by_key/$surahNumber:$ayahNumber?language=ar&words=true&word_fields=text_uthmani,translation'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final words = data['verse']?['words'] as List? ?? [];
        return words.map((w) => {
          'text': w['text_uthmani'] as String? ?? '',
          'translation': w['translation']?['text'] as String? ?? '',
          'transliteration': w['transliteration']?['text'] as String? ?? '',
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}

class TafsirEdition {
  final String id;
  final String name;
  final String author;
  final String description;
  final int color;
  final String icon;
  final String language;

  const TafsirEdition({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.color,
    required this.icon,
    this.language = 'ar',
  });

  bool get isArabic => language == 'ar';
  bool get isEnglish => language == 'en';
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int page;
  final int hizbQuarter;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    this.juz = 0,
    this.page = 0,
    this.hizbQuarter = 0,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      juz: json['juz'] as int? ?? 0,
      page: json['page'] as int? ?? 0,
      hizbQuarter: json['hizbQuarter'] as int? ?? 0,
    );
  }
}

class TafsirAyah {
  final int ayahNumber;
  final String text;

  TafsirAyah({required this.ayahNumber, required this.text});

  factory TafsirAyah.fromJson(Map<String, dynamic> json) {
    return TafsirAyah(
      ayahNumber: json['ayah'] as int? ??
          json['numberInSurah'] as int? ??
          json['verse_number'] as int? ??
          json['number'] as int? ??
          0,
      text: json['text'] as String? ?? json['tafsir'] as String? ?? '',
    );
  }
}
