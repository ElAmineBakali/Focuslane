import 'package:flutter/material.dart';
import 'package:focuslane/core/services/module_visibility_service.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final ModuleVisibilityService _visibility = ModuleVisibilityService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _visibility.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _toggleModule(String route, bool enabled) async {
    await _visibility.setEnabled(route, enabled);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Módulos')),
      body: Padding(
        padding: FocuslaneTokens.pagePaddingFor(context),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  children: [
                    Container(
                      padding: FocuslaneTokens.cardPaddingFor(context),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: colorScheme.surface,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activa solo lo que quieras ver',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Los módulos desactivados desaparecen de la navegación principal y no molestan en el flujo normal. Los cambios se guardan al instante.',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: FocuslaneTokens.pageGapFor(context)),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: colorScheme.surface,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: _visibility.hiddenRoutes,
                        builder: (context, hiddenRoutes, _) {
                          return Column(
                            children: [
                              for (
                                var i = 0;
                                i < ModuleVisibilityService.modules.length;
                                i++
                              ) ...[
                                _ModuleTile(
                                  definition:
                                      ModuleVisibilityService.modules[i],
                                  enabled:
                                      !hiddenRoutes.contains(
                                        ModuleVisibilityService
                                            .modules[i]
                                            .route,
                                      ),
                                  onChanged:
                                      (enabled) => _toggleModule(
                                        ModuleVisibilityService
                                            .modules[i]
                                            .route,
                                        enabled,
                                      ),
                                ),
                                if (i !=
                                    ModuleVisibilityService.modules.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 20,
                                    endIndent: 20,
                                    color: colorScheme.outlineVariant,
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.definition,
    required this.enabled,
    required this.onChanged,
  });

  final ModuleVisibilityDefinition definition;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = FocuslaneTokens.isCompact(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 46,
            height: compact ? 38 : 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color:
                  enabled
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              definition.icon,
              color:
                  enabled
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  definition.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'Activo en la navegación'
                      : 'Oculto en la navegación',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        enabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
