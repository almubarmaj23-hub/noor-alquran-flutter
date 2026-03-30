import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../data/surahs_data.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0D9488), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Theme Toggle
                  _buildIconBtn(
                    icon: provider.isDark ? Icons.light_mode : Icons.dark_mode,
                    onTap: () => provider.toggleTheme(),
                  ),
                  // Language Toggle
                  GestureDetector(
                    onTap: () => provider.toggleLanguage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'En' : 'عربي',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // App Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.menu_book,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'نور القرآن' : 'Noor Al-Quran',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'استمع إلى تلاوات عطرة من كتاب الله'
                            : 'Listen to beautiful recitations',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats Cards
              Row(
                children: [
                  _buildStat(
                      '${surahs.length}', isAr ? 'سورة' : 'Surahs'),
                  _buildStat('$totalVerses', isAr ? 'آية' : 'Verses'),
                  _buildStat('$makkiCount', isAr ? 'مكية' : 'Makki'),
                  _buildStat('$madaniCount', isAr ? 'مدنية' : 'Madani'),
                ],
              ),
              const SizedBox(height: 12),
              // Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up,
                      color: Colors.white.withValues(alpha: 0.8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    isAr
                        ? '100 قارئ • تشغيل مباشر • تحميل مجاني'
                        : '100 Reciters • Live Streaming • Free Download',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
