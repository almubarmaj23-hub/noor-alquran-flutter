import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../data/reciters_data.dart';

class ReciterSelector extends StatelessWidget {
  const ReciterSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;
    final reciter = provider.currentReciter;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF0D9488).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'اختر القارئ' : 'Select Reciter',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${reciters.length} ${isAr ? 'قارئ متاح' : 'reciters available'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _showReciterDialog(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr ? reciter.nameArabic : reciter.nameEnglish,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.search, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.headphones,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'يتم الاستماع الآن بصوت' : 'Now listening to',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                      ),
                      Text(
                        reciter.nameArabic,
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReciterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _ReciterSheet(),
    );
  }
}

class _ReciterSheet extends StatefulWidget {
  const _ReciterSheet();

  @override
  State<_ReciterSheet> createState() => _ReciterSheetState();
}

class _ReciterSheetState extends State<_ReciterSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;
    final filtered = reciters.where((r) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return r.nameArabic.contains(_search) ||
          r.nameEnglish.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isAr ? 'اختر القارئ' : 'Select Reciter',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث باسم القارئ...' : 'Search reciter...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${filtered.length} ${isAr ? 'من' : 'of'} ${reciters.length} ${isAr ? 'قارئ' : 'reciters'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (_, i) {
                final r = filtered[i];
                final isSelected = provider.selectedReciterId == r.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF10B981), width: 2)
                        : null,
                  ),
                  child: ListTile(
                    onTap: () {
                      provider.setReciter(r.id);
                      Navigator.pop(context);
                    },
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.grey[300],
                      child: Icon(
                        isSelected ? Icons.check : Icons.person,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isAr ? r.nameArabic : r.nameEnglish,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(isAr ? r.nameEnglish : r.nameArabic),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
