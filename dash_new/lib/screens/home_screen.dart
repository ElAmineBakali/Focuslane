import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_dashboard_personal/widgets/focuslane_title.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:mi_dashboard_personal/core/services/core_sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  final void Function(bool isDark) toggleTheme;
  final ThemeMode themeMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _Module {
  final String title;
  final String route;
  final IconData icon;
  final String image;
  const _Module(this.title, this.route, this.icon, this.image);
}

const List<_Module> _defaultModules = [
  _Module(
    'Calendario',
    '/calendar',
    Icons.calendar_month,
    'assets/home/calendario.jpg',
  ),
  _Module(
    'Tareas',
    '/tasks',
    Icons.check_circle_outlined,
    'assets/home/tareas.jpg',
  ),
  _Module('Notas', '/notes', Icons.notes_outlined, 'assets/home/notas.jpg'),
  _Module(
    'Hábitos',
    '/habits',
    Icons.checklist_outlined,
    'assets/home/habitos.jpg',
  ),
  _Module(
    'Estudio',
    AppRoutes.studyDashboard,
    Icons.school_outlined,
    'assets/home/estudio.jpg',
  ),
  _Module(
    'Gimnasio',
    AppRoutes.gymDashboard,
    Icons.fitness_center_outlined,
    'assets/home/gimnasio.jpg',
  ),
  _Module(
    'Meditación',
    '/meditation',
    Icons.self_improvement_outlined,
    'assets/home/meditacion.jpg',
  ),
  _Module(
    'Food',
    AppRoutes.foodDashboard,
    Icons.restaurant_outlined,
    'assets/home/alimentacion.jpg',
  ),
  _Module(
    'Finanzas',
    '/finance',
    Icons.account_balance_wallet_outlined,
    'assets/home/finanzas.jpg',
  ),
  _Module(
    'Trading',
    '/trading',
    Icons.candlestick_chart,
    'assets/home/trading.jpg',
  ),
  _Module(
    'Cultura',
    '/culture',
    Icons.smart_display,
    'assets/home/cultura.jpg',
  ),
  _Module('Hobbies', '/skills', Icons.interests, 'assets/home/hobbies.jpg'),
  _Module('Ropa', '/ropa', Icons.checkroom, 'assets/home/ropa.jpg'),
  _Module('Metas', '/goals', Icons.sports_score, 'assets/home/metas.jpg'),
];

class _ModulePrefs {
  static const _kOrder = 'home_modules_order';
  static const _kHidden = 'home_modules_hidden';

  static List<String> _routes() => _defaultModules.map((m) => m.route).toList();

  static Future<List<String>> loadOrder() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getStringList(_kOrder);
    final all = _routes();
    if (saved == null || saved.isEmpty) return all;
    final set = {...saved};
    for (final r in all) {
      if (!set.contains(r)) saved.add(r);
    }
    return saved;
  }

  static Future<Set<String>> loadHidden() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getStringList(_kHidden) ?? const <String>[]).toSet();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late List<_Module> _modules;
  Set<String> _hidden = {};
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) {
      for (final m in _modules.take(6)) {
        precacheImage(AssetImage(m.image), context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      CoreSyncService.I.start(uid);
    }
    _loadModules();
  }

  Future<void> _loadModules() async {
    final order = await _ModulePrefs.loadOrder();
    final hidden = await _ModulePrefs.loadHidden();
    final byRoute = {for (final m in _defaultModules) m.route: m};
    final ordered = <_Module>[
      for (final r in order)
        if (byRoute.containsKey(r)) byRoute[r]!,
    ];
    if (!mounted) return;
    setState(() {
      _hidden = hidden;
      _modules = ordered.where((m) => !_hidden.contains(m.route)).toList();
      _loading = false;
    });
  }

  Future<void> _openModulesEditor() async {
    await Navigator.of(context).pushNamed('/modules');
    await _loadModules();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkNow = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final m in _modules.take(6)) {
        precacheImage(AssetImage(m.image), context);
      }
    });

    return ScrollConfiguration(
      behavior: const _NoGlowNoScrollbarBehavior(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const FocusLaneTitle(fontSize: 20),
          actions: [
            IconButton(
              tooltip: isDarkNow ? 'Claro' : 'Oscuro',
              onPressed: () => widget.toggleTheme(!isDarkNow),
              icon: Icon(
                isDarkNow
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).pushNamed('/settings');
            await _loadModules();
          },
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Ajustes'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossAxisCount =
                width >= 1200 ? 4 : (width >= 900 ? 3 : 2);
            final double maxWidth = width >= 1200 ? 1200 : width;

            final bottomInset = MediaQuery.of(context).viewPadding.bottom;
            final bottomPadding = bottomInset + 96;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: GridView.builder(
                  cacheExtent: 1200,
                  padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _modules.length,
                  itemBuilder:
                      (context, i) => _ModuleCard(
                        module: _modules[i],
                        onLongPressEdit: _openModulesEditor,
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({required this.module, required this.onLongPressEdit});
  final _Module module;
  final VoidCallback onLongPressEdit;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return LayoutBuilder(
      builder: (ctx, cons) {
        final dpr = MediaQuery.of(ctx).devicePixelRatio;
        final targetW = (cons.maxWidth * dpr).clamp(320, 900).round();
        final provider = ResizeImage(
          AssetImage(widget.module.image),
          width: targetW,
        );

        return GestureDetector(
          onLongPress: widget.onLongPressEdit,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 110),
            scale: _pressed ? 0.985 : 1,
            child: Material(
              color: s.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap:
                    () => Navigator.of(context).pushNamed(widget.module.route),
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                splashColor: s.primary.withOpacity(0.10),
                highlightColor: Colors.transparent,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: provider,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(isDark ? .24 : .30),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                        child: Container(
                          height: isMobile ? 70 : 84,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: s.surface.withOpacity(isDark ? .40 : .55),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              border: Border.all(
                                color: s.outlineVariant.withOpacity(.35),
                              ),
                            ),
                            padding: EdgeInsets.all(isMobile ? 8 : 10),
                            child: Icon(
                              widget.module.icon,
                              color: s.onSurface,
                              size: isMobile ? 22 : 24,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.module.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: s.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.north_east,
                                size: 16,
                                color: s.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Entrar',
                                style: TextStyle(
                                  color: s.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoGlowNoScrollbarBehavior extends ScrollBehavior {
  const _NoGlowNoScrollbarBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext c,
    Widget child,
    ScrollableDetails d,
  ) => child;
  @override
  Widget buildScrollbar(BuildContext c, Widget child, ScrollableDetails d) =>
      child;
}
