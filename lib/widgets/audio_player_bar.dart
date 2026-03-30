import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioPlayerBar extends StatelessWidget {
  const AudioPlayerBar({super.key});

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final surah = provider.currentSurah;
    if (surah == null) return const SizedBox.shrink();

    final isAr = provider.isArabic;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox;
              final width = box.size.width;
              final dx = details.localPosition.dx;
              provider.seekTo(dx / width);
            },
            child: Container(
              height: 4,
              color: theme.colorScheme.surfaceContainerHighest,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: provider.progress.clamp(0.0, 1.0),
                child: Container(
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Row 1: Info
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAr ? surah.nameArabic : surah.nameEnglish,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_formatTime(provider.position)} / ${_formatTime(provider.duration)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Row 2: Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rewind
                    _CtrlBtn(
                      icon: Icons.replay_10,
                      onTap: provider.seekBackward,
                    ),
                    // Previous
                    _CtrlBtn(
                      icon: Icons.skip_previous,
                      onTap: isAr ? provider.playNext : provider.playPrevious,
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: provider.togglePlay,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                        child: provider.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(
                                provider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                    // Next
                    _CtrlBtn(
                      icon: Icons.skip_next,
                      onTap: isAr ? provider.playPrevious : provider.playNext,
                    ),
                    // Forward
                    _CtrlBtn(
                      icon: Icons.forward_10,
                      onTap: provider.seekForward,
                    ),
                    const SizedBox(width: 8),
                    // Repeat
                    _CtrlBtn(
                      icon: Icons.repeat,
                      onTap: provider.toggleRepeat,
                      active: provider.isRepeat,
                    ),
                    // Random
                    _CtrlBtn(
                      icon: Icons.shuffle,
                      onTap: provider.playRandom,
                    ),
                    // Close
                    _CtrlBtn(
                      icon: Icons.close,
                      onTap: provider.closePlayer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _CtrlBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(
          icon,
          size: 22,
          color: active
              ? const Color(0xFF10B981)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
