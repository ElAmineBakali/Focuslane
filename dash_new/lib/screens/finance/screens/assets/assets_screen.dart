import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/models/asset_model.dart';
import 'package:focuslane/screens/finance/services/asset_service.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key, required this.onBackToDashboard});

  final VoidCallback onBackToDashboard;

  static const route = '/finance/assets';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Asset>>(
      stream: AssetService.I.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar los activos',
              subtitle: '${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return _AssetsContent(assets: snapshot.data ?? const <Asset>[]);
      },
    );
  }
}

class _AssetsContent extends StatelessWidget {
  const _AssetsContent({required this.assets});

  final List<Asset> assets;

  @override
  Widget build(BuildContext context) {
    final total = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: 'Activos',
              subtitle: 'Patrimonio registrado y valor actual.',
              badge: '${assets.length} activos',
              total: _currency(total),
              buttonLabel: 'Nuevo activo',
              buttonIcon: Icons.add_rounded,
              onPressed:
                  () => Navigator.pushNamed(context, '/finance/assets/form'),
            ),
            const SizedBox(height: 16),
            if (assets.isEmpty)
              const FocusCard(
                child: FocusEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  message: 'Sin activos',
                  subtitle: 'Registra propiedades, ahorros o inversiones.',
                ),
              )
            else
              ResponsiveGrid(
                minItemWidth: 300,
                spacing: 16,
                children: [
                  for (final asset in assets) _AssetCard(asset: asset),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      onTap:
          () => Navigator.pushNamed(
            context,
            '/finance/assets/form',
            arguments: asset,
          ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  asset.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _currency(asset.currentValue),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.total,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String total;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(label: badge, color: scheme.primary),
                  FocusBadge(label: total, color: scheme.secondary),
                ],
              ),
            ],
          );
          final action = FocusPrimaryButton(
            label: buttonLabel,
            icon: buttonIcon,
            onPressed: onPressed,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), action],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}

String _currency(double value) => '${value.toStringAsFixed(2)} EUR';
