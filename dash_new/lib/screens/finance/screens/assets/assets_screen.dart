import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/asset_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/asset_service.dart';

import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/components/focus_module_header.dart';
import '../../../../design/ui/tokens/focuslane_tokens.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/assets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Activos',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo activo',
            onPressed: () => Navigator.pushNamed(context, '/finance/assets/form'),
          ),
        ],
      ),
      body: Padding(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          children: [
            Expanded(
              child: FocusCard(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<List<Asset>>(
                  stream: AssetService.I.watchAll(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final assets = snap.data ?? const [];
                    if (assets.isEmpty) {
                      return const Center(child: Text('Sin activos'));
                    }
                    return ListView.separated(
                      itemCount: assets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = assets[i];
                        return ListTile(
                          title: Text(a.name),
                          subtitle: Text(a.type),
                          trailing: Text(
                            '${a.currentValue.toStringAsFixed(2)}â‚¬',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/finance/assets/form',
                            arguments: a,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




