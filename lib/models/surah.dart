class Surah {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String type; // 'مكية' or 'مدنية'
  final int versesCount;

  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.type,
    required this.versesCount,
  });

  String get paddedId => id.toString().padLeft(3, '0');
}
