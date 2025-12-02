import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/finance_models.dart';
import 'package:mi_dashboard_personal/screens/finance/services/finance_firestore_service.dart';
import '../../../utils/app_links.dart';
import '../../../widgets/ui_scaffold.dart';
import 'asset_edit_sheet.dart';

class AssetsListScreen extends StatelessWidget {
  const AssetsListScreen({super.key});
  static const route = '/finance/assets';

  IconData _icon(AssetKind k) {
    switch (k) {
      case AssetKind.house:
        return Icons.house_rounded;
      case AssetKind.car:
        return Icons.directions_car_rounded;
      case AssetKind.land:
        return Icons.terrain_rounded;
      case AssetKind.other:
        return Icons.inventory_2_rounded;
    }
  }

  String _kindLabel(AssetKind k) {
    switch (k) {
      case AssetKind.house:
        return 'Vivienda';
      case AssetKind.car:
        return 'Vehículo';
      case AssetKind.land:
        return 'Terreno';
      case AssetKind.other:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceAssetsFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrimonio'),
        actions: [
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Atajos',
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'tr') AppLinks.openTradeRepublic();
              if (v == 'imagin') AppLinks.openImagin();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'tr', child: Text('Abrir Trade Republic')),
              PopupMenuItem(value: 'imagin', child: Text('Abrir imagin')),
            ],
          ),
          IconButton(
            tooltip: 'Añadir activo',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const AssetEditSheet(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AssetItem>>(
        stream: svc.watchAssets(),
        builder: (ctx, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) {
            return const Center(child: Text('Añade tu primer activo con el botón +'));
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            itemCount: data.length,
            separatorBuilder: (ctx, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final x = data[i];
              final color = Theme.of(ctx).colorScheme.primary;
              return Card(
                child: ListTile(
                  leading: Icon(_icon(x.kind), color: color),
                  title: Text(x.name),
                  subtitle: Text([
                    _kindLabel(x.kind),
                    if (x.estValue != null)
                      '${x.estValue!.toStringAsFixed(0)} ${x.currency ?? ''}'.trim(),
                    if ((x.address ?? '').isNotEmpty) x.address!,
                  ].join(' • ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((x.address ?? '').isNotEmpty)
                        IconButton(
                          tooltip: 'Abrir en mapas',
                          icon: const Icon(Icons.location_on_outlined),
                          onPressed: () => AppLinks.openMapQuery(x.address!),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await showModalBottomSheet(
                              context: ctx,
                              isScrollControlled: true,
                              builder: (_) => AssetEditSheet(initial: x),
                            );
                          } else if (v == 'del') {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                title: const Text('Eliminar activo'),
                                content: Text('¿Eliminar "${x.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await FinanceAssetsFirestoreService.I.deleteAsset(x.id);
                            }
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'del', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
