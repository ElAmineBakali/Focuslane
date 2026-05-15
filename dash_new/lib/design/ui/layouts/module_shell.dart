import 'package:flutter/material.dart';
import '../components/focus_header.dart';
import 'module_scaffold.dart';
import 'module_sidebar.dart';

class ModuleShell extends StatelessWidget {
  final List<ModuleSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBarOverride;
  final String moduleTitle;
  final IconData moduleIcon;

  const ModuleShell({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.appBarOverride,
    required this.moduleTitle,
    required this.moduleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final title = items[selectedIndex].label;
    final header =
        appBarOverride ??
        FocusHeader(title: title, subtitle: moduleTitle, actions: actions);

    return ModuleScaffold(
      child: Scaffold(
        key: scaffoldKey,
        drawer:
            !isDesktop
                ? Drawer(
                  child: ModuleSidebar(
                    items: items,
                    selectedIndex: selectedIndex,
                    onItemSelected: (index) {
                      onItemSelected(index);
                      Navigator.pop(context);
                    },
                    title: moduleTitle,
                    headerIcon: moduleIcon,
                  ),
                )
                : null,
        appBar:
            !isDesktop
                ? FocusHeader(
                  title: title,
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  actions: actions,
                  useSoftGradient: true,
                )
                : null,
        body: Row(
          children: [
            if (isDesktop)
              ModuleSidebar(
                items: items,
                selectedIndex: selectedIndex,
                onItemSelected: onItemSelected,
                title: moduleTitle,
                headerIcon: moduleIcon,
              ),
            Expanded(
              child: Column(
                children: [
                  if (isDesktop)
                    SizedBox(
                      height: header.preferredSize.height,
                      child: header,
                    ),
                  Expanded(
                    child: Padding(
                      padding:
                          isDesktop
                              ? const EdgeInsets.only(left: 0)
                              : EdgeInsets.zero,
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
