import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/surah.dart';
import '../screens/surah_read_screen.dart';

class SurahListWidget extends StatelessWidget {
  const SurahListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final list = provider.filteredSurahs;
    final isAr = provider.isArabic;

    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'لا توجد نتائج' : 'No results found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  isAr
                      ? 'جرب تغيير معايير البحث أو الفلترة'
                      : 'Try changing search or filter criteria',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _SurahCard(surah: list[index]),
        childCount: list.length,
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final Surah surah;
  const _SurahCard({required this.surah});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;
    final isCurrent = provider.currentSurah?.id == surah.id;
    final isFav = provider.favorites.contains(surah.id);
    final theme = Theme.of(context);

    return Card(
      elevation: isCurrent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? const BorderSide(color: Color(0xFF10B981), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Number + Name + Fav
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isCurrent
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF0D9488)])
                        : null,
                    color: isCurrent ? null : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${surah.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCurrent ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? surah.nameArabic : surah.nameEnglish,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isAr)
                        Text(
                          surah.nameEnglish,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isFav)
                  const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ),
            const Spacer(),
            // Type + Verses
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: surah.type == 'مكية'
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: surah.type == 'مكية'
                          ? Colors.amber.withValues(alpha: 0.4)
                          : Colors.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    surah.type == 'مكية'
                        ? (isAr ? 'مكية' : 'Makki')
                        : (isAr ? 'مدنية' : 'Madani'),
                    style: TextStyle(
                      fontSize: 11,
                      color: surah.type == 'مكية'
                          ? Colors.amber[800]
                          : Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${surah.versesCount} ${isAr ? 'آية' : 'verse'}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Read + Tafsir button
            SizedBox(
              height: 34,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahReadScreen(surah: surah),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_stories, size: 14),
                label: Text(
                  isAr ? 'قراءة وتفسير' : 'Read & Tafsir',
                  style: const TextStyle(fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(
                      color: Color(0xFF1B5E20), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: () => provider.playSurah(surah),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      child: provider.isLoading && isCurrent
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              isCurrent && provider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 22,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => provider.toggleFavorite(surah.id),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: isFav
                            ? Colors.amber
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFav ? Colors.amber : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
