class Reciter {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String baseUrl;

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.baseUrl,
  });

  String getAudioUrl(int surahId) {
    final paddedNumber = surahId.toString().padLeft(3, '0');
    return '$baseUrl/$paddedNumber.mp3';
  }
}
