import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:focuslane/core/services/module_visibility_service.dart';
import 'package:focuslane/navigation/app_routes.dart';

import '../components/focus_icon_button.dart';
import '../components/focus_search_field.dart';
import '../tokens/focuslane_tokens.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.activeRoute,
    this.onNavigate,
    this.showSearch = false,
    this.searchHint = 'Buscar...',
    this.onSearchSubmitted,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String? activeRoute;
  final ValueChanged<String>? onNavigate;
  final bool showSearch;
  final String searchHint;
  final ValueChanged<String>? onSearchSubmitted;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    ModuleVisibilityService.instance.ensureLoaded();
  }

  Future<void> _navigate(String route) async {
    final current =
        widget.activeRoute ?? ModalRoute.of(context)?.settings.name ?? '';
    if (_isActive(current, route)) return;

    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
      return;
    }

    await Navigator.of(context).pushNamed(route);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final activeRoute =
        widget.activeRoute ?? ModalRoute.of(context)?.settings.name ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer:
          isDesktop
              ? null
              : Drawer(
                child: SafeArea(
                  child: FocusAppSidebar(
                    activeRoute: activeRoute,
                    onNavigate: (route) {
                      Navigator.of(context).pop();
                      _navigate(route);
                    },
                    onSignOut: _signOut,
                  ),
                ),
              ),
      body: Row(
        children: [
          if (isDesktop)
            FocusAppSidebar(
              activeRoute: activeRoute,
              onNavigate: _navigate,
              onSignOut: _signOut,
            ),
          Expanded(
            child: Column(
              children: [
                FocusTopBar(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  showMenu: !isDesktop,
                  showSearch: widget.showSearch,
                  searchHint: widget.searchHint,
                  actions: widget.actions,
                  onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onSearchSubmitted: widget.onSearchSubmitted,
                  onOpenNotifications: () => _navigate(AppRoutes.notifications),
                  onOpenSettings: () => _navigate(AppRoutes.settings),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class FocusTopBar extends StatelessWidget {
  const FocusTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showMenu = false,
    this.showSearch = false,
    this.searchHint = 'Buscar...',
    this.onOpenMenu,
    this.onSearchSubmitted,
    this.onOpenNotifications,
    this.onOpenSettings,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final bool showMenu;
  final bool showSearch;
  final String searchHint;
  final VoidCallback? onOpenMenu;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenSettings;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final label = _userInitial(user);

    return Container(
      height: FocuslaneTokens.topBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 720 ? 12 : 24,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        boxShadow: FocuslaneTokens.subtleShadow(context),
      ),
      child: Row(
        children: [
          if (showMenu) ...[
            FocusIconButton(
              icon: Icons.menu_rounded,
              tooltip: 'Abrir navegación',
              onPressed: onOpenMenu,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (showSearch && MediaQuery.sizeOf(context).width >= 760) ...[
            SizedBox(
              width: 320,
              height: 42,
              child: FocusSearchField(
                hintText: searchHint,
                onSubmitted: onSearchSubmitted,
              ),
            ),
            const SizedBox(width: 12),
          ],
          ...?actions,
          FocusIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notificaciones',
            badge: true,
            onPressed: onOpenNotifications,
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Ajustes',
            child: InkWell(
              onTap: onOpenSettings,
              borderRadius: BorderRadius.circular(999),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusAppSidebar extends StatelessWidget {
  const FocusAppSidebar({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    required this.onSignOut,
  });

  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  static const _items = <_AppNavItem>[
    _AppNavItem(
      'Inicio',
      Icons.home_outlined,
      Icons.home_rounded,
      AppRoutes.home,
    ),
    _AppNavItem(
      'Tareas',
      Icons.checklist_rounded,
      Icons.task_alt_rounded,
      AppRoutes.tasksDashboard,
    ),
    _AppNavItem(
      'Hábitos',
      Icons.repeat_rounded,
      Icons.repeat_rounded,
      AppRoutes.habitsDashboard,
    ),
    _AppNavItem(
      'Calendario',
      Icons.calendar_today_outlined,
      Icons.calendar_month_rounded,
      AppRoutes.calendarDashboard,
    ),
    _AppNavItem(
      'Notas',
      Icons.description_outlined,
      Icons.description_rounded,
      AppRoutes.notesDashboard,
    ),
    _AppNavItem(
      'Estudio',
      Icons.school_outlined,
      Icons.school_rounded,
      AppRoutes.studyDashboard,
    ),
    _AppNavItem(
      'Alimentación',
      Icons.restaurant_outlined,
      Icons.restaurant_rounded,
      AppRoutes.foodDashboard,
    ),
    _AppNavItem(
      'Finanzas',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      AppRoutes.financeDashboard,
    ),
    _AppNavItem(
      'Gimnasio',
      Icons.fitness_center_outlined,
      Icons.fitness_center_rounded,
      AppRoutes.gymDashboard,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: FocuslaneTokens.sidebarWidth,
      color: scheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: scheme.outlineVariant)),
          boxShadow: FocuslaneTokens.subtleShadow(context),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: FocuslaneTokens.subtleShadow(context),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: scheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FocusLane',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Productividad tranquila',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: ModuleVisibilityService.instance.hiddenRoutes,
                builder: (context, hidden, _) {
                  final items = _items
                      .where(
                        (item) =>
                            item.route == AppRoutes.home ||
                            !hidden.contains(item.route),
                      )
                      .toList(growable: false);
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final item in items)
                        _SidebarTile(
                          item: item,
                          selected: _isActive(activeRoute, item.route),
                          onTap: () => onNavigate(item.route),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  _SidebarTile(
                    item: const _AppNavItem(
                      'Notificaciones',
                      Icons.notifications_outlined,
                      Icons.notifications_rounded,
                      AppRoutes.notifications,
                    ),
                    selected: _isActive(activeRoute, AppRoutes.notifications),
                    onTap: () => onNavigate(AppRoutes.notifications),
                  ),
                  _SidebarTile(
                    item: const _AppNavItem(
                      'Ajustes',
                      Icons.settings_outlined,
                      Icons.settings_rounded,
                      AppRoutes.settings,
                    ),
                    selected: _isActive(activeRoute, AppRoutes.settings),
                    onTap: () => onNavigate(AppRoutes.settings),
                  ),
                  Divider(color: scheme.outlineVariant, height: 20),
                  _ProfileSummary(user: user),
                  const SizedBox(height: 8),
                  _SidebarTile(
                    item: const _AppNavItem(
                      'Cerrar sesión',
                      Icons.logout_rounded,
                      Icons.logout_rounded,
                      '',
                    ),
                    selected: false,
                    isDestructive: true,
                    onTap: onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
  });

  final _AppNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg =
        isDestructive
            ? scheme.error
            : selected
            ? scheme.primary
            : scheme.onSurfaceVariant;
    final bg =
        selected ? scheme.secondaryContainer.withValues(alpha: 0.42) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bg ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: fg,
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileRef =
        user == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .collection('profile')
                .doc('info');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileRef?.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final displayName =
            ((data['displayName'] as String?) ??
                    user?.displayName ??
                    user?.email ??
                    'FocusLane')
                .trim();
        final photoUrl =
            ((data['photoUrl'] as String?) ?? user?.photoURL ?? '').trim();

        return Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
              child:
                  photoUrl.isEmpty
                      ? Text(
                        _initialFrom(displayName),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      )
                      : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.isEmpty ? 'FocusLane' : displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    user?.email ?? 'Sesión activa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppNavItem {
  const _AppNavItem(this.label, this.icon, this.activeIcon, this.route);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}

bool _isActive(String current, String route) {
  if (route == AppRoutes.home) {
    return current == route || current.isEmpty;
  }
  return current == route || current.startsWith('$route/');
}

String _userInitial(User? user) {
  final source =
      user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : (user?.email ?? 'F');
  return _initialFrom(source);
}

String _initialFrom(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'F';
  return trimmed.substring(0, 1).toUpperCase();
}
