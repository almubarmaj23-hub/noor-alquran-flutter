import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../models/reciter.dart';
import '../data/surahs_data.dart';
import '../data/reciters_data.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Surah? _currentSurah;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isRepeat = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _selectedReciterId = 'minshawi';
  List<int> _favorites = [];
  bool _showFavorites = false;
  String _filter = 'all';
  String _searchQuery = '';
  bool _isArabic = true;
  bool _isDark = false;

  Surah? get currentSurah => _currentSurah;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isRepeat => _isRepeat;
  Duration get position => _position;
  Duration get duration => _duration;
  String get selectedReciterId => _selectedReciterId;
  List<int> get favorites => _favorites;
  bool get showFavorites => _showFavorites;
  String get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isArabic => _isArabic;
  bool get isDark => _isDark;

  Reciter get currentReciter =>
      reciters.firstWhere((r) => r.id == _selectedReciterId,
          orElse: () => reciters.first);

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  List<Surah> get filteredSurahs {
    var result = surahs.toList();
    if (_filter != 'all') {
      result = result.where((s) => s.type == _filter).toList();
    }
    if (_showFavorites) {
      result = result.where((s) => _favorites.contains(s.id)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) =>
          s.nameArabic.contains(_searchQuery) ||
          s.nameEnglish.toLowerCase().contains(q) ||
          s.id.toString() == _searchQuery).toList();
    }
    return result;
  }

  AudioProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = (prefs.getStringList('favorites') ?? [])
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    _selectedReciterId = prefs.getString('reciter') ?? 'minshawi';
    _isArabic = prefs.getBool('isArabic') ?? true;
    _isDark = prefs.getBool('isDark') ?? false;
    notifyListeners();

    _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          playNext();
        }
      }
      notifyListeners();
    });
  }

  Future<void> playSurah(Surah surah) async {
    if (_currentSurah?.id == surah.id) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }
    _currentSurah = surah;
    _isLoading = true;
    notifyListeners();
    try {
      final url = currentReciter.getAudioUrl(surah.id);
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void playNext() {
    if (_currentSurah == null) return;
    final idx = surahs.indexWhere((s) => s.id == _currentSurah!.id);
    final next = idx < surahs.length - 1 ? surahs[idx + 1] : surahs[0];
    playSurah(next);
  }

  void playPrevious() {
    if (_currentSurah == null) return;
    final idx = surahs.indexWhere((s) => s.id == _currentSurah!.id);
    final prev = idx > 0 ? surahs[idx - 1] : surahs[surahs.length - 1];
    playSurah(prev);
  }

  void seekTo(double value) {
    final ms = (value * _duration.inMilliseconds).toInt();
    _player.seek(Duration(milliseconds: ms));
  }

  void seekForward() {
    final newPos = _position + const Duration(seconds: 10);
    _player.seek(newPos > _duration ? _duration : newPos);
  }

  void seekBackward() {
    final newPos = _position - const Duration(seconds: 10);
    _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void playRandom() {
    final r = Random();
    playSurah(surahs[r.nextInt(surahs.length)]);
  }

  void closePlayer() {
    _player.stop();
    _currentSurah = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  Future<void> toggleFavorite(int surahId) async {
    if (_favorites.contains(surahId)) {
      _favorites.remove(surahId);
    } else {
      _favorites.add(surahId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites', _favorites.map((e) => e.toString()).toList());
  }

  void setShowFavorites(bool v) {
    _showFavorites = v;
    notifyListeners();
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> setReciter(String id) async {
    _selectedReciterId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reciter', id);
    if (_currentSurah != null) {
      _player.stop();
      final url = currentReciter.getAudioUrl(_currentSurah!.id);
      await _player.setUrl(url);
      await _player.play();
    }
  }

  Future<void> toggleLanguage() async {
    _isArabic = !_isArabic;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isArabic', _isArabic);
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', _isDark);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
