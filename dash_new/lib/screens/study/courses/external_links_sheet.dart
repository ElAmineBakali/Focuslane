import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:focuslane/shared/app_links.dart';

class ExternalLinksSheet extends StatelessWidget {
  const ExternalLinksSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Enlaces externos',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Accede rápidamente a tus herramientas de estudio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _ExternalLinkTile(
                      icon: Icons.school_rounded,
                      title: 'Canvas',
                      subtitle: 'Plataforma educativa',
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      onTap: () {
                        AppLinks.openCanvas();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.psychology_rounded,
                      title: 'ChatGPT',
                      subtitle: 'Asistente de IA',
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade600],
                      ),
                      onTap: () {
                        AppLinks.openChatGPT();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 50.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.translate_rounded,
                      title: 'Google Translate',
                      subtitle: 'Traductor',
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      onTap: () {
                        AppLinks.openTranslate();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.video_library_rounded,
                      title: 'YouTube',
                      subtitle: 'Videos educativos',
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade800],
                      ),
                      onTap: () {
                        AppLinks.openYoutube();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 150.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.article_rounded,
                      title: 'Wikipedia',
                      subtitle: 'Enciclopedia libre',
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade700, Colors.grey.shade900],
                      ),
                      onTap: () {
                        AppLinks.openWikipedia();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.code_rounded,
                      title: 'GitHub',
                      subtitle: 'Repositorios de código',
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade700,
                        ],
                      ),
                      onTap: () {
                        AppLinks.openGithub();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 250.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.functions_rounded,
                      title: 'WolframAlpha',
                      subtitle: 'Motor de conocimiento',
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.deepOrange.shade600,
                        ],
                      ),
                      onTap: () {
                        AppLinks.openWolframAlpha();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                _ExternalLinkTile(
                      icon: Icons.library_books_rounded,
                      title: 'Google Scholar',
                      subtitle: 'Artículos académicos',
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade400,
                          Colors.indigo.shade700,
                        ],
                      ),
                      onTap: () {
                        AppLinks.openGoogleScholar();
                        Navigator.pop(context);
                      },
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 350.ms)
                    .slideX(begin: -0.2, end: 0),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ExternalLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                gradient.colors.first.withOpacity(0.1) == gradient.colors.first
                    ? null
                    : LinearGradient(
                      colors:
                          gradient.colors
                              .map((c) => c.withOpacity(0.1))
                              .toList(),
                    ),
            border: Border.all(
              color: gradient.colors.first.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: colorScheme.onPrimary, size: 26),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


