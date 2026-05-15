import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/models/subscription_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/subscription_service.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key, required this.onBackToDashboard});

  final VoidCallback onBackToDashboard;

  static const route = '/finance/subscriptions';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Subscription>>(
      stream: SubscriptionService.I.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar las suscripciones',
              subtitle: '${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return _SubscriptionsContent(
          subscriptions: snapshot.data ?? const <Subscription>[],
        );
      },
    );
  }
}

class _SubscriptionsContent extends StatelessWidget {
  const _SubscriptionsContent({required this.subscriptions});

  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context) {
    final active = subscriptions.where((sub) => sub.isActive).length;
    final monthlyTotal = subscriptions
        .where((sub) => sub.isActive)
        .fold<double>(0, (sum, sub) => sum + sub.amount);

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suscripciones',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pagos recurrentes, recordatorios y estado activo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FocusBadge(
                            label: '$active activas',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          FocusBadge(
                            label: '${_currency(monthlyTotal)} estimado',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  );
                  final action = FocusPrimaryButton(
                    label: 'Nueva suscripción',
                    icon: Icons.add_rounded,
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          '/finance/subscriptions/form',
                        ),
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
            ),
            const SizedBox(height: 16),
            if (subscriptions.isEmpty)
              const FocusCard(
                child: FocusEmptyState(
                  icon: Icons.subscriptions_outlined,
                  message: 'Sin suscripciones',
                  subtitle:
                      'Registra pagos recurrentes para hacer seguimiento.',
                ),
              )
            else
              ResponsiveGrid(
                minItemWidth: 300,
                spacing: 16,
                children: [
                  for (final sub in subscriptions) _SubscriptionCard(sub: sub),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysLeft = sub.nextDue.difference(DateTime.now()).inDays;
    final tone = sub.isActive ? scheme.primary : scheme.outline;

    return FocusCard(
      onTap:
          () => Navigator.pushNamed(
            context,
            '/finance/subscriptions/form',
            arguments: sub,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconForCategory(sub.category),
                  color: tone,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sub.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusChip(
                label: labelForCategory(sub.category),
                icon: Icons.category_outlined,
                color: scheme.primary,
              ),
              FocusChip(
                label: _frequencyLabel(sub.frequency),
                icon: Icons.repeat_rounded,
                color: scheme.secondary,
              ),
              FocusChip(
                label: sub.isActive ? 'Activa' : 'Pausada',
                icon:
                    sub.isActive
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_outline_rounded,
                color: tone,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Próximo pago',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                DateFormat('d MMM yyyy', 'es_ES').format(sub.nextDue),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FocusBadge(
                  label: 'En $daysLeft d',
                  color: scheme.secondary,
                ),
              ),
              Text(
                _currency(sub.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _frequencyLabel(String value) {
  switch (value) {
    case 'daily':
      return 'Diaria';
    case 'weekly':
      return 'Semanal';
    case 'monthly':
      return 'Mensual';
    case 'yearly':
      return 'Anual';
    default:
      return 'Personalizada';
  }
}

String _currency(double value) => '${value.toStringAsFixed(2)} EUR';
