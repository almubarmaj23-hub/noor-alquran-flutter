import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../services/bookmark_service.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showOverlay = false;


  int _bookmarkedPage = 0;

  // Cache for page data
  final Map<int, List<MushafAyah>> _pageCache = {};
  final Map<int, bool> _loadingPages = {};

  // Total pages in Quran
  static const int totalPages = 604;

  static const Color _gold = Color(0xFFD4A843);
  static const Color _darkBrown = Color(0xFF3E2723);
  static const Color _parchment = Color(0xFFFDF6E3);
  static const Color _darkParchment = Color(0xFF1A1209);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, totalPages);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadBookmark();
    _loadPageData(_currentPage);
    // Preload adjacent pages
    if (_currentPage > 1) _loadPageData(_currentPage - 1);
    if (_currentPage < totalPages) _loadPageData(_currentPage + 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final lastPage = await BookmarkService.getLastPage();
    if (mounted) setState(() => _bookmarkedPage = lastPage);
  }

  void _toggleBookmark() {
    setState(() => _bookmarkedPage = _currentPage);
    BookmarkService.saveLastPage(_currentPage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_added, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('تم حفظ العلامة عند الصفحة $_currentPage'),
          ],
        ),
        backgroundColor: const Color(0xFFD4A843),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadPageData(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber) || _loadingPages[pageNumber] == true) return;
    _loadingPages[pageNumber] = true;

    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/page/$pageNumber/quran-uthmani'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final ayahs = (data['data']['ayahs'] as List)
              .map((a) => MushafAyah.fromJson(a))
              .toList();
          if (mounted) {
            setState(() => _pageCache[pageNumber] = ayahs);
          }
        }
      }
    } catch (e) {
      // Fallback: try alternative
    }
    _loadingPages[pageNumber] = false;
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);
    // Auto-save bookmark
    BookmarkService.saveLastPage(page);
    _loadPageData(page);
    if (page > 1) _loadPageData(page - 1);
    if (page < totalPages) _loadPageData(page + 1);
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
  }

  void _goToPage(int page) {
    final target = page.clamp(1, totalPages);
    _pageController.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _darkParchment : _parchment;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Page viewer
            GestureDetector(
              onTap: _toggleOverlay,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  return _MushafPage(
                    pageNumber: pageNum,
                    ayahs: _pageCache[pageNum],
                    isLoading: _loadingPages[pageNum] == true && !(_pageCache.containsKey(pageNum)),
                    isDark: isDark,
                  );
                },
              ),
            ),
            // Top overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showOverlay ? 0 : -120,
              left: 0,
              right: 0,
              child: _buildTopBar(context, isDark),
            ),
            // Bottom overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showOverlay ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildBottomBar(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    final pageInfo = _getMushafPageInfo(_currentPage);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.black87, Colors.black54]
              : [_darkBrown, _darkBrown.withValues(alpha: 0.85)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'المصحف الشريف',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pageInfo['surah']} - الجزء ${pageInfo['juz']}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _currentPage == _bookmarkedPage ? Icons.bookmark : Icons.bookmark_border,
                  color: _gold,
                ),
                onPressed: _toggleBookmark,
                tooltip: 'حفظ علامة مرجعية',
              ),
              if (_bookmarkedPage > 0 && _bookmarkedPage != _currentPage)
                GestureDetector(
                  onTap: () => _goToPage(_bookmarkedPage),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark, color: _gold, size: 14),
                        const SizedBox(width: 2),
                        Text('ص$_bookmarkedPage', style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => _showSearch(context),
                tooltip: 'البحث في القرآن',
              ),
              IconButton(
                icon: const Icon(Icons.format_list_numbered, color: Colors.white),
                onPressed: () => _showGoToSurah(context),
                tooltip: 'الانتقال لسورة',
              ),
              IconButton(
                icon: const Icon(Icons.menu_book, color: Colors.white),
                onPressed: () => _showTableOfContents(context),
                tooltip: 'فهرس المصحف',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.black54, Colors.black87]
              : [_darkBrown.withValues(alpha: 0.85), _darkBrown],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before, color: Colors.white, size: 28),
                onPressed: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showGoToPage(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: _gold.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'صفحة $_currentPage من $totalPages',
                          style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: _gold,
                        activeTrackColor: _gold,
                        inactiveTrackColor: Colors.white30,
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _currentPage.toDouble(),
                        min: 1,
                        max: totalPages.toDouble(),
                        onChanged: (v) => _goToPage(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next, color: Colors.white, size: 28),
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getMushafPageInfo(int page) {
    final juz = _getJuzForPage(page);
    final surahEntry = _getSurahEntryForPage(page);
    return {
      'surah': surahEntry != null ? 'سورة ${surahEntry.name}' : 'القرآن الكريم',
      'juz': juz,
    };
  }

  int _getJuzForPage(int page) {
    // Accurate juz starts by page (Medina Mushaf)
    const juzPages = [
      1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582
    ];
    int juz = 1;
    for (int i = juzPages.length - 1; i >= 0; i--) {
      if (page >= juzPages[i]) {
        juz = i + 1;
        break;
      }
    }
    return juz.clamp(1, 30);
  }

  _SurahIndexEntry? _getSurahEntryForPage(int page) {
    _SurahIndexEntry? result;
    for (final entry in _mushafSurahIndex) {
      if (entry.startPage <= page) {
        result = entry;
      } else {
        break;
      }
    }
    return result;
  }

  void _showGoToPage(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الانتقال إلى صفحة', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل رقم الصفحة (1-$totalPages)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '$_currentPage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _gold, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
              onPressed: () {
                final page = int.tryParse(ctrl.text);
                if (page != null && page >= 1 && page <= totalPages) {
                  Navigator.pop(ctx);
                  _goToPage(page);
                }
              },
              child: const Text('انتقال'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchSheet(onNavigate: _goToPage),
    );
  }

  void _showTableOfContents(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TableOfContentsSheet(onNavigate: _goToPage),
    );
  }

  void _showGoToSurah(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoToSurahSheet(onNavigate: _goToPage),
    );
  }
}

