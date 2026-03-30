import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/reciter_selector.dart';
import '../widgets/search_filter.dart';
import '../widgets/surah_list.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/footer_widget.dart';
import 'tafsir_home_screen.dart';
import 'surah_read_screen.dart';
import 'mushaf_screen.dart';
import '../data/surahs_data.dart';
import '../services/bookmark_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, _) {
        return Directionality(
          textDirection:
              provider.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: HeaderWidget()),
                    // Bookmark resume card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _BookmarkResumeCard(),
                      ),
                    ),
                    // Feature cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _FeatureCards(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: ReciterSelector(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: SearchFilterWidget(),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          16, 12, 16, provider.currentSurah != null ? 120 : 40),
                      sliver: SurahListWidget(),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom:
                                provider.currentSurah != null ? 100 : 0),
                        child: FooterWidget(),
                      ),
                    ),
                  ],
                ),
                if (provider.currentSurah != null)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AudioPlayerBar(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bookmark resume card - shows last reading position
class _BookmarkResumeCard extends StatefulWidget {
  @override
  State<_BookmarkResumeCard> createState() => _BookmarkResumeCardState();
}

class _BookmarkResumeCardState extends State<_BookmarkResumeCard> {
  Map<String, dynamic>? _lastReading;
  bool _hasBookmark = false;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final has = await BookmarkService.hasBookmark();
    if (has) {
      final data = await BookmarkService.getLastReading();
      if (mounted) {
        setState(() {
          _hasBookmark = true;
          _lastReading = data;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBookmark || _lastReading == null) return const SizedBox.shrink();

    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;
    final surahName = _lastReading!['surahName'] as String;
    final ayahNum = _lastReading!['ayahNumber'] as int;
    final lastPage = _lastReading!['lastPage'] as int;
    final timeAgo = BookmarkService.formatTimeAgo(_lastReading!['lastReadTime'] as String);

    if (surahName.isEmpty && lastPage <= 1) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (surahName.isNotEmpty && ayahNum > 0) {
          final surahId = _lastReading!['surahId'] as int;
          final surah = surahs.firstWhere(
            (s) => s.id == surahId,
            orElse: () => surahs.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahReadScreen(
                surah: surah,
                initialAyah: ayahNum,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MushafScreen(initialPage: lastPage),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064E3B).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'متابعة القراءة' : 'Continue Reading',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surahName.isNotEmpty
                        ? '${isAr ? "سورة" : "Surah"} $surahName - ${isAr ? "الآية" : "Ayah"} $ayahNum'
                        : '${isAr ? "صفحة" : "Page"} $lastPage',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.menu_book_rounded,
                title: isAr ? 'المصحف' : 'Mushaf',
                subtitle: isAr ? '٦٠٤ صفحة كاملة' : '604 Full Pages',
                gradient: const [Color(0xFF5D4037), Color(0xFFD4A843)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MushafScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FeatureCard(
                icon: Icons.auto_stories,
                title: isAr ? 'التفاسير' : 'Tafsir',
                subtitle: isAr ? '10 تفاسير معتمدة' : '10 Tafsir Books',
                gradient: const [Color(0xFF1B5E20), Color(0xFF388E3C)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TafsirHomeScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.text_fields,
                title: isAr ? 'الإعراب' : "I'rab",
                subtitle: isAr ? 'إعراب القرآن' : 'Grammar Analysis',
                gradient: const [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                onTap: () => _showSurahPicker(context, isAr, 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FeatureCard(
                icon: Icons.help_outline,
                title: isAr ? 'الغريب' : 'Gharib',
                subtitle: isAr ? 'غريب القرآن' : 'Difficult Words',
                gradient: const [Color(0xFFE65100), Color(0xFFFF6D00)],
                onTap: () => _showSurahPicker(context, isAr, 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSurahPicker(BuildContext context, bool isAr, int tabIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isAr
                          ? (tabIndex == 2
                              ? 'اختر سورة للإعراب'
                              : 'اختر سورة لغريب القرآن')
                          : (tabIndex == 2
                              ? "Select Surah for I'rab"
                              : 'Select Surah for Gharib'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: tabIndex == 2
                                      ? [
                                          const Color(0xFF4A148C),
                                          const Color(0xFF7B1FA2)
                                        ]
                                      : [
                                          const Color(0xFFE65100),
                                          const Color(0xFFFF6D00)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${surah.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              surah.nameArabic,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${surah.nameEnglish} - ${surah.versesCount} ${isAr ? "آية" : "verses"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                                Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SurahReadScreen(surah: surah),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
