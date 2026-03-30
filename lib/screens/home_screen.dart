import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/reciter_selector.dart';
import '../widgets/search_filter.dart';
import '../widgets/surah_list.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/footer_widget.dart';

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
