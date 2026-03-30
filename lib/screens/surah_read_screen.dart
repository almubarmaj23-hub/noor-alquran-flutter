import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/surah.dart';
import '../providers/audio_provider.dart';
import '../services/quran_service.dart';
import '../services/bookmark_service.dart';

class SurahReadScreen extends StatefulWidget {
  final Surah surah;
  final int? initialAyah;
  const SurahReadScreen({super.key, required this.surah, this.initialAyah});

  @override
  State<SurahReadScreen> createState() => _SurahReadScreenState();
}

class _SurahReadScreenState extends State<SurahReadScreen>
    with SingleTickerProviderStateMixin {
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedAyah;
  late TabController _tabController;
  final ScrollController _readingScrollController = ScrollController();

  // Colors
  static const Color _primaryGreen = Color(0xFF059669);
  static const Color _darkGreen = Color(0xFF047857);
  static const Color _teal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAyahs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _readingScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAyahs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ayahs = await QuranService.fetchSurahText(widget.surah.id);
      if (mounted) {
        setState(() {
          _ayahs = ayahs;
          _isLoading = false;
        });
        // Scroll to initial ayah if provided
        if (widget.initialAyah != null && widget.initialAyah! > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAyah(widget.initialAyah!);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل في تحميل الآيات. تحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToAyah(int ayahNumber) {
    // Approximate scroll position
    const cardHeight = 140.0;
    final targetOffset = (ayahNumber - 1) * cardHeight;
    if (_readingScrollController.hasClients) {
      _readingScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF8FFFE),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: _primaryGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildAppBarBackground(provider),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled, color: Colors.white, size: 30),
                    onPressed: () => provider.playSurah(widget.surah),
                    tooltip: 'تشغيل السورة',
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: _buildTabBar(),
                ),
              ),
            ];
          },
          body: _isLoading
              ? _buildLoadingWidget()
              : _error != null
                  ? _buildErrorWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReadingTab(theme, isDark),
                        _TafsirTab(surah: widget.surah, ayahs: _ayahs),
                        _IrabTab(surah: widget.surah, ayahs: _ayahs),
                        _GharibTab(surah: widget.surah, ayahs: _ayahs),
                        _AyahNavigatorTab(
                          surah: widget.surah,
                          ayahs: _ayahs,
                          onNavigateToTafsir: () => _tabController.animateTo(1),
                          onNavigateToIrab: () => _tabController.animateTo(2),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildAppBarBackground(AudioProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF064E3B), _primaryGreen, _teal],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.surah.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.surah.nameArabic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        widget.surah.nameEnglish,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoChip(Icons.format_list_numbered_rtl, '${widget.surah.versesCount} آية'),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    widget.surah.type == 'مكية' ? Icons.wb_sunny_outlined : Icons.location_city_outlined,
                    widget.surah.type,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.menu_book_outlined, 'السورة ${widget.surah.id}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _primaryGreen,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.menu_book, size: 16), text: 'القراءة'),
          Tab(icon: Icon(Icons.auto_stories, size: 16), text: 'التفسير'),
          Tab(icon: Icon(Icons.text_fields, size: 16), text: 'الإعراب'),
          Tab(icon: Icon(Icons.help_outline, size: 16), text: 'الغريب'),
          Tab(icon: Icon(Icons.find_in_page, size: 16), text: 'الآيات'),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _primaryGreen, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل سورة ${widget.surah.nameArabic}...',
            style: const TextStyle(fontSize: 16, color: _primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadAyahs,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingTab(ThemeData theme, bool isDark) {
    return ListView(
      controller: _readingScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Bismillah
        if (widget.surah.id != 1 && widget.surah.id != 9)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                    : [const Color(0xFFF0FFF4), const Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: _primaryGreen,
                  height: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ..._ayahs.map((ayah) => _buildAyahCard(ayah, theme, isDark)),
      ],
    );
  }

  Widget _buildAyahCard(Ayah ayah, ThemeData theme, bool isDark) {
    final isSelected = _selectedAyah == ayah.numberInSurah;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF052E16) : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF1C2A36) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? _primaryGreen : theme.colorScheme.outline.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _primaryGreen.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedAyah = isSelected ? null : ayah.numberInSurah);
          // Save bookmark on tap
          BookmarkService.saveLastReading(
            widget.surah.id,
            ayah.numberInSurah,
            widget.surah.nameArabic,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  // Ayah number badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryGreen, _darkGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Meta chips
                  if (ayah.juz > 0) ...[
                    _buildMetaChip('جزء ${ayah.juz}', Colors.teal),
                    const SizedBox(width: 4),
                  ],
                  if (ayah.page > 0)
                    _buildMetaChip('ص${ayah.page}', Colors.blue),
                  // Action menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    onSelected: (value) => _handleAyahAction(value, ayah),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text('نسخ الآية'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18, color: Color(0xFF0D9488)),
                            SizedBox(width: 8),
                            Text('مشاركة الآية'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'tafsir',
                        child: Row(
                          children: [
                            Icon(Icons.auto_stories, size: 18, color: Color(0xFF1B5E20)),
                            SizedBox(width: 8),
                            Text('تفسير هذه الآية'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'irab',
                        child: Row(
                          children: [
                            Icon(Icons.text_fields, size: 18, color: Colors.purple),
                            SizedBox(width: 8),
                            Text('إعراب هذه الآية'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Ayah text
              Text(
                ayah.text,
                style: TextStyle(
                  fontSize: 24,
                  height: 2.3,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
              // Action bar when selected
              if (isSelected) ...[
                const SizedBox(height: 12),
                Divider(color: _primaryGreen.withValues(alpha: 0.2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(Icons.auto_stories, 'التفسير', _primaryGreen, () {
                      _tabController.animateTo(1);
                    }),
                    _buildQuickAction(Icons.text_fields, 'الإعراب', Colors.purple, () {
                      _tabController.animateTo(2);
                    }),
                    _buildQuickAction(Icons.help_outline, 'الغريب', Colors.deepOrange, () {
                      _tabController.animateTo(3);
                    }),
                    _buildQuickAction(Icons.copy, 'نسخ', Colors.blue, () {
                      _handleAyahAction('copy', ayah);
                    }),
                    _buildQuickAction(Icons.share, 'مشاركة', Colors.teal, () {
                      _handleAyahAction('share', ayah);
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _handleAyahAction(String action, Ayah ayah) {
    final surahName = widget.surah.nameArabic;
    final ayahText = ayah.text;
    final ayahNum = ayah.numberInSurah;
    final reference = 'سورة $surahName - الآية $ayahNum';

    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: '$ayahText\n($reference)'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('تم نسخ الآية بنجاح'),
              ],
            ),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case 'share':
        SharePlus.instance.share(ShareParams(
          text: '$ayahText\n\n$reference\n\nمن تطبيق نور القرآن',
          subject: reference,
        ));
        break;
      case 'tafsir':
        // Show quick tafsir bottom sheet for this specific ayah
        _showQuickTafsir(ayah);
        break;
      case 'irab':
        _tabController.animateTo(2);
        break;
    }
  }

  void _showQuickTafsir(Ayah ayah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickTafsirSheet(
        surah: widget.surah,
        ayah: ayah,
      ),
    );
  }
}

/// =========== QUICK TAFSIR SHEET ===========
/// يعرض تفسير آية محددة في bottom sheet مع اختيار كتاب التفسير
class _QuickTafsirSheet extends StatefulWidget {
  final Surah surah;
  final Ayah ayah;

  const _QuickTafsirSheet({required this.surah, required this.ayah});

  @override
  State<_QuickTafsirSheet> createState() => _QuickTafsirSheetState();
}

class _QuickTafsirSheetState extends State<_QuickTafsirSheet> {
  String _selectedEdition = 'ar-tafsir-ibn-kathir';
  String? _tafsirText;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTafsir();
  }

  Future<void> _fetchTafsir() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final text = await QuranService.fetchAyahTafsir(
        _selectedEdition,
        widget.surah.id,
        widget.ayah.numberInSurah,
      );
      if (mounted) {
        setState(() {
          _tafsirText = text ?? 'لا يتوفر تفسير لهذه الآية في هذا الكتاب حالياً.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل التفسير. تحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  TafsirEdition get _currentEdition =>
      QuranService.tafsirEditions.firstWhere((e) => e.id == _selectedEdition);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final edition = _currentEdition;
    final editionColor = Color(edition.color);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2A36) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header with ayah info
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [editionColor.withValues(alpha: 0.15), editionColor.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: editionColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: editionColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.auto_stories, color: editionColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفسير الآية ${widget.ayah.numberInSurah} من سورة ${widget.surah.nameArabic}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: editionColor),
                            ),
                            Text(edition.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Share button
                      if (_tafsirText != null)
                        IconButton(
                          onPressed: () {
                            final text = '📖 ${edition.name}\n\n'
                                'سورة ${widget.surah.nameArabic} - الآية ${widget.ayah.numberInSurah}\n\n'
                                '﴿ ${widget.ayah.text} ﴾\n\n$_tafsirText\n\n— من تطبيق نور القرآن';
                            SharePlus.instance.share(ShareParams(text: text));
                          },
                          icon: const Icon(Icons.share_rounded, size: 20),
                          color: editionColor,
                          tooltip: 'مشاركة التفسير',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Ayah text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.ayah.text,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 18, height: 2.1, fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
            // Edition Selector (horizontal)
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: QuranService.tafsirEditions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final ed = QuranService.tafsirEditions[index];
                  final isSelected = ed.id == _selectedEdition;
                  final edColor = Color(ed.color);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEdition = ed.id);
                      _fetchTafsir();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? edColor : edColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: edColor.withValues(alpha: isSelected ? 1 : 0.3)),
                      ),
                      child: Text(
                        ed.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : edColor,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Tafsir content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: editionColor, strokeWidth: 2),
                          const SizedBox(height: 12),
                          Text('جاري تحميل التفسير...', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _fetchTafsir,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: editionColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.format_quote_rounded, color: editionColor.withValues(alpha: 0.4), size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      edition.author,
                                      style: TextStyle(
                                        color: editionColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  _tafsirText ?? '',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 2.0,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.88)
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =========== TAFSIR TAB ===========
class _TafsirTab extends StatefulWidget {
  final Surah surah;
  final List<Ayah> ayahs;
  const _TafsirTab({required this.surah, required this.ayahs});

  @override
  State<_TafsirTab> createState() => _TafsirTabState();
}

class _TafsirTabState extends State<_TafsirTab> with AutomaticKeepAliveClientMixin {
  String _selectedEdition = 'ar-tafsir-ibn-kathir';
  List<TafsirAyah> _tafsirData = [];
  bool _isLoading = false;
  String? _error;
  int? _jumpToAyah;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _ayahSearchController = TextEditingController();



  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTafsir();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ayahSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTafsir() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await QuranService.fetchTafsir(_selectedEdition, widget.surah.id);
      if (mounted) setState(() { _tafsirData = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'فشل في تحميل التفسير'; _isLoading = false; });
    }
  }

  TafsirEdition get _currentEdition =>
      QuranService.tafsirEditions.firstWhere((e) => e.id == _selectedEdition);

  void _showAyahJumpDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.find_in_page, color: Color(_currentEdition.color)),
              const SizedBox(width: 8),
              const Text('انتقل إلى آية', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل رقم الآية (1 - ${widget.surah.versesCount})',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'رقم الآية',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(_currentEdition.color), width: 2),
                  ),
                ),
                onSubmitted: (v) {
                  Navigator.pop(ctx);
                  _jumpToAyahNumber(int.tryParse(v) ?? 1);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Color(_currentEdition.color)),
              onPressed: () {
                Navigator.pop(ctx);
                _jumpToAyahNumber(int.tryParse(ctrl.text) ?? 1);
              },
              child: const Text('انتقل'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _jumpToAyahNumber(int ayahNum) {
    final clampedAyah = ayahNum.clamp(1, widget.surah.versesCount);
    setState(() => _jumpToAyah = clampedAyah);
    // Scroll to the ayah
    final index = _tafsirData.indexWhere((t) => t.ayahNumber == clampedAyah);
    if (index != -1 && _scrollController.hasClients) {
      const cardHeight = 200.0;
      _scrollController.animateTo(
        index * cardHeight,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _shareTafsirAyah(TafsirAyah tafsir) {
    final ayahObj = widget.ayahs.where((a) => a.numberInSurah == tafsir.ayahNumber).firstOrNull;
    final surahName = widget.surah.nameArabic;
    final text = StringBuffer();
    text.writeln('📖 تفسير الآية ${tafsir.ayahNumber} من سورة $surahName');
    text.writeln('المصدر: ${_currentEdition.name}');
    text.writeln();
    if (ayahObj != null) {
      text.writeln('﴿ ${ayahObj.text} ﴾');
      text.writeln();
    }
    text.writeln(tafsir.text);
    text.writeln();
    text.writeln('— من تطبيق نور القرآن');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ---- Edition Selector ----
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2A36) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: QuranService.tafsirEditions.length,
                  itemBuilder: (context, index) {
                    final edition = QuranService.tafsirEditions[index];
                    final isSelected = edition.id == _selectedEdition;
                    return GestureDetector(
                      onTap: () { setState(() => _selectedEdition = edition.id); _loadTafsir(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? LinearGradient(
                            colors: [Color(edition.color), Color(edition.color).withValues(alpha: 0.7)],
                          ) : null,
                          color: isSelected ? null : (isDark ? const Color(0xFF2A3A46) : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Color(edition.color) : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: Color(edition.color).withValues(alpha: 0.3), blurRadius: 8)
                          ] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getIconData(edition.icon), size: 22,
                                color: isSelected ? Colors.white : Color(edition.color)),
                            const SizedBox(height: 5),
                            Text(
                              edition.name,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Edition info + jump to ayah
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Icon(_getIconData(_currentEdition.icon), color: Color(_currentEdition.color), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentEdition.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(_currentEdition.color)),
                          ),
                          Text(
                            _currentEdition.author,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Jump to ayah button
                    TextButton.icon(
                      onPressed: _showAyahJumpDialog,
                      icon: Icon(Icons.find_in_page, size: 16, color: Color(_currentEdition.color)),
                      label: Text(
                        'انتقل لآية',
                        style: TextStyle(fontSize: 12, color: Color(_currentEdition.color)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ---- Content ----
        Expanded(
          child: _isLoading
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF059669)),
                    SizedBox(height: 12),
                    Text('جاري تحميل التفسير...'),
                  ],
                ))
              : _error != null
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _loadTafsir, child: const Text('إعادة المحاولة')),
                      ],
                    ))
                  : _tafsirData.isEmpty
                      ? _buildNoDataWidget()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _tafsirData.length,
                          itemBuilder: (context, index) {
                            final tafsir = _tafsirData[index];
                            final isHighlighted = _jumpToAyah == tafsir.ayahNumber;
                            return _buildTafsirCard(tafsir, theme, isDark, isHighlighted);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('لا يتوفر تفسير لهذه السورة', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('جرب اختيار تفسير آخر', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTafsirCard(TafsirAyah tafsir, ThemeData theme, bool isDark, bool isHighlighted) {
    final ayahText = widget.ayahs.where((a) => a.numberInSurah == tafsir.ayahNumber).firstOrNull?.text;
    final editionColor = Color(_currentEdition.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2A36) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isHighlighted ? Border.all(color: editionColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? editionColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isHighlighted ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [editionColor, editionColor.withValues(alpha: 0.75)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${tafsir.ayahNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'الآية ${tafsir.ayahNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                // Share button
                GestureDetector(
                  onTap: () => _shareTafsirAyah(tafsir),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share_outlined, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                // Copy tafsir button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: tafsir.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم نسخ التفسير'),
                        backgroundColor: editionColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_outlined, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Ayah text
          if (ayahText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: editionColor.withValues(alpha: 0.04),
                border: Border(
                  bottom: BorderSide(color: editionColor.withValues(alpha: 0.1)),
                ),
              ),
              child: Text(
                ayahText,
                style: TextStyle(
                  fontSize: 21,
                  height: 2.1,
                  fontWeight: FontWeight.w500,
                  color: editionColor.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          // Tafsir text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tafsir.text,
              style: TextStyle(
                fontSize: 15.5,
                height: 2.0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const map = {
      'book': Icons.book,
      'history_edu': Icons.history_edu,
      'gavel': Icons.gavel,
      'auto_stories': Icons.auto_stories,
      'menu_book': Icons.menu_book,
      'school': Icons.school,
      'lightbulb': Icons.lightbulb,
      'wb_sunny': Icons.wb_sunny,
      'summarize': Icons.summarize,
      'translate': Icons.translate,
    };
    return map[iconName] ?? Icons.book;
  }
}

/// =========== I'RAB TAB (Modern Arabic Grammar) ===========
class _IrabTab extends StatefulWidget {
  final Surah surah;
  final List<Ayah> ayahs;
  const _IrabTab({required this.surah, required this.ayahs});

  @override
  State<_IrabTab> createState() => _IrabTabState();
}

class _IrabTabState extends State<_IrabTab> with AutomaticKeepAliveClientMixin {
  final Map<int, List<_WordIrab>> _irabCache = {};
  bool _isLoading = false;
  int _selectedAyahIndex = 0;
  bool _showWordView = true; // word view or full view

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.ayahs.isNotEmpty) {
      _loadIrab(0);
    }
  }

  Future<void> _loadIrab(int index) async {
    if (index < 0 || index >= widget.ayahs.length) return;
    final ayah = widget.ayahs[index];

    setState(() {
      _isLoading = true;
      _selectedAyahIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 150)); // smooth transition

    if (!_irabCache.containsKey(ayah.numberInSurah)) {
      _irabCache[ayah.numberInSurah] = _analyzeAyah(ayah.text);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // Modern Arabic Grammar Analysis
  List<_WordIrab> _analyzeAyah(String text) {
    final words = text.split(RegExp(r'\s+'));
    final results = <_WordIrab>[];

    for (int i = 0; i < words.length; i++) {
      if (words[i].trim().isEmpty) continue;
      final fullWord = words[i];
      final clean = _removeHarakat(fullWord);
      results.add(_analyzeWordModern(fullWord, clean, i, words.length));
    }
    return results;
  }

  String _removeHarakat(String word) {
    return word.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0600-\u0605\u06DD]'),
      '',
    );
  }

  _WordIrab _analyzeWordModern(String full, String clean, int pos, int total) {
    Map<String, String>? m;
    
    m = _checkParticles(clean);
    if (m != null) return _WordIrab.fromMap(full, clean, m);

    m = _checkPronouns(clean, pos);
    if (m != null) return _WordIrab.fromMap(full, clean, m);

    if (_isVerb(clean)) {
      return _WordIrab.fromMap(full, clean, _analyzeVerb(clean, full, pos));
    }

    return _WordIrab.fromMap(full, clean, _analyzeNoun(clean, full, pos, total));
  }

  Map<String, String>? _checkParticles(String w) {
    final particles = <String, Map<String, String>>{
      'إن': {'type': 'حرف', 'category': 'حرف ناسخ', 'irab': 'حرف توكيد ونصب', 'build': 'مبني على الفتح، ينصب الاسم ويرفع الخبر', 'note': 'من أخوات إنّ'},
      'أن': {'type': 'حرف', 'category': 'حرف ناسخ', 'irab': 'حرف مصدري ونصب', 'build': 'مبني على الفتح'},
      'كأن': {'type': 'حرف', 'category': 'حرف ناسخ', 'irab': 'حرف تشبيه ونصب', 'build': 'مبني على الفتح'},
      'لكن': {'type': 'حرف', 'category': 'حرف ناسخ', 'irab': 'حرف استدراك ونصب', 'build': 'مبني على الفتح'},
      'ليت': {'type': 'حرف', 'category': 'حرف ناسخ', 'irab': 'حرف تمنٍّ ونصب', 'build': 'مبني على الفتح'},
      'لعل': {'type': 'حرف', 'category': 'حرف ناسخ', 'irab': 'حرف ترجٍّ ونصب', 'build': 'مبني على الفتح'},
      'لا': {'type': 'حرف', 'category': 'حرف نفي', 'irab': 'حرف نفي', 'build': 'مبني على السكون، لا محل له من الإعراب'},
      'ما': {'type': 'حرف', 'category': 'حرف نفي/مصدري', 'irab': 'حرف نفي أو اسم موصول', 'build': 'مبني على السكون'},
      'لم': {'type': 'حرف', 'category': 'حرف جازم', 'irab': 'حرف جزم ونفي وقلب', 'build': 'مبني على السكون، يجزم الفعل المضارع'},
      'لن': {'type': 'حرف', 'category': 'حرف ناصب', 'irab': 'حرف نفي ونصب واستقبال', 'build': 'مبني على السكون، ينصب الفعل المضارع'},
      'قد': {'type': 'حرف', 'category': 'حرف تحقيق', 'irab': 'حرف تحقيق وتوقع', 'build': 'مبني على السكون، لا محل له من الإعراب'},
      'سوف': {'type': 'حرف', 'category': 'حرف تسويف', 'irab': 'حرف استقبال وتسويف', 'build': 'مبني على الفتح، لا محل له من الإعراب'},
      'بل': {'type': 'حرف', 'category': 'حرف عطف', 'irab': 'حرف إضراب وعطف', 'build': 'مبني على السكون'},
      'حتى': {'type': 'حرف', 'category': 'حرف غاية', 'irab': 'حرف غاية وجر أو ناصب', 'build': 'مبني على السكون'},
      'كي': {'type': 'حرف', 'category': 'حرف تعليل', 'irab': 'حرف تعليل ونصب', 'build': 'مبني على السكون'},
      'لو': {'type': 'حرف', 'category': 'حرف شرط', 'irab': 'حرف شرط غير جازم', 'build': 'مبني على السكون، يدل على امتناع الجواب لامتناع الشرط'},
      'إذا': {'type': 'ظرف', 'category': 'ظرف زمان', 'irab': 'ظرف لما يستقبل من الزمان', 'build': 'مبني على السكون في محل نصب، متضمن معنى الشرط'},
      'إذ': {'type': 'ظرف', 'category': 'ظرف زمان', 'irab': 'ظرف زمان للماضي', 'build': 'مبني على السكون في محل نصب'},
      'إلا': {'type': 'أداة', 'category': 'أداة استثناء', 'irab': 'أداة حصر واستثناء', 'build': 'مبني على السكون، لا محل له من الإعراب'},
      'ثم': {'type': 'حرف', 'category': 'حرف عطف', 'irab': 'حرف عطف للترتيب والتراخي', 'build': 'مبني على الفتح'},
      'و': {'type': 'حرف', 'category': 'حرف عطف', 'irab': 'حرف عطف للجمع', 'build': 'مبني على الفتح'},
      'ف': {'type': 'حرف', 'category': 'حرف عطف', 'irab': 'حرف عطف للترتيب والتعقيب', 'build': 'مبني على الفتح'},
      'أو': {'type': 'حرف', 'category': 'حرف عطف', 'irab': 'حرف عطف للتخيير أو الإباحة', 'build': 'مبني على السكون'},
      'في': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر', 'build': 'مبني على السكون، يجر ما بعده'},
      'من': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للابتداء أو التبعيض', 'build': 'مبني على السكون'},
      'إلى': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للانتهاء', 'build': 'مبني على السكون'},
      'على': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للاستعلاء', 'build': 'مبني على السكون'},
      'عن': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للمجاوزة', 'build': 'مبني على السكون'},
      'ب': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للإلصاق', 'build': 'مبني على الكسر'},
      'ل': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للملك أو التعليل', 'build': 'مبني على الكسر'},
      'ك': {'type': 'حرف', 'category': 'حرف جر', 'irab': 'حرف جر للتشبيه', 'build': 'مبني على الفتح'},
      'الذي': {'type': 'اسم', 'category': 'اسم موصول', 'irab': 'اسم موصول للمفرد المذكر', 'build': 'مبني على السكون'},
      'التي': {'type': 'اسم', 'category': 'اسم موصول', 'irab': 'اسم موصول للمفردة المؤنثة', 'build': 'مبني على السكون'},
      'الذين': {'type': 'اسم', 'category': 'اسم موصول', 'irab': 'اسم موصول لجمع المذكر', 'build': 'مبني على الفتح'},
      'هذا': {'type': 'اسم', 'category': 'اسم إشارة', 'irab': 'اسم إشارة للمفرد المذكر القريب', 'build': 'مبني على السكون'},
      'هذه': {'type': 'اسم', 'category': 'اسم إشارة', 'irab': 'اسم إشارة للمفردة المؤنثة القريبة', 'build': 'مبني على الكسر'},
      'ذلك': {'type': 'اسم', 'category': 'اسم إشارة', 'irab': 'اسم إشارة للمفرد المذكر البعيد', 'build': 'مبني على الفتح'},
      'تلك': {'type': 'اسم', 'category': 'اسم إشارة', 'irab': 'اسم إشارة للمفردة المؤنثة البعيدة', 'build': 'مبني على الفتح'},
      'هؤلاء': {'type': 'اسم', 'category': 'اسم إشارة', 'irab': 'اسم إشارة لجمع العاقل القريب', 'build': 'مبني على الكسر'},
      'أولئك': {'type': 'اسم', 'category': 'اسم إشارة', 'irab': 'اسم إشارة لجمع العاقل البعيد', 'build': 'مبني على الفتح'},
    };
    return particles[w];
  }

  Map<String, String>? _checkPronouns(String w, int pos) {
    final pronouns = <String, Map<String, String>>{
      'هو': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل للغائب المفرد المذكر', 'build': 'مبني على الفتح في محل ${pos == 0 ? "رفع مبتدأ" : "رفع أو نصب"}'},
      'هي': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل للغائبة المفردة المؤنثة', 'build': 'مبني على الفتح'},
      'هم': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل لجمع الغائبين المذكر', 'build': 'مبني على السكون'},
      'هن': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل لجمع الغائبات المؤنث', 'build': 'مبني على الفتح'},
      'أنت': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل للمخاطب المفرد المذكر', 'build': 'مبني على الفتح'},
      'أنتم': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل لجمع المخاطبين', 'build': 'مبني على السكون'},
      'أنا': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل للمتكلم المفرد', 'build': 'مبني على السكون'},
      'نحن': {'type': 'ضمير', 'category': 'ضمير منفصل', 'irab': 'ضمير منفصل للمتكلمين', 'build': 'مبني على الضم'},
    };
    final result = pronouns[w];
    if (result != null) return result;
    return null;
  }

  bool _isVerb(String w) {
    if (w.length < 2) { return false; }
    // Past tense patterns (including attached pronouns)
    if (w.endsWith('وا') || w.endsWith('تم') || w.endsWith('نا') || w.endsWith('تن') ||
        w.endsWith('تما') || w.endsWith('تموا') || (w.endsWith('ت') && w.length > 3)) { return true; }
    // Present tense prefixes: ي، ت، ن، أ with min length
    if ((w.startsWith('ي') || w.startsWith('ت') || w.startsWith('ن') || w.startsWith('أ')) && w.length > 3) { return true; }
    // Imperative: starts with ا (alef wasl)
    if (w.startsWith('ا') && w.length > 3 && !w.startsWith('ال')) { return true; }
    // Common Quran verb roots to help detection
    const verbRoots = ['قَالَ', 'قال', 'كان', 'جاء', 'رأى', 'أَمَرَ', 'نزل', 'خلق', 'علم', 'أعلم',
      'آمن', 'كفر', 'عبد', 'شكر', 'ذكر', 'دخل', 'خرج', 'أرسل', 'أنزل', 'هدى', 'ضل',
      'فعل', 'قدر', 'وعد', 'وعظ', 'أمر', 'نهى', 'حكم', 'عدل', 'ظلم'];
    if (verbRoots.contains(w)) return true;
    return false;
  }

  /// تحليل متقدم للفعل - يأخذ في الاعتبار الحركات والضمائر المتصلة
  Map<String, String> _analyzeVerb(String clean, String full, int pos) {
    String tense, form, sign, note = '', subject = '';

    // ---- تحديد نوع الفعل ----
    if (clean.endsWith('وا')) {
      tense = 'ماضٍ';
      form = 'مبني على الضم';
      sign = 'الضمة المقدرة قبل واو الجماعة';
      subject = 'واو الجماعة: فاعل مبني على السكون في محل رفع';
    } else if (clean.endsWith('تموا') || clean.endsWith('تم')) {
      tense = 'ماضٍ';
      form = 'مبني على السكون';
      sign = 'السكون';
      subject = 'ضمير المخاطبين: فاعل مبني في محل رفع';
    } else if (clean.endsWith('نا')) {
      tense = 'ماضٍ';
      form = 'مبني على السكون';
      sign = 'السكون';
      subject = '"نا": ضمير المتكلمين، فاعل مبني في محل رفع';
    } else if (clean.endsWith('تما')) {
      tense = 'ماضٍ';
      form = 'مبني على السكون';
      sign = 'السكون';
      subject = 'ضمير المثنى: فاعل مبني في محل رفع';
    } else if (clean.endsWith('ت') && clean.length > 3) {
      tense = 'ماضٍ';
      form = 'مبني على الفتح';
      sign = 'الفتح الظاهر';
      // تحقق هل هو تاء التأنيث أم تاء الفاعل
      final lastChar = full.length > 1 ? full[full.length - 2] : '';
      if (lastChar == '\u064E') { // فتحة قبل التاء = تاء الفاعل
        subject = 'تاء الفاعل: ضمير رفع متحرك في محل رفع فاعل';
      } else {
        form = 'مبني على السكون';
        sign = 'السكون';
        subject = 'تاء التأنيث الساكنة: حرف مبني لا محل له من الإعراب';
      }
    } else if (clean.startsWith('ا') && !clean.startsWith('ال') && clean.length > 3) {
      tense = 'أمر';
      // تحقق من نوع البناء
      if (clean.endsWith('وا')) {
        form = 'مبني على حذف النون';
        sign = 'حذف النون';
        subject = 'واو الجماعة: فاعل مبني في محل رفع';
      } else if (clean.endsWith('ي') || clean.endsWith('ن')) {
        form = 'مبني على حذف النون';
        sign = 'حذف النون';
      } else {
        form = 'مبني على السكون';
        sign = 'السكون الظاهر على آخره';
      }
      note = 'فعل الأمر مبني دائماً ولا يدخله التغيير الإعرابي';
    } else {
      // ---- الفعل المضارع - تحليل دقيق بالحركات ----
      tense = 'مضارع';
      final lastChar = full.isNotEmpty ? full[full.length - 1] : '';
      final secondLast = full.length > 1 ? full[full.length - 2] : '';

      if (lastChar == '\u0646' && (secondLast == '\u064F' || secondLast == '\u064E')) {
        // ثبوت النون - الأفعال الخمسة
        form = 'مرفوع وعلامة رفعه ثبوت النون (من الأفعال الخمسة)';
        sign = 'ثبوت النون';
        note = 'الأفعال الخمسة: تُرفع بثبوت النون وتُنصب وتُجزم بحذفها';
      } else if (lastChar == '\u064F') {
        form = 'مرفوع وعلامة رفعه الضمة الظاهرة على آخره';
        sign = 'الضمة الظاهرة';
        note = 'الفعل المضارع مرفوع لتجرده من الناصب والجازم';
      } else if (lastChar == '\u064E') {
        form = 'منصوب وعلامة نصبه الفتحة الظاهرة';
        sign = 'الفتحة الظاهرة';
        note = 'يكون الفعل المضارع منصوباً بعد: أن، لن، كي، حتى، وغيرها';
      } else if (lastChar == '\u0652') {
        form = 'مجزوم وعلامة جزمه السكون';
        sign = 'السكون';
        note = 'يُجزم الفعل المضارع بعد أدوات الجزم: لم، لا الناهية، وجواب الطلب';
      } else if (clean.endsWith('ي') || clean.endsWith('ا') || clean.endsWith('و')) {
        form = 'مرفوع وعلامة رفعه الضمة المقدرة على حرف العلة';
        sign = 'الضمة المقدرة';
        note = 'تُقدَّر الحركة على حروف العلة للثقل';
      } else {
        form = 'مرفوع وعلامة رفعه الضمة الظاهرة أو المقدرة';
        sign = 'الضمة';
      }
    }

    return {
      'type': 'فعل',
      'category': 'فعل $tense',
      'irab': 'فعل $tense $form',
      'build': 'علامة إعرابه: $sign${subject.isNotEmpty ? " | $subject" : ""}',
      if (note.isNotEmpty) 'note': note,
    };
  }

  /// تحليل متقدم للأسماء - يأخذ في الاعتبار الجمع والتثنية وأنواع الاسم
  Map<String, String> _analyzeNoun(String clean, String full, int pos, int total) {
    // تحقق من علامات التعريف
    final isDefiniteAl = clean.startsWith('ال') || clean.startsWith('لل');

    // تحقق من التنوين والحركات
    final isTanwin = full.contains('\u064C') || full.contains('\u064B') || full.contains('\u064D');

    // تحقق من علامات الإعراب على الحرف الأخير (نتجاهل isProper مؤقتاً - قيمة مساعدة)
    final lastChar = full.isNotEmpty ? full[full.length - 1] : '';
    final secondLast = full.length > 1 ? full[full.length - 2] : '';

    final isMajroor = lastChar == '\u0650' ||
        (lastChar == '\u0646' && secondLast == '\u0650') || // كسرة + نون
        full.endsWith('\u064D'); // تنوين كسر

    final isMansub = lastChar == '\u064E' ||
        (lastChar == '\u0646' && secondLast == '\u064E') || // فتحة + نون
        full.endsWith('\u064B'); // تنوين فتح

    final isMarfu = lastChar == '\u064F' ||
        (lastChar == '\u0646' && secondLast == '\u064F') || // ضمة + نون
        full.endsWith('\u064C'); // تنوين ضم

    // تحقق من الجمع والتثنية
    final isDual = clean.endsWith('ان') || clean.endsWith('ين') && clean.length > 4;
    final isMascPlural = clean.endsWith('ون') || clean.endsWith('ين') && !isDual;
    final isFemsPlural = clean.endsWith('ات') && clean.length > 3;

    String position, sign, note = '', definiteness = '';

    // تحديد التعريف
    if (isDefiniteAl) {
      definiteness = 'معرفة بـ(ال) التعريف';
    } else if (isTanwin) {
      definiteness = 'نكرة منونة';
    } else {
      definiteness = 'اسم معرفة بالإضافة أو العلمية';
    }

    // تحديد الموضع الإعرابي
    if (isMajroor) {
      position = 'مجرور';
      if (isDual) {
        sign = 'الياء نيابةً عن الكسرة (مثنى)';
        note = 'المثنى: يُرفع بالألف ويُجر وينصب بالياء';
      } else if (isMascPlural) {
        sign = 'الياء نيابةً عن الكسرة (جمع مذكر سالم)';
        note = 'جمع المذكر السالم: يُرفع بالواو ويُجر وينصب بالياء';
      } else {
        sign = isDefiniteAl ? 'الكسرة الظاهرة على آخره' : (isTanwin ? 'الكسرة المنونة' : 'الكسرة');
      }
      note = note.isEmpty ? 'يأتي مجروراً بعد حرف الجر أو بالإضافة' : note;
    } else if (isMansub) {
      position = 'منصوب';
      if (isDual) {
        sign = 'الياء نيابةً عن الفتحة (مثنى)';
      } else if (isMascPlural) {
        sign = 'الياء نيابةً عن الفتحة (جمع مذكر سالم)';
      } else if (isFemsPlural) {
        sign = 'الكسرة نيابةً عن الفتحة (جمع مؤنث سالم)';
        note = 'جمع المؤنث السالم يُنصب بالكسرة نيابةً عن الفتحة';
      } else {
        sign = isDefiniteAl ? 'الفتحة الظاهرة على آخره' : (isTanwin ? 'الفتحة المنونة' : 'الفتحة');
      }
    } else if (isMarfu) {
      position = 'مرفوع';
      if (isDual) {
        sign = 'الألف نيابةً عن الضمة (مثنى)';
      } else if (isMascPlural) {
        sign = 'الواو نيابةً عن الضمة (جمع مذكر سالم)';
      } else {
        sign = isDefiniteAl ? 'الضمة الظاهرة على آخره' : (isTanwin ? 'الضمة المنونة' : 'الضمة');
      }
    } else if (pos == 0) {
      position = 'مرفوع (محتملاً مبتدأ أو فاعلاً)';
      sign = 'الضمة الظاهرة أو المقدرة';
      note = 'الاسم المبتدئ به الجملة يُرفع مبتدأً أو فاعلاً';
    } else if (clean.endsWith('ي') || clean.endsWith('ا') || clean.endsWith('و')) {
      position = 'يُحدَّد من السياق (حرف علة في آخره)';
      sign = 'الحركة مقدرة على حرف العلة';
      note = 'الاسم المقصور والممدود تُقدَّر فيهما الحركات';
    } else {
      position = 'يُحدَّد من السياق';
      sign = 'حسب موضعه في الجملة';
    }

    // تحقق من الممنوع من الصرف
    final noSarf = _isMamnuMinAlSarf(clean);
    if (noSarf) {
      definiteness += ' (ممنوع من الصرف)';
      note = note.isEmpty ? 'ممنوع من الصرف: يُجر بالفتحة بدل الكسرة' : '$note | ممنوع من الصرف';
    }

    return {
      'type': 'اسم',
      'category': 'اسم $definiteness',
      'irab': 'اسم $position، وعلامة إعرابه $sign',
      'build': 'معرب، علامة إعرابه $sign${isDual ? " (مثنى)" : isMascPlural ? " (جمع مذكر سالم)" : isFemsPlural ? " (جمع مؤنث سالم)" : ""}',
      if (note.isNotEmpty) 'note': note,
    };
  }

  /// تحقق من الممنوع من الصرف بناءً على الأوزان الشائعة
  bool _isMamnuMinAlSarf(String w) {
    if (w.startsWith('ال')) return false; // المعرف بأل ليس ممنوعاً
    // أسماء أعلام شائعة ممنوعة من الصرف
    const mamnuNames = ['إبراهيم', 'إسماعيل', 'إسحاق', 'يعقوب', 'يوسف', 'موسى', 'عيسى',
      'مريم', 'فرعون', 'هامان', 'قارون', 'لقمان', 'نوح', 'هود', 'صالح'];
    if (mamnuNames.contains(w)) return true;
    // التنوين غير موجود في الممنوع من الصرف عادةً
    return false;
  }

  void _shareIrab(int ayahNum) {
    final irabList = _irabCache[ayahNum] ?? [];
    final ayah = widget.ayahs.where((a) => a.numberInSurah == ayahNum).firstOrNull;
    final text = StringBuffer();
    text.writeln('📝 إعراب الآية $ayahNum من سورة ${widget.surah.nameArabic}');
    text.writeln();
    if (ayah != null) text.writeln('﴿ ${ayah.text} ﴾\n');
    for (final w in irabList) {
      text.writeln('${w.word}: ${w.irabText}');
    }
    text.writeln('\n— من تطبيق نور القرآن');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.ayahs.isEmpty) {
      return const Center(child: Text('لا توجد آيات'));
    }

    final currentAyah = widget.ayahs[_selectedAyahIndex.clamp(0, widget.ayahs.length - 1)];
    final irabList = _irabCache[currentAyah.numberInSurah] ?? [];

    return Column(
      children: [
        // ---- Ayah selector ----
        Container(
          height: 58,
          color: isDark ? const Color(0xFF1C2A36) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = widget.ayahs[index];
              final isSelected = index == _selectedAyahIndex;
              return GestureDetector(
                onTap: () => _loadIrab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                    ) : null,
                    color: isSelected ? null : (isDark ? const Color(0xFF2A3A46) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // ---- Header ----
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.withValues(alpha: 0.12), Colors.purple.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.text_fields, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الإعراب التفصيلي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                    Text('وفق المنهج الحديث المعاصر في النحو العربي',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              // Toggle view
              GestureDetector(
                onTap: () => setState(() => _showWordView = !_showWordView),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showWordView ? Icons.view_list : Icons.grid_view,
                          size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(_showWordView ? 'عرض بطاقي' : 'عرض قائمة',
                          style: const TextStyle(fontSize: 11, color: Colors.purple)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _shareIrab(currentAyah.numberInSurah),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, size: 14, color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
        // ---- Content ----
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.purple))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                  children: [
                    // Ayah text display
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.withValues(alpha: 0.06), Colors.purple.withValues(alpha: 0.02)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'الآية ${currentAyah.numberInSurah}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentAyah.text,
                            style: const TextStyle(fontSize: 22, height: 2.2, color: Color(0xFF6A1B9A)),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    // I'rab content
                    if (irabList.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('لم يتم تحميل الإعراب بعد', style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      _showWordView
                          ? _buildWordCards(irabList, theme, isDark)
                          : _buildListView(irabList, theme, isDark),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWordCards(List<_WordIrab> irabList, ThemeData theme, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: irabList.map((w) => _WordIrabCard(wordIrab: w, isDark: isDark)).toList(),
    );
  }

  Widget _buildListView(List<_WordIrab> irabList, ThemeData theme, bool isDark) {
    return Column(
      children: irabList.map((w) => _IrabListItem(wordIrab: w, isDark: isDark, theme: theme)).toList(),
    );
  }
}

class _WordIrab {
  final String word;
  final String clean;
  final String wordType;
  final String category;
  final String irab;
  final String buildNote;
  final String? note;

  String get irabText => irab;

  _WordIrab({
    required this.word,
    required this.clean,
    required this.wordType,
    required this.category,
    required this.irab,
    required this.buildNote,
    this.note,
  });

  factory _WordIrab.fromMap(String full, String clean, Map<String, String> map) {
    return _WordIrab(
      word: full,
      clean: clean,
      wordType: map['type'] ?? 'اسم',
      category: map['category'] ?? '',
      irab: map['irab'] ?? '',
      buildNote: map['build'] ?? '',
      note: map['note'],
    );
  }
}

class _WordIrabCard extends StatelessWidget {
  final _WordIrab wordIrab;
  final bool isDark;
  const _WordIrabCard({required this.wordIrab, required this.isDark});

  Color get _typeColor {
    switch (wordIrab.wordType) {
      case 'فعل': return const Color(0xFF1565C0);
      case 'حرف': return const Color(0xFF6A1B9A);
      case 'ضمير': return const Color(0xFF00695C);
      case 'ظرف': return const Color(0xFFE65100);
      case 'أداة': return const Color(0xFF558B2F);
      default: return const Color(0xFF37474F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2A36) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Word
          Text(
            wordIrab.word,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _typeColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              wordIrab.category,
              style: TextStyle(fontSize: 10, color: _typeColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          // I'rab
          Text(
            wordIrab.irab,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
            textDirection: TextDirection.rtl,
          ),
          if (wordIrab.note != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                wordIrab.note!,
                style: const TextStyle(fontSize: 10, color: Colors.orange),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IrabListItem extends StatelessWidget {
  final _WordIrab wordIrab;
  final bool isDark;
  final ThemeData theme;
  const _IrabListItem({required this.wordIrab, required this.isDark, required this.theme});

  Color get _typeColor {
    switch (wordIrab.wordType) {
      case 'فعل': return const Color(0xFF1565C0);
      case 'حرف': return const Color(0xFF6A1B9A);
      case 'ضمير': return const Color(0xFF00695C);
      case 'ظرف': return const Color(0xFFE65100);
      default: return const Color(0xFF37474F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2A36) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: _typeColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(wordIrab.category,
                          style: TextStyle(fontSize: 10, color: _typeColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  wordIrab.irab,
                  style: TextStyle(fontSize: 13, height: 1.7, color: theme.colorScheme.onSurface),
                  textDirection: TextDirection.rtl,
                ),
                if (wordIrab.buildNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(wordIrab.buildNote,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        textDirection: TextDirection.rtl),
                  ),
                if (wordIrab.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('💡 ${wordIrab.note}',
                        style: const TextStyle(fontSize: 11, color: Colors.orange),
                        textDirection: TextDirection.rtl),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            wordIrab.word,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _typeColor),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

/// =========== GHARIB TAB ===========
class _GharibTab extends StatefulWidget {
  final Surah surah;
  final List<Ayah> ayahs;
  const _GharibTab({required this.surah, required this.ayahs});

  @override
  State<_GharibTab> createState() => _GharibTabState();
}

class _GharibTabState extends State<_GharibTab> with AutomaticKeepAliveClientMixin {
  int _selectedAyahIndex = 0;

  @override
  bool get wantKeepAlive => true;

  static const Map<String, Map<String, String>> _gharibDictionary = {
    'ٱلۡحَمۡدُ': {'meaning': 'الثناء والشكر', 'root': 'ح م د', 'detail': 'الحمد: الثناء على الله بصفات الكمال وأفعال الجمال، يختلف عن الشكر إذ يكون على النعمة وغيرها'},
    'ٱلرَّحۡمَـٰنِ': {'meaning': 'ذو الرحمة الواسعة', 'root': 'ر ح م', 'detail': 'صفة مشبهة مبالغة تدل على سعة الرحمة، وهي رحمة الدنيا التي تعم المؤمن والكافر'},
    'ٱلرَّحِيمِ': {'meaning': 'ذو الرحمة الخاصة', 'root': 'ر ح م', 'detail': 'صفة مشبهة تدل على الرحمة الخاصة بالمؤمنين في الآخرة، وهي أخص من الرحمن'},
    'ٱلۡعَـٰلَمِينَ': {'meaning': 'جميع المخلوقات', 'root': 'ع ل م', 'detail': 'جمع عالَم بفتح اللام، وهو كل ما سوى الله: الإنس والجن والملائكة وسائر المخلوقات'},
    'مَـٰلِكِ': {'meaning': 'المتصرف المالك', 'root': 'م ل ك', 'detail': 'صاحب الملك والسلطان المطلق على الخلائق يوم القيامة، وقرئ (مَلِك) أي السلطان الحاكم'},
    'ٱلدِّينِ': {'meaning': 'يوم الجزاء والحساب', 'root': 'د ي ن', 'detail': 'الدين هنا بمعنى الجزاء والحساب والمحاسبة، يوم يدين الله فيه الخلق بأعمالهم'},
    'نَعۡبُدُ': {'meaning': 'نتذلل ونخضع', 'root': 'ع ب د', 'detail': 'العبادة: غاية التذلل لله مع غاية المحبة والتعظيم، وهي تشمل جميع ما يحبه الله ويرضاه'},
    'نَسۡتَعِينُ': {'meaning': 'نطلب العون', 'root': 'ع و ن', 'detail': 'الاستعانة: طلب المعونة من الله في جميع الأمور الدينية والدنيوية'},
    'ٱلصِّرَٰطَ': {'meaning': 'الطريق الواسع المستقيم', 'root': 'ص ر ط', 'detail': 'الصراط: الطريق الواضح الواسع، مستعار لدين الإسلام الذي لا عوج فيه'},
    'ٱلۡمُسۡتَقِيمَ': {'meaning': 'المعتدل الذي لا عوج فيه', 'root': 'ق و م', 'detail': 'اسم فاعل من استقام: الطريق القويم الذي لا انحراف فيه يمينًا ولا شمالًا'},
    'أَنۡعَمۡتَ': {'meaning': 'تفضلت بالنعمة والهداية', 'root': 'ن ع م', 'detail': 'الإنعام: إسباغ النعم والخيرات، والمنعم عليهم هم الأنبياء والصديقون والشهداء والصالحون'},
    'ٱلۡمَغۡضُوبِ': {'meaning': 'من نزل عليه الغضب الإلهي', 'root': 'غ ض ب', 'detail': 'المغضوب عليهم: الذين عرفوا الحق وتركوه عمدًا، وهم اليهود وأمثالهم'},
    'ٱلضَّآلِّينَ': {'meaning': 'الحائدين عن الحق', 'root': 'ض ل ل', 'detail': 'الضالون: الذين جهلوا الحق ولم يهتدوا إليه، وهم النصارى وأمثالهم'},
    'ذَٰلِكَ': {'meaning': 'اسم إشارة للبعيد التعظيم', 'root': 'ذ ل ك', 'detail': 'اسم إشارة للمفرد المذكر البعيد، استعمل للقريب للتعظيم وإعلاء شأن القرآن'},
    'ٱلۡكِتَٰبُ': {'meaning': 'القرآن الكريم', 'root': 'ك ت ب', 'detail': 'الكتاب: مصدر بمعنى المكتوب، سُمي القرآن كتابًا لكتابته في اللوح المحفوظ وصحائف الوحي'},
    'رَيۡبَ': {'meaning': 'شك مع قلق واضطراب', 'root': 'ر ي ب', 'detail': 'الريب: أخص من الشك، يتضمن الشك مع الاتهام والقلق، لا يجوز تقدير حرف الجر'},
    'ٱلۡمُتَّقِينَ': {'meaning': 'الذين اتقوا الله', 'root': 'و ق ي', 'detail': 'التقوى: جعل وقاية بين العبد وعذاب الله بفعل الطاعات واجتناب المحرمات'},
    'ٱلۡغَيۡبِ': {'meaning': 'ما غاب عن الحواس والإدراك', 'root': 'غ ي ب', 'detail': 'الغيب: كل ما غاب عن إدراك الإنسان مما أخبر الله به: الآخرة، القدر، الروح، وغيرها'},
    'يُنفِقُونَ': {'meaning': 'يبذلون أموالهم في وجوه الخير', 'root': 'ن ف ق', 'detail': 'الإنفاق: بذل المال والجهد في سبيل الله، يشمل الزكاة والصدقة والنفقة على العيال'},
    'أُنزِلَ': {'meaning': 'أُهبط ونُزِّل من العلو', 'root': 'ن ز ل', 'detail': 'الإنزال: إهباط الشيء من العلو، والقرآن نُزِّل منجمًا في ثلاث وعشرين سنة'},
    'يُوقِنُونَ': {'meaning': 'يعلمون علمًا جازمًا لا شك فيه', 'root': 'ي ق ن', 'detail': 'اليقين: العلم الجازم المطابق للواقع الذي لا يخالطه شك ولا ظن'},
    'هُدًى': {'meaning': 'دلالة وإرشاد وبيان', 'root': 'ه د ي', 'detail': 'الهدى: الدلالة الموصلة إلى الحق، وهو نوعان: هدى بيان وإرشاد، وهدى توفيق وتسديد'},
    'ٱلۡمُفۡلِحُونَ': {'meaning': 'الفائزون الناجون', 'root': 'ف ل ح', 'detail': 'الفلاح: حصول الخير والفوز، ومنه فلاح الأرض لأنه يشقها ليستخرج خيرها'},
    'كَفَرُواْ': {'meaning': 'جحدوا وستروا الحق', 'root': 'ك ف ر', 'detail': 'الكفر: الجحود والإنكار وستر الحق بعد وضوحه. الكافر: من يستر الحق كالزارع يستر الحبة'},
    'غِشَٰوَةٌ': {'meaning': 'غطاء وستار يحجب الإبصار', 'root': 'غ ش و', 'detail': 'الغشاوة: الغطاء المحيط بالشيء من جميع جوانبه، تصوير لحال الكافر المحجوب عن الهداية'},
    'خَٰلِدُونَ': {'meaning': 'مقيمون إلى الأبد', 'root': 'خ ل د', 'detail': 'الخلود: الإقامة الدائمة الأبدية التي لا انقطاع لها، من خَلَد: ثبت وأقام'},
    'يُخَٰدِعُونَ': {'meaning': 'يتظاهرون بالإيمان إيقاعًا', 'root': 'خ د ع', 'detail': 'المخادعة: المراوغة والتمويه، إظهار خلاف ما يُبطن، ولكن الله يعامل المنافق بمثل فعله'},
    'مَرَضٌ': {'meaning': 'علة وضعف في القلب', 'root': 'م ر ض', 'detail': 'المرض هنا مرض القلب: الشك والنفاق والرياء، وهو أشد خطرًا من مرض الجسد'},
    'يُفۡسِدُواْ': {'meaning': 'يُخربون ويُهلكون', 'root': 'ف س د', 'detail': 'الإفساد: إحداث الخلل والفساد في الأرض بالكفر والنفاق والمعاصي'},
    'سَفِيهٌ': {'meaning': 'ناقص العقل والرأي', 'root': 'س ف ه', 'detail': 'السفه: خفة العقل وضعف الرأي، ضد الحلم، وأصله من ثوب سفيه: رقيق النسيج'},
    'ٱسۡتَوَىٰ': {'meaning': 'علا وارتفع واستقر', 'root': 'س و ي', 'detail': 'الاستواء: العلو والارتفاع والاستقرار، استواء الله على العرش صفة ثابتة تليق بجلاله'},
    'خَلِيفَةً': {'meaning': 'من يخلف غيره ويقوم مقامه', 'root': 'خ ل ف', 'detail': 'الخليفة: من يخلف غيره، وخلافة الإنسان في الأرض: القيام بالعمارة والاستخلاف الإلهي'},
    'بَقَرَةً': {'meaning': 'أنثى البقر', 'root': 'ب ق ر', 'detail': 'البقرة: الأنثى من الثيران، سميت بذلك لأنها تبقر الأرض أي تشقها وتحرثها'},
    'صَلۡدًا': {'meaning': 'حجر أملس صلب لا تراب عليه', 'root': 'ص ل د', 'detail': 'الصَّلد: الحجر الأملس الصلب الذي لا تراب عليه ولا ينبت، وهو مثل للرياء'},
    'وَابِلٌ': {'meaning': 'مطر شديد غزير القطرات', 'root': 'و ب ل', 'detail': 'الوابل: المطر الشديد الغزير الكبير القطرات، ضد الطل، تمثيل للعمل الخالص المضاعف'},
    'طَلٌّ': {'meaning': 'ندى ومطر خفيف دقيق', 'root': 'ط ل ل', 'detail': 'الطل: الندى الخفيف الدقيق الذي لا يُرى وقوعه، تمثيل للعمل المقبول وإن قل'},
    'جَنَّةٌ': {'meaning': 'البستان كثير الأشجار', 'root': 'ج ن ن', 'detail': 'الجنة: البستان الكثير الأشجار المتكاثفة حتى تُجِنّ ما فيها. والجنة الآخروية: دار النعيم'},
    'رَبَّنَا': {'meaning': 'يا خالقنا وسيدنا', 'root': 'ر ب ب', 'detail': 'الرب: المالك المتصرف الموجد والمربي، ولا يُستعمل وصفًا لغير الله إلا بإضافة'},
    'تَوَفَّيۡتَنِي': {'meaning': 'قبضت روحي وأكملت أجلي', 'root': 'و ف ي', 'detail': 'التوفي: استيفاء الشيء وأخذه كاملًا، والموت استيفاء الله للأجل المحدد'},
    'ٱلظَّـٰلِمِينَ': {'meaning': 'الواضعين الشيء في غير موضعه', 'root': 'ظ ل م', 'detail': 'الظلم: وضع الشيء في غير موضعه، وأعظمه الشرك بالله لأنه وضع العبادة في غير موضعها'},
  };

  List<Map<String, String>> _findGharibWords(String ayahText) {
    final results = <Map<String, String>>[];
    final words = ayahText.split(RegExp(r'\s+'));

    for (final word in words) {
      if (_gharibDictionary.containsKey(word)) {
        if (!results.any((r) => r['word'] == word)) {
          results.add({'word': word, ..._gharibDictionary[word]!});
        }
        continue;
      }
      final stripped = _stripDiacritics(word);
      for (final entry in _gharibDictionary.entries) {
        final dictStripped = _stripDiacritics(entry.key);
        if (stripped == dictStripped || (stripped.length > 2 && dictStripped.contains(stripped))) {
          if (!results.any((r) => r['word'] == entry.key)) {
            results.add({'word': entry.key, 'original': word, ...entry.value});
          }
        }
      }
    }
    return results;
  }

  String _stripDiacritics(String w) {
    return w.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0600-\u0605\u06DD]'), '');
  }

  void _shareGharib(int ayahNum) {
    final ayah = widget.ayahs.where((a) => a.numberInSurah == ayahNum).firstOrNull;
    if (ayah == null) return;
    final words = _findGharibWords(ayah.text);
    final text = StringBuffer();
    text.writeln('📚 غريب القرآن - الآية $ayahNum من سورة ${widget.surah.nameArabic}');
    text.writeln();
    if (words.isEmpty) {
      text.writeln('لا توجد كلمات غريبة في هذه الآية');
    } else {
      for (final w in words) {
        text.writeln('• ${w['word']}: ${w['meaning']}');
        if (w['root'] != null) text.writeln('  الجذر: ${w['root']}');
      }
    }
    text.writeln('\n— من تطبيق نور القرآن');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.ayahs.isEmpty) return const Center(child: Text('لا توجد آيات'));

    final currentAyah = widget.ayahs[_selectedAyahIndex.clamp(0, widget.ayahs.length - 1)];
    final gharibWords = _findGharibWords(currentAyah.text);

    return Column(
      children: [
        // Ayah selector
        Container(
          height: 58,
          color: isDark ? const Color(0xFF1C2A36) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = widget.ayahs[index];
              final isSelected = index == _selectedAyahIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedAyahIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(
                      colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
                    ) : null,
                    color: isSelected ? null : (isDark ? const Color(0xFF2A3A46) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.deepOrange.withValues(alpha: 0.1),
              Colors.deepOrange.withValues(alpha: 0.03),
            ]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.deepOrange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('غريب القرآن الكريم',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                    Text('بيان معاني الكلمات الصعبة - مستوحى من مفردات الراغب',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _shareGharib(currentAyah.numberInSurah),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, size: 14, color: Colors.deepOrange),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            children: [
              // Ayah card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.deepOrange.withValues(alpha: 0.06),
                    Colors.deepOrange.withValues(alpha: 0.02),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFBF360C), Color(0xFFE64A19)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'الآية ${currentAyah.numberInSurah}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${gharibWords.length} كلمة',
                          style: TextStyle(fontSize: 12, color: gharibWords.isEmpty ? Colors.green : Colors.deepOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentAyah.text,
                      style: const TextStyle(fontSize: 22, height: 2.2, color: Color(0xFFBF360C)),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              // Gharib words
              if (gharibWords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2A36) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, size: 36, color: Colors.green),
                      ),
                      const SizedBox(height: 12),
                      const Text('لا توجد كلمات غريبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('جميع كلمات هذه الآية واضحة المعنى', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              else
                ...gharibWords.map((entry) => _buildGharibCard(entry, theme, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGharibCard(Map<String, String> entry, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2A36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFBF360C), Color(0xFFE64A19)]),
              borderRadius: BorderRadius.only(topRight: Radius.circular(16), topLeft: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry['word'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const Spacer(),
                if (entry['root'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('الجذر', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(
                        entry['root']!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Meaning & detail
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    const Text('المعنى:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry['meaning'] ?? '',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
                if (entry['detail'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      entry['detail']!,
                      style: TextStyle(fontSize: 13.5, height: 1.8, color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =========== AYAH NAVIGATOR TAB ===========
class _AyahNavigatorTab extends StatefulWidget {
  final Surah surah;
  final List<Ayah> ayahs;
  final VoidCallback onNavigateToTafsir;
  final VoidCallback onNavigateToIrab;

  const _AyahNavigatorTab({
    required this.surah,
    required this.ayahs,
    required this.onNavigateToTafsir,
    required this.onNavigateToIrab,
  });

  @override
  State<_AyahNavigatorTab> createState() => _AyahNavigatorTabState();
}

class _AyahNavigatorTabState extends State<_AyahNavigatorTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Ayah> _filtered = [];
  int? _selectedAyahNum;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _filtered = widget.ayahs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.ayahs;
      } else {
        _filtered = widget.ayahs.where((a) {
          return a.text.contains(query) || a.numberInSurah.toString() == query;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primary = Color(0xFF059669);

    return Column(
      children: [
        // Search bar
        Container(
          color: isDark ? const Color(0xFF1C2A36) : Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'جميع آيات سورة ${widget.surah.nameArabic}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filtered.length} آية',
                      style: const TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث في نص الآية أو رقمها...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: const Icon(Icons.search, color: primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchController.clear(); _onSearch(''); },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A3A46) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // Ayah list
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final ayah = _filtered[index];
                    final isSelected = _selectedAyahNum == ayah.numberInSurah;
                    return _buildAyahItem(ayah, theme, isDark, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAyahItem(Ayah ayah, ThemeData theme, bool isDark, bool isSelected) {
    const primary = Color(0xFF059669);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF052E16) : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF1C2A36) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primary : theme.colorScheme.outline.withValues(alpha: 0.08),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedAyahNum = isSelected ? null : ayah.numberInSurah),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primary, Color(0xFF047857)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (ayah.juz > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('جزء ${ayah.juz}', style: const TextStyle(fontSize: 10, color: Colors.teal)),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (ayah.page > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ص${ayah.page}', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                    ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    onSelected: (v) => _handleAction(v, ayah),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 16, color: primary), SizedBox(width: 8), Text('نسخ')])),
                      const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 16, color: Colors.teal), SizedBox(width: 8), Text('مشاركة')])),
                      const PopupMenuItem(value: 'tafsir', child: Row(children: [Icon(Icons.auto_stories, size: 16, color: Color(0xFF1B5E20)), SizedBox(width: 8), Text('التفسير')])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ayah.text,
                style: TextStyle(
                  fontSize: 19,
                  height: 2.1,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Divider(color: primary.withValues(alpha: 0.2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAction(Icons.auto_stories, 'التفسير', primary, widget.onNavigateToTafsir),
                    _buildAction(Icons.text_fields, 'الإعراب', Colors.purple, widget.onNavigateToIrab),
                    _buildAction(Icons.copy, 'نسخ', Colors.blue, () => _handleAction('copy', ayah)),
                    _buildAction(Icons.share, 'مشاركة', Colors.teal, () => _handleAction('share', ayah)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _handleAction(String action, Ayah ayah) {
    final surahName = widget.surah.nameArabic;
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: '${ayah.text}\n(سورة $surahName - الآية ${ayah.numberInSurah})'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم النسخ'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case 'share':
        SharePlus.instance.share(ShareParams(text: '${ayah.text}\n(سورة $surahName - الآية ${ayah.numberInSurah})\n\nمن تطبيق نور القرآن'));
        break;
      case 'tafsir':
        widget.onNavigateToTafsir();
        break;
    }
  }
}
