import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget global para selección de enlaces externos
/// Muestra apps comunes con iconos grandes y visuales
class ExternalLinkPickerWidget extends StatelessWidget {
  final String? initialLink;
  final ValueChanged<String?> onLinkSelected;
  final String label;

  const ExternalLinkPickerWidget({
    super.key,
    this.initialLink,
    required this.onLinkSelected,
    this.label = 'Enlaces externos',
  });

  static final List<ExternalApp> _apps = [
    ExternalApp(
      name: 'Canvas',
      url: 'https://canvas.instructure.com',
      icon: Icons.school_rounded,
      color: const Color(0xFFE13827),
    ),
    ExternalApp(
      name: 'ChatGPT',
      url: 'https://chat.openai.com',
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFF10A37F),
    ),
    ExternalApp(
      name: 'Google Translate',
      url: 'https://translate.google.com',
      icon: Icons.translate_rounded,
      color: const Color(0xFF4285F4),
    ),
    ExternalApp(
      name: 'Google Drive',
      url: 'https://drive.google.com',
      icon: Icons.folder_rounded,
      color: const Color(0xFF34A853),
    ),
    ExternalApp(
      name: 'GitHub',
      url: 'https://github.com',
      icon: Icons.code_rounded,
      color: const Color(0xFF181717),
    ),
    ExternalApp(
      name: 'Notion',
      url: 'https://notion.so',
      icon: Icons.description_rounded,
      color: const Color(0xFF000000),
    ),
    ExternalApp(
      name: 'Google Docs',
      url: 'https://docs.google.com',
      icon: Icons.article_rounded,
      color: const Color(0xFF4285F4),
    ),
    ExternalApp(
      name: 'YouTube',
      url: 'https://youtube.com',
      icon: Icons.play_circle_filled_rounded,
      color: const Color(0xFFFF0000),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (initialLink != null && initialLink!.isNotEmpty)
              TextButton.icon(
                onPressed: () => onLinkSelected(null),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Quitar'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _apps.length,
          itemBuilder: (context, index) {
            final app = _apps[index];
            final isSelected = initialLink == app.url;

            return InkWell(
              onTap: () => onLinkSelected(app.url),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? app.color.withOpacity(0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: app.color, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      app.icon,
                      size: 32,
                      color: isSelected ? app.color : colorScheme.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? app.color : colorScheme.onSurface,
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
        
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'O pega un enlace personalizado',
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: initialLink != null && initialLink!.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.open_in_new_rounded),
                    onPressed: () async {
                      final uri = Uri.parse(initialLink!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  )
                : null,
          ),
          controller: TextEditingController(text: initialLink),
          onChanged: (value) {
            if (value.trim().isEmpty) {
              onLinkSelected(null);
            } else if (value.startsWith('http')) {
              onLinkSelected(value.trim());
            }
          },
        ),
      ],
    );
  }
}

class ExternalApp {
  final String name;
  final String url;
  final IconData icon;
  final Color color;

  const ExternalApp({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });
}
