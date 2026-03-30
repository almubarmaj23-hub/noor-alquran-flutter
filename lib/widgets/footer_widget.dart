import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/audio_provider.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isAr = provider.isArabic;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // App Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                child: const Center(
                  child: Text(
                    'نور',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'نور القرآن' : 'Noor Al-Quran',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Noor Al-Quran',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'استمع إلى تلاوات عطرة من كتاب الله'
                : 'Listen to beautiful recitations from the Book of Allah',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'تطوير داوود الاحمدي' : 'Developed by Dawood Al-Ahmadi',
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'للتواصل مع المطور عبر الإيميل'
                : 'Contact the developer via email',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'almubarmaj8@gmail.com',
                queryParameters: {
                  'subject': isAr
                      ? 'تواصل من تطبيق القرآن الكريم'
                      : 'Contact from Quran App',
                },
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.email, size: 16),
            label: const Text('almubarmaj8@gmail.com',
                style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 16),
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${isAr ? 'جميع التلاوات من موقع' : 'All recitations from'} Mp3Quran',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 4),
          Text(
            '\u00A9 ${DateTime.now().year} ${isAr ? 'نور القرآن' : 'Noor Al-Quran'} • ${isAr ? 'جميع الحقوق محفوظة' : 'All rights reserved'}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
