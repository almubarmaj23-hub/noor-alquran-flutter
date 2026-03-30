import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class SearchFilterWidget extends StatelessWidget {
  const SearchFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: isAr
                  ? 'ابحث باسم السورة أو رقمها...'
                  : 'Search by surah name or number...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => provider.setSearchQuery(v),
          ),
          const SizedBox(height: 12),
          // Filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _FilterChip(
                label: isAr ? 'الكل' : 'All',
                selected: provider.filter == 'all',
                onTap: () => provider.setFilter('all'),
              ),
              _FilterChip(
                label: isAr ? 'مكية' : 'Makki',
                selected: provider.filter == 'مكية',
                onTap: () => provider.setFilter('مكية'),
              ),
              _FilterChip(
                label: isAr ? 'مدنية' : 'Madani',
                selected: provider.filter == 'مدنية',
                onTap: () => provider.setFilter('مدنية'),
              ),
              _FilterChip(
                label: isAr ? 'المفضلة' : 'Favorites',
                selected: provider.showFavorites,
                onTap: () =>
                    provider.setShowFavorites(!provider.showFavorites),
                icon: Icons.star,
                activeColor: Colors.amber,
                badgeCount: provider.favorites.length,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                '${isAr ? 'عرض' : 'Displaying'} ${provider.filteredSurahs.length} ${isAr ? 'سورة' : 'surah'}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? activeColor;
  final int? badgeCount;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.activeColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? const Color(0xFF059669);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