// ========== MUSHAF PAGE ==========
class _MushafPage extends StatelessWidget {
  final int pageNumber;
  final List<MushafAyah>? ayahs;
  final bool isLoading;
  final bool isDark;

  const _MushafPage({
    required this.pageNumber,
    this.ayahs,
    this.isLoading = false,
    this.isDark = false,
  });

  static const Color _gold = Color(0xFFD4A843);
  static const Color _darkBrown = Color(0xFF3E2723);
  static const Color _parchment = Color(0xFFFDF6E3);
  static const Color _darkParchment = Color(0xFF1A1209);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? _darkParchment : _parchment;
    final textColor = isDark ? const Color(0xFFEDE0C8) : _darkBrown;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Page header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _gold.withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              children: [
                _buildPageInfo(_getSurahOnPage(), textColor),
                const Spacer(),
                _buildPageInfo('صفحة $pageNumber', textColor),
              ],
            ),
          ),
          // Page content
          Expanded(
            child: isLoading || ayahs == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _gold, strokeWidth: 2),
                        const SizedBox(height: 12),
                        Text('جاري تحميل الصفحة...', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13)),
                      ],
                    ),
                  )
                : _buildPageContent(context, textColor),
          ),
          // Page footer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _gold.withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '٭ $_pageNumber ٭',
                  style: TextStyle(color: _gold, fontSize: 14, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _pageNumber => _toArabicNumerals(pageNumber);

  String _toArabicNumerals(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? digits[d] : c;
    }).join();
  }

  String _getSurahOnPage() {
    if (ayahs != null && ayahs!.isNotEmpty) {
      return ayahs!.first.surahName;
    }
    return 'القرآن الكريم';
  }

  Widget _buildPageInfo(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPageContent(BuildContext context, Color textColor) {
    if (ayahs == null || ayahs!.isEmpty) {
      return Center(
        child: Text('لا توجد بيانات', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
      );
    }

    // Group ayahs by their position on page
    // Check if we need bismillah
    final firstAyah = ayahs!.first;
    final showBismillah = firstAyah.numberInSurah == 1 &&
        firstAyah.surahNumber != 1 &&
        firstAyah.surahNumber != 9;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBismillah) _buildBismillah(textColor),
          // Build surah headers within page
          _buildAyahsFlow(context, textColor),
        ],
      ),
    );
  }

  Widget _buildBismillah(Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _gold.withValues(alpha: 0.5)),
          bottom: BorderSide(color: _gold.withValues(alpha: 0.5)),
        ),
      ),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          height: 2,
          color: _gold,
          fontWeight: FontWeight.w500,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildAyahsFlow(BuildContext context, Color textColor) {
    // Group by surah to show surah headers
    final List<Widget> widgets = [];
    int? lastSurahNum;

    for (final ayah in ayahs!) {
      // Show surah header when surah changes
      if (lastSurahNum != ayah.surahNumber) {
        if (lastSurahNum != null) {
          // New surah starts - show header
          widgets.add(_buildSurahHeader(ayah.surahName, textColor));
          if (ayah.surahNumber != 9) {
            widgets.add(_buildBismillah(textColor));
          }
        }
        lastSurahNum = ayah.surahNumber;
      }
    }

    // Build continuous text flow
    widgets.add(_buildContinuousText(context, textColor));

    return Column(children: widgets);
  }

  Widget _buildSurahHeader(String surahName, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _gold.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(4),
        color: _gold.withValues(alpha: 0.08),
      ),
      child: Text(
        'سورة $surahName',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _gold,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildContinuousText(BuildContext context, Color textColor) {
    // Build inline text with ayah number markers
    final spans = <InlineSpan>[];

    for (final ayah in ayahs!) {
      // Ayah text
      spans.add(TextSpan(
        text: '${ayah.text} ',
        style: TextStyle(
          fontSize: 20,
          height: 2.5,
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
      ));
      // Ayah number circle
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _AyahNumberCircle(
          number: ayah.numberInSurah,
          surahName: ayah.surahName,
          ayahText: ayah.text,
          isDark: isDark,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}

// ========== AYAH NUMBER CIRCLE ==========
class _AyahNumberCircle extends StatelessWidget {
  final int number;
  final String surahName;
  final String ayahText;
  final bool isDark;

  const _AyahNumberCircle({
    required this.number,
    required this.surahName,
    required this.ayahText,
    this.isDark = false,
  });

  static const Color _gold = Color(0xFFD4A843);

  String _toArabicNumerals(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? digits[d] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAyahOptions(context),
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _gold, width: 1.5),
          color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.6),
        ),
        child: Center(
          child: Text(
            _toArabicNumerals(number),
            style: TextStyle(
              fontSize: 9,
              color: _gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showAyahOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ayah info header
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_gold, Color(0xFFE8B45A)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'سورة $surahName - الآية $number',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ayah text preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withValues(alpha: 0.2)),
                ),
                child: Text(
                  ayahText,
                  style: const TextStyle(fontSize: 18, height: 2),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy,
                      label: 'نسخ الآية',
                      color: const Color(0xFF059669),
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: '$ayahText\n(سورة $surahName - الآية $number)',
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تم نسخ الآية'),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share,
                      label: 'مشاركة',
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        Navigator.pop(ctx);
                        SharePlus.instance.share(ShareParams(
                          text: '$ayahText\n(سورة $surahName - الآية $number)\n\nمن مصحف نور القرآن',
                        ));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ========== SEARCH SHEET ==========
class _SearchSheet extends StatefulWidget {
  final Function(int) onNavigate;
  const _SearchSheet({required this.onNavigate});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  List<_SearchResult> _results = [];
  bool _isSearching = false;

  static const Color _gold = Color(0xFFD4A843);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/search/${Uri.encodeComponent(query)}/all/ar'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final matches = (data['data']['matches'] as List?) ?? [];
          final results = matches.take(20).map((m) => _SearchResult(
            text: m['text'] as String? ?? '',
            surahName: m['surah']?['name'] as String? ?? '',
            surahNumber: m['surah']?['number'] as int? ?? 0,
            ayahNumber: m['numberInSurah'] as int? ?? 0,
            page: m['page'] as int? ?? 1,
          )).toList();

          if (mounted) setState(() { _results = results; _isSearching = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2A36) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.search, color: _gold),
                  const SizedBox(width: 8),
                  Text('البحث في القرآن الكريم',
                      style: TextStyle(color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _controller,
                onChanged: (v) => _search(v),
                textDirection: TextDirection.rtl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث في آيات القرآن الكريم...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () { _controller.clear(); setState(() => _results = []); },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _gold, width: 1.5),
                  ),
                ),
              ),
            ),
            // Results
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 48, color: _gold.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _controller.text.isEmpty ? 'اكتب للبحث في القرآن الكريم' : 'لا توجد نتائج',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _buildResultCard(result, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(_SearchResult result, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onNavigate(result.page);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${result.surahName} - الآية ${result.ayahNumber}',
                    style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('ص${result.page}', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.text,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ========== TABLE OF CONTENTS ==========
class _TableOfContentsSheet extends StatefulWidget {
  final Function(int) onNavigate;
  const _TableOfContentsSheet({required this.onNavigate});

  @override
  State<_TableOfContentsSheet> createState() => _TableOfContentsSheetState();
}

class _TableOfContentsSheetState extends State<_TableOfContentsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _filter = '';

  static const Color _gold = Color(0xFFD4A843);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2A36) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.menu_book, color: _gold),
                  const SizedBox(width: 8),
                  Text('فهرس المصحف', style: TextStyle(color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: _gold,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [Tab(text: 'السور'), Tab(text: 'الأجزاء')],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _filter = v),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahList(isDark),
                  _buildJuzList(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahList(bool isDark) {
    final filtered = _mushafSurahIndex.where((s) =>
      s.name.contains(_filter) || s.nameEn.toLowerCase().contains(_filter.toLowerCase()) ||
      s.number.toString() == _filter
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final surah = filtered[index];
        return _buildSurahItem(surah, isDark);
      },
    );
  }

  Widget _buildSurahItem(_SurahIndexEntry surah, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onNavigate(surah.startPage);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.name, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
                  Text(surah.nameEn, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ص${surah.startPage}', style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 2),
                Text(surah.type, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuzList(bool isDark) {
    // Accurate juz start pages in the Medina Mushaf
    const juzStartPages = [
      1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
    ];
    const juzStartSurah = [
      'الفاتحة', 'البقرة', 'البقرة', 'آل عمران', 'النساء',
      'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
      'التوبة', 'هود', 'يوسف', 'إبراهيم', 'الإسراء',
      'الكهف', 'الأنبياء', 'المؤمنون', 'الفرقان', 'النمل',
      'العنكبوت', 'الأحزاب', 'يس', 'الزمر', 'فصلت',
      'الأحقاف', 'الذاريات', 'المجادلة', 'الملك', 'النبأ',
    ];
    final juzData = List.generate(30, (i) => _JuzEntry(
      number: i + 1,
      startPage: juzStartPages[i],
      startSurah: juzStartSurah[i],
    ));

    final filtered = juzData.where((j) =>
      j.number.toString().contains(_filter) ||
      'الجزء ${j.number}'.contains(_filter)
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final juz = filtered[index];
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            widget.onNavigate(juz.startPage);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFD4A843), Color(0xFFE8B45A)]),
                  ),
                  child: Center(
                    child: Text(
                      '${juz.number}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الجزء ${juz.number}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (juz.startSurah.isNotEmpty)
                        Text(
                          'يبدأ من سورة ${juz.startSurah}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD4A843), Color(0xFFE8B45A)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('ص${juz.startPage}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ========== GO TO SURAH SHEET ==========
class _GoToSurahSheet extends StatefulWidget {
  final Function(int) onNavigate;
  const _GoToSurahSheet({required this.onNavigate});

  @override
  State<_GoToSurahSheet> createState() => _GoToSurahSheetState();
}

class _GoToSurahSheetState extends State<_GoToSurahSheet> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  static const Color _gold = Color(0xFFD4A843);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _mushafSurahIndex.where((s) =>
      s.name.contains(_filter) ||
      s.nameEn.toLowerCase().contains(_filter.toLowerCase()) ||
      s.number.toString() == _filter
    ).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1209) : const Color(0xFFFDF6E3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.4), width: 2)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD4A843), Color(0xFFE8B45A)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.format_list_numbered, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الانتقال إلى سورة',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '١١٤ سورة في القرآن الكريم',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _filter = v),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم السورة أو رقمها...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: Icon(Icons.search, color: _gold.withValues(alpha: 0.7), size: 20),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.07) : _gold.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final surah = filtered[index];
                  return _buildSurahItem(surah, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahItem(_SurahIndexEntry surah, bool isDark) {
    final isMakki = surah.type == 'مكية';
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onNavigate(surah.startPage);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withValues(alpha: 0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              // Surah number in decorated circle
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isMakki
                        ? [const Color(0xFF6D4C41), const Color(0xFFD4A843)]
                        : [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
                  ),
                  boxShadow: [
                    BoxShadow(color: _gold.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Surah name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? const Color(0xFFEDE0C8) : const Color(0xFF3E2723),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          surah.nameEn,
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isMakki
                                ? const Color(0xFF6D4C41).withValues(alpha: 0.15)
                                : const Color(0xFF1B5E20).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            surah.type,
                            style: TextStyle(
                              color: isMakki ? const Color(0xFF6D4C41) : const Color(0xFF2E7D32),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Page badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFD4A843), Color(0xFFE8B45A)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ص${surah.startPage}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== DATA MODELS ==========
class MushafAyah {
  final int number;
  final String text;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final int juz;
  final int page;

  MushafAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.juz,
    required this.page,
  });

  factory MushafAyah.fromJson(Map<String, dynamic> json) {
    return MushafAyah(
      number: json['number'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      surahNumber: json['surah']?['number'] as int? ?? 0,
      surahName: json['surah']?['name'] as String? ?? 'القرآن',
      juz: json['juz'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
    );
  }
}

class _SearchResult {
  final String text;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final int page;

  _SearchResult({
    required this.text,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
  });
}

class _SurahIndexEntry {
  final int number;
  final String name;
  final String nameEn;
  final int startPage;
  final String type;

  const _SurahIndexEntry({
    required this.number,
    required this.name,
    required this.nameEn,
    required this.startPage,
    required this.type,
  });
}

class _JuzEntry {
  final int number;
  final int startPage;
  final String startSurah;
  _JuzEntry({required this.number, required this.startPage, this.startSurah = ''});
}

const List<_SurahIndexEntry> _mushafSurahIndex = [
  _SurahIndexEntry(number: 1, name: 'الفاتحة', nameEn: 'Al-Fatiha', startPage: 1, type: 'مكية'),
  _SurahIndexEntry(number: 2, name: 'البقرة', nameEn: 'Al-Baqarah', startPage: 2, type: 'مدنية'),
  _SurahIndexEntry(number: 3, name: 'آل عمران', nameEn: 'Al-Imran', startPage: 50, type: 'مدنية'),
  _SurahIndexEntry(number: 4, name: 'النساء', nameEn: 'An-Nisa', startPage: 77, type: 'مدنية'),
  _SurahIndexEntry(number: 5, name: 'المائدة', nameEn: 'Al-Maidah', startPage: 106, type: 'مدنية'),
  _SurahIndexEntry(number: 6, name: 'الأنعام', nameEn: 'Al-Anam', startPage: 128, type: 'مكية'),
  _SurahIndexEntry(number: 7, name: 'الأعراف', nameEn: 'Al-Araf', startPage: 151, type: 'مكية'),
  _SurahIndexEntry(number: 8, name: 'الأنفال', nameEn: 'Al-Anfal', startPage: 177, type: 'مدنية'),
  _SurahIndexEntry(number: 9, name: 'التوبة', nameEn: 'At-Tawbah', startPage: 187, type: 'مدنية'),
  _SurahIndexEntry(number: 10, name: 'يونس', nameEn: 'Yunus', startPage: 208, type: 'مكية'),
  _SurahIndexEntry(number: 11, name: 'هود', nameEn: 'Hud', startPage: 221, type: 'مكية'),
  _SurahIndexEntry(number: 12, name: 'يوسف', nameEn: 'Yusuf', startPage: 235, type: 'مكية'),
  _SurahIndexEntry(number: 13, name: 'الرعد', nameEn: 'Ar-Rad', startPage: 249, type: 'مدنية'),
  _SurahIndexEntry(number: 14, name: 'إبراهيم', nameEn: 'Ibrahim', startPage: 255, type: 'مكية'),
  _SurahIndexEntry(number: 15, name: 'الحجر', nameEn: 'Al-Hijr', startPage: 262, type: 'مكية'),
  _SurahIndexEntry(number: 16, name: 'النحل', nameEn: 'An-Nahl', startPage: 267, type: 'مكية'),
  _SurahIndexEntry(number: 17, name: 'الإسراء', nameEn: 'Al-Isra', startPage: 282, type: 'مكية'),
  _SurahIndexEntry(number: 18, name: 'الكهف', nameEn: 'Al-Kahf', startPage: 293, type: 'مكية'),
  _SurahIndexEntry(number: 19, name: 'مريم', nameEn: 'Maryam', startPage: 305, type: 'مكية'),
  _SurahIndexEntry(number: 20, name: 'طه', nameEn: 'Ta-Ha', startPage: 312, type: 'مكية'),
  _SurahIndexEntry(number: 21, name: 'الأنبياء', nameEn: 'Al-Anbiya', startPage: 322, type: 'مكية'),
  _SurahIndexEntry(number: 22, name: 'الحج', nameEn: 'Al-Hajj', startPage: 332, type: 'مدنية'),
  _SurahIndexEntry(number: 23, name: 'المؤمنون', nameEn: 'Al-Muminun', startPage: 342, type: 'مكية'),
  _SurahIndexEntry(number: 24, name: 'النور', nameEn: 'An-Nur', startPage: 350, type: 'مدنية'),
  _SurahIndexEntry(number: 25, name: 'الفرقان', nameEn: 'Al-Furqan', startPage: 359, type: 'مكية'),
  _SurahIndexEntry(number: 26, name: 'الشعراء', nameEn: 'Ash-Shuara', startPage: 367, type: 'مكية'),
  _SurahIndexEntry(number: 27, name: 'النمل', nameEn: 'An-Naml', startPage: 377, type: 'مكية'),
  _SurahIndexEntry(number: 28, name: 'القصص', nameEn: 'Al-Qasas', startPage: 385, type: 'مكية'),
  _SurahIndexEntry(number: 29, name: 'العنكبوت', nameEn: 'Al-Ankabut', startPage: 396, type: 'مكية'),
  _SurahIndexEntry(number: 30, name: 'الروم', nameEn: 'Ar-Rum', startPage: 404, type: 'مكية'),
  _SurahIndexEntry(number: 31, name: 'لقمان', nameEn: 'Luqman', startPage: 411, type: 'مكية'),
  _SurahIndexEntry(number: 32, name: 'السجدة', nameEn: 'As-Sajdah', startPage: 415, type: 'مكية'),
  _SurahIndexEntry(number: 33, name: 'الأحزاب', nameEn: 'Al-Ahzab', startPage: 418, type: 'مدنية'),
  _SurahIndexEntry(number: 34, name: 'سبأ', nameEn: 'Saba', startPage: 428, type: 'مكية'),
  _SurahIndexEntry(number: 35, name: 'فاطر', nameEn: 'Fatir', startPage: 434, type: 'مكية'),
  _SurahIndexEntry(number: 36, name: 'يس', nameEn: 'Ya-Sin', startPage: 440, type: 'مكية'),
  _SurahIndexEntry(number: 37, name: 'الصافات', nameEn: 'As-Saffat', startPage: 446, type: 'مكية'),
  _SurahIndexEntry(number: 38, name: 'ص', nameEn: 'Sad', startPage: 453, type: 'مكية'),
  _SurahIndexEntry(number: 39, name: 'الزمر', nameEn: 'Az-Zumar', startPage: 458, type: 'مكية'),
  _SurahIndexEntry(number: 40, name: 'غافر', nameEn: 'Ghafir', startPage: 467, type: 'مكية'),
  _SurahIndexEntry(number: 41, name: 'فصلت', nameEn: 'Fussilat', startPage: 477, type: 'مكية'),
  _SurahIndexEntry(number: 42, name: 'الشورى', nameEn: 'Ash-Shura', startPage: 483, type: 'مكية'),
  _SurahIndexEntry(number: 43, name: 'الزخرف', nameEn: 'Az-Zukhruf', startPage: 489, type: 'مكية'),
  _SurahIndexEntry(number: 44, name: 'الدخان', nameEn: 'Ad-Dukhan', startPage: 496, type: 'مكية'),
  _SurahIndexEntry(number: 45, name: 'الجاثية', nameEn: 'Al-Jathiyah', startPage: 499, type: 'مكية'),
  _SurahIndexEntry(number: 46, name: 'الأحقاف', nameEn: 'Al-Ahqaf', startPage: 502, type: 'مكية'),
  _SurahIndexEntry(number: 47, name: 'محمد', nameEn: 'Muhammad', startPage: 507, type: 'مدنية'),
  _SurahIndexEntry(number: 48, name: 'الفتح', nameEn: 'Al-Fath', startPage: 511, type: 'مدنية'),
  _SurahIndexEntry(number: 49, name: 'الحجرات', nameEn: 'Al-Hujurat', startPage: 515, type: 'مدنية'),
  _SurahIndexEntry(number: 50, name: 'ق', nameEn: 'Qaf', startPage: 518, type: 'مكية'),
  _SurahIndexEntry(number: 51, name: 'الذاريات', nameEn: 'Adh-Dhariyat', startPage: 520, type: 'مكية'),
  _SurahIndexEntry(number: 52, name: 'الطور', nameEn: 'At-Tur', startPage: 523, type: 'مكية'),
  _SurahIndexEntry(number: 53, name: 'النجم', nameEn: 'An-Najm', startPage: 526, type: 'مكية'),
  _SurahIndexEntry(number: 54, name: 'القمر', nameEn: 'Al-Qamar', startPage: 528, type: 'مكية'),
  _SurahIndexEntry(number: 55, name: 'الرحمن', nameEn: 'Ar-Rahman', startPage: 531, type: 'مدنية'),
  _SurahIndexEntry(number: 56, name: 'الواقعة', nameEn: 'Al-Waqiah', startPage: 534, type: 'مكية'),
  _SurahIndexEntry(number: 57, name: 'الحديد', nameEn: 'Al-Hadid', startPage: 537, type: 'مدنية'),
  _SurahIndexEntry(number: 58, name: 'المجادلة', nameEn: 'Al-Mujadila', startPage: 542, type: 'مدنية'),
  _SurahIndexEntry(number: 59, name: 'الحشر', nameEn: 'Al-Hashr', startPage: 545, type: 'مدنية'),
  _SurahIndexEntry(number: 60, name: 'الممتحنة', nameEn: 'Al-Mumtahanah', startPage: 549, type: 'مدنية'),
  _SurahIndexEntry(number: 61, name: 'الصف', nameEn: 'As-Saf', startPage: 551, type: 'مدنية'),
  _SurahIndexEntry(number: 62, name: 'الجمعة', nameEn: 'Al-Jumuah', startPage: 553, type: 'مدنية'),
  _SurahIndexEntry(number: 63, name: 'المنافقون', nameEn: 'Al-Munafiqun', startPage: 554, type: 'مدنية'),
  _SurahIndexEntry(number: 64, name: 'التغابن', nameEn: 'At-Taghabun', startPage: 556, type: 'مدنية'),
  _SurahIndexEntry(number: 65, name: 'الطلاق', nameEn: 'At-Talaq', startPage: 558, type: 'مدنية'),
  _SurahIndexEntry(number: 66, name: 'التحريم', nameEn: 'At-Tahrim', startPage: 560, type: 'مدنية'),
  _SurahIndexEntry(number: 67, name: 'الملك', nameEn: 'Al-Mulk', startPage: 562, type: 'مكية'),
  _SurahIndexEntry(number: 68, name: 'القلم', nameEn: 'Al-Qalam', startPage: 564, type: 'مكية'),
  _SurahIndexEntry(number: 69, name: 'الحاقة', nameEn: 'Al-Haqqah', startPage: 566, type: 'مكية'),
  _SurahIndexEntry(number: 70, name: 'المعارج', nameEn: 'Al-Maarij', startPage: 568, type: 'مكية'),
  _SurahIndexEntry(number: 71, name: 'نوح', nameEn: 'Nuh', startPage: 570, type: 'مكية'),
  _SurahIndexEntry(number: 72, name: 'الجن', nameEn: 'Al-Jinn', startPage: 572, type: 'مكية'),
  _SurahIndexEntry(number: 73, name: 'المزمل', nameEn: 'Al-Muzzammil', startPage: 574, type: 'مكية'),
  _SurahIndexEntry(number: 74, name: 'المدثر', nameEn: 'Al-Muddaththir', startPage: 575, type: 'مكية'),
  _SurahIndexEntry(number: 75, name: 'القيامة', nameEn: 'Al-Qiyamah', startPage: 577, type: 'مكية'),
  _SurahIndexEntry(number: 76, name: 'الإنسان', nameEn: 'Al-Insan', startPage: 578, type: 'مدنية'),
  _SurahIndexEntry(number: 77, name: 'المرسلات', nameEn: 'Al-Mursalat', startPage: 580, type: 'مكية'),
  _SurahIndexEntry(number: 78, name: 'النبأ', nameEn: 'An-Naba', startPage: 582, type: 'مكية'),
  _SurahIndexEntry(number: 79, name: 'النازعات', nameEn: 'An-Naziat', startPage: 583, type: 'مكية'),
  _SurahIndexEntry(number: 80, name: 'عبس', nameEn: 'Abasa', startPage: 585, type: 'مكية'),
  _SurahIndexEntry(number: 81, name: 'التكوير', nameEn: 'At-Takwir', startPage: 586, type: 'مكية'),
  _SurahIndexEntry(number: 82, name: 'الانفطار', nameEn: 'Al-Infitar', startPage: 587, type: 'مكية'),
  _SurahIndexEntry(number: 83, name: 'المطففين', nameEn: 'Al-Mutaffifin', startPage: 587, type: 'مكية'),
  _SurahIndexEntry(number: 84, name: 'الانشقاق', nameEn: 'Al-Inshiqaq', startPage: 589, type: 'مكية'),
  _SurahIndexEntry(number: 85, name: 'البروج', nameEn: 'Al-Buruj', startPage: 590, type: 'مكية'),
  _SurahIndexEntry(number: 86, name: 'الطارق', nameEn: 'At-Tariq', startPage: 591, type: 'مكية'),
  _SurahIndexEntry(number: 87, name: 'الأعلى', nameEn: 'Al-Ala', startPage: 591, type: 'مكية'),
  _SurahIndexEntry(number: 88, name: 'الغاشية', nameEn: 'Al-Ghashiyah', startPage: 592, type: 'مكية'),
  _SurahIndexEntry(number: 89, name: 'الفجر', nameEn: 'Al-Fajr', startPage: 593, type: 'مكية'),
  _SurahIndexEntry(number: 90, name: 'البلد', nameEn: 'Al-Balad', startPage: 594, type: 'مكية'),
  _SurahIndexEntry(number: 91, name: 'الشمس', nameEn: 'Ash-Shams', startPage: 595, type: 'مكية'),
  _SurahIndexEntry(number: 92, name: 'الليل', nameEn: 'Al-Lail', startPage: 595, type: 'مكية'),
  _SurahIndexEntry(number: 93, name: 'الضحى', nameEn: 'Ad-Duha', startPage: 596, type: 'مكية'),
  _SurahIndexEntry(number: 94, name: 'الشرح', nameEn: 'Ash-Sharh', startPage: 596, type: 'مكية'),
  _SurahIndexEntry(number: 95, name: 'التين', nameEn: 'At-Tin', startPage: 597, type: 'مكية'),
  _SurahIndexEntry(number: 96, name: 'العلق', nameEn: 'Al-Alaq', startPage: 597, type: 'مكية'),
  _SurahIndexEntry(number: 97, name: 'القدر', nameEn: 'Al-Qadr', startPage: 598, type: 'مكية'),
  _SurahIndexEntry(number: 98, name: 'البينة', nameEn: 'Al-Bayyinah', startPage: 598, type: 'مدنية'),
  _SurahIndexEntry(number: 99, name: 'الزلزلة', nameEn: 'Az-Zalzalah', startPage: 599, type: 'مدنية'),
  _SurahIndexEntry(number: 100, name: 'العاديات', nameEn: 'Al-Adiyat', startPage: 599, type: 'مكية'),
  _SurahIndexEntry(number: 101, name: 'القارعة', nameEn: 'Al-Qariah', startPage: 600, type: 'مكية'),
  _SurahIndexEntry(number: 102, name: 'التكاثر', nameEn: 'At-Takathur', startPage: 600, type: 'مكية'),
  _SurahIndexEntry(number: 103, name: 'العصر', nameEn: 'Al-Asr', startPage: 601, type: 'مكية'),
  _SurahIndexEntry(number: 104, name: 'الهمزة', nameEn: 'Al-Humazah', startPage: 601, type: 'مكية'),
  _SurahIndexEntry(number: 105, name: 'الفيل', nameEn: 'Al-Fil', startPage: 601, type: 'مكية'),
  _SurahIndexEntry(number: 106, name: 'قريش', nameEn: 'Quraish', startPage: 602, type: 'مكية'),
  _SurahIndexEntry(number: 107, name: 'الماعون', nameEn: 'Al-Maun', startPage: 602, type: 'مكية'),
  _SurahIndexEntry(number: 108, name: 'الكوثر', nameEn: 'Al-Kawthar', startPage: 602, type: 'مكية'),
  _SurahIndexEntry(number: 109, name: 'الكافرون', nameEn: 'Al-Kafirun', startPage: 603, type: 'مكية'),
  _SurahIndexEntry(number: 110, name: 'النصر', nameEn: 'An-Nasr', startPage: 603, type: 'مدنية'),
  _SurahIndexEntry(number: 111, name: 'المسد', nameEn: 'Al-Masad', startPage: 603, type: 'مكية'),
  _SurahIndexEntry(number: 112, name: 'الإخلاص', nameEn: 'Al-Ikhlas', startPage: 604, type: 'مكية'),
  _SurahIndexEntry(number: 113, name: 'الفلق', nameEn: 'Al-Falaq', startPage: 604, type: 'مكية'),
  _SurahIndexEntry(number: 114, name: 'الناس', nameEn: 'An-Nas', startPage: 604, type: 'مكية'),
];
