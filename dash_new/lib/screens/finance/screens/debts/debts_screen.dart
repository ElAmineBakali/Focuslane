import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/models/loan_model.dart';
import 'package:focuslane/screens/finance/services/debt_service_loans.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key, required this.onBackToDashboard});

  final VoidCallback onBackToDashboard;

  static const route = '/finance/debts';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Debt>>(
      stream: DebtService.I.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar las deudas',
              subtitle: '${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return _DebtsContent(debts: snapshot.data ?? const <Debt>[]);
      },
    );
  }
}

class _DebtsContent extends StatelessWidget {
  const _DebtsContent({required this.debts});

  final List<Debt> debts;

  @override
  Widget build(BuildContext context) {
    final balance = debts.fold<double>(0, (sum, debt) => sum + debt.balance);
    final original = debts.fold<double>(
      0,
      (sum, debt) => sum + debt.originalAmount,
    );
    final paid = (original - balance).clamp(0, double.infinity).toDouble();

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
                        'Deudas',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Importe pendiente, acreedor y progreso de pago.',
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
                            label: '${debts.length} deudas',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          FocusBadge(
                            label: 'Pendiente ${_currency(balance)}',
                            color: Theme.of(context).colorScheme.error,
                          ),
                          FocusBadge(
                            label: 'Pagado ${_currency(paid)}',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  );
                  final action = FocusPrimaryButton(
                    label: 'Nueva deuda',
                    icon: Icons.add_rounded,
                    onPressed:
                        () =>
                            Navigator.pushNamed(context, '/finance/debts/form'),
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
            if (debts.isEmpty)
              const FocusCard(
                child: FocusEmptyState(
                  icon: Icons.account_balance_outlined,
                  message: 'Sin deudas',
                  subtitle: 'Registra una deuda para controlar pagos.',
                ),
              )
            else
              Column(
                children: [
                  for (final debt in debts) ...[
                    _DebtCard(debt: debt),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress =
        debt.originalAmount <= 0
            ? 0.0
            : 1 - (debt.balance / debt.originalAmount);
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return FocusCard(
      onTap:
          () => Navigator.pushNamed(
            context,
            '/finance/debts/form',
            arguments: debt,
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
                  color: scheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.account_balance_rounded, color: scheme.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      debt.creditor,
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
                _currency(debt.balance),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FocusProgressBar(
            value: progress.clamp(0.0, 1.0),
            color: scheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% pagado de ${_currency(debt.originalAmount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _currency(double value) => '${value.toStringAsFixed(2)} EUR';
