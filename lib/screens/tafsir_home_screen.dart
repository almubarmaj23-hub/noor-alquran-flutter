import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../data/surahs_data.dart';
import '../models/surah.dart';
import 'surah_read_screen.dart';

class TafsirHomeScreen extends StatefulWidget {
  const TafsirHomeScreen({super.key});

  @override
  State<TafsirHomeScreen> createState() => _TafsirHomeScreenState();
}

class _TafsirHomeScreenState extends State<TafsirHomeScreen> {
  String _selectedEditionId = 'ar-tafsir-ibn-kathir';
  String _searchQuery = '';

  List<Surah> get _filteredSurahs {
    if (_searchQuery.isEmpty) return surahs;
    final q = _searchQuery.toLowerCase();
    return surahs
        .where((s) =>
            s.nameArabic.contains(_searchQuery) ||
            s.nameEnglish.toLowerCase().contains(q) ||
            s.id.toString() == _searchQuery)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentEdition = QuranService.tafsirEditions
        .firstWhere((e) => e.id == _selectedEditionId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1B5E20),
                        Color(0xFF2E7D32),
                        Color(0xFF388E3C)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.auto_stories,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'التفاسير المعتمدة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '10 تفاسير من أمهات كتب التفسير عند أهل السنة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Tafsir Edition Selector
            SliverToBoxAdapter(
              child: Container(
                height: 130,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: QuranService.tafsirEditions.length,
                  itemBuilder: (context, index) {
                    final edition = QuranService.tafsirEditions[index];
                    final isSelected = edition.id == _selectedEditionId;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedEditionId = edition.id),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    Color(edition.color),
                                    Color(edition.color)
                                        .withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark
                                  ? theme
                                      .colorScheme.surfaceContainerHighest
                                  : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.2)),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(edition.color)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIcon(edition.icon),
                              size: 28,
                              color: isSelected
                                  ? Colors.white
                                  : Color(edition.color),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              edition.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              edition.author,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Current edition info card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      Color(currentEdition.color).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(currentEdition.color)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getIcon(currentEdition.icon),
                            color: Color(currentEdition.color), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentEdition.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(currentEdition.color),
                                ),
                              ),
                              Text(
                                currentEdition.author,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentEdition.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Surah list header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'اختر السورة (${_filteredSurahs.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Surah list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final surah = _filteredSurahs[index];
                  return _buildSurahTile(surah, theme, isDark);
                },
                childCount: _filteredSurahs.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTile(Surah surah, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahReadScreen(surah: surah),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${surah.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.nameArabic,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            surah.nameEnglish,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: surah.type == 'مكية'
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${surah.type} - ${surah.versesCount} آية',
                              style: TextStyle(
                                fontSize: 10,
                                color: surah.type == 'مكية'
                                    ? Colors.amber[800]
                                    : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'book':
        return Icons.book;
      case 'history_edu':
        return Icons.history_edu;
      case 'gavel':
        return Icons.gavel;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'menu_book':
        return Icons.menu_book;
      case 'school':
        return Icons.school;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'summarize':
        return Icons.summarize;
      case 'translate':
        return Icons.translate;
      default:
        return Icons.book;
    }
  }
}
