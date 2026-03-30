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
import '../data/surahs_data.dart';

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

class _FeatureCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;

    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.auto_stories,
            title: isAr ? 'التفاسير' : 'Tafsir',
            subtitle: isAr ? '10 تفاسير معتمدة' : '10 Tafsir Books',
            gradient: const [Color(0xFF1B5E20), Color(0xFF388E3C)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TafsirHomeScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FeatureCard(
            icon: Icons.text_fields,
            title: isAr ? 'الإعراب' : "I'rab",
            subtitle: isAr ? 'إعراب القرآن' : 'Grammar Analysis',
            gradient: const [Color(0xFF4A148C), Color(0xFF7B1FA2)],
            onTap: () {
              _showSurahPicker(context, isAr, 2);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FeatureCard(
            icon: Icons.help_outline,
            title: isAr ? 'الغريب' : 'Gharib',
            subtitle: isAr ? 'غريب القرآن' : 'Difficult Words',
            gradient: const [Color(0xFFE65100), Color(0xFFFF6D00)],
            onTap: () {
              _showSurahPicker(context, isAr, 3);
            },
          ),
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
                  // Handle bar
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
