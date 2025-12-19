import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class FixedExpensesChecklistScreen extends StatefulWidget {
  const FixedExpensesChecklistScreen({super.key});
  static const route = '/finance/checklist/fixed';

  @override
  State<FixedExpensesChecklistScreen> createState() =>
      _FixedExpensesChecklistScreenState();
}

class _FixedExpensesChecklistScreenState
    extends State<FixedExpensesChecklistScreen> {
  String _pkNow() => FinanceFirestoreService.I.periodKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    FinanceFirestoreService.I.backfillSubscriptionsOrder();
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    final pk = _pkNow();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos fijos (checklist mensual)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: StreamBuilder<List<Subscription>>(
            stream: svc.watchSubscriptions(),
            builder: (context, s) {
              final items = s.data ?? [];
              if (items.isEmpty) return const SizedBox.shrink();

              return StreamBuilder<List<Map<String, bool>>>(
                stream: Stream.fromFuture(_getPaidStatusStream(svc, items, pk)),
                builder: (ctx, paidSnap) {
                  final paidList = paidSnap.data ?? [];
                  final paid =
                      paidList.isEmpty ? <String, bool>{} : paidList.first;
                  final total = items.fold<double>(
                    0,
                    (sum, sub) => sum + sub.amount,
                  );
                  final totalPaid = items
                      .where((sub) => paid[sub.id] == true)
                      .fold<double>(0, (sum, sub) => sum + sub.amount);
                  final pending = total - totalPaid;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          'Total: ${total.toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Pagado: ${totalPaid.toStringAsFixed(2)}€',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          'Pendiente: ${pending.toStringAsFixed(2)}€',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: svc.watchSubscriptions(),
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = s.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes gastos fijos. Pulsa + para crear uno.',
              ),
            );
          }

          return ReorderableListView.builder(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom + 110,
            ),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final mutable = List<Subscription>.from(items);
              final moved = mutable.removeAt(oldIndex);
              mutable.insert(newIndex, moved);

              final reordered = [
                for (var i = 0; i < mutable.length; i++)
                  Subscription(
                    id: mutable[i].id,
                    name: mutable[i].name,
                    amount: mutable[i].amount,
                    currency: mutable[i].currency,
                    category: mutable[i].category,
                    billingCycle: mutable[i].billingCycle,
                    billingDay: mutable[i].billingDay,
                    isFixed: mutable[i].isFixed,
                    remindDaysBefore: mutable[i].remindDaysBefore,
                    autoMarkPaid: mutable[i].autoMarkPaid,
                    order: i,
                  ),
              ];
              await svc.updateSubscriptionsOrder(reordered);
            },
            buildDefaultDragHandles: false,
            itemBuilder: (_, i) {
              final sub = items[i];

              return _SubscriptionRow(
                key: ValueKey('row-${sub.id}-$pk'),
                svc: svc,
                sub: sub,
                pk: pk,
                index: i,
                onEdit: () => _openSubForm(context, svc, editing: sub),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSubForm(context, svc),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<Map<String, bool>>> _getPaidStatusStream(
    FinanceFirestoreService svc,
    List<Subscription> items,
    String pk,
  ) async {
    final Map<String, bool> result = {};
    for (final sub in items) {
      result[sub.id] =
          await svc.watchSubscriptionPaidForMonth(sub.id, pk).first;
    }
    return [result];
  }

  void _openSubForm(
    BuildContext context,
    FinanceFirestoreService svc, {
    Subscription? editing,
  }) {
    final name = TextEditingController(text: editing?.name ?? '');
    final amount = TextEditingController(
      text: editing?.amount.toString() ?? '',
    );
    final currency = TextEditingController(text: editing?.currency ?? 'EUR');
    final category = TextEditingController(text: editing?.category ?? 'Other');
    final billingDay = TextEditingController(
      text: editing?.billingDay != null ? editing!.billingDay.toString() : '',
    );
    String cycle = editing?.billingCycle ?? 'monthly';
    final form = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      editing == null
                          ? 'Nueva suscripción'
                          : 'Editar suscripción',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amount,
                      decoration: const InputDecoration(labelText: 'Importe'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator:
                          (v) =>
                              v == null || double.tryParse(v) == null
                                  ? 'Inválido'
                                  : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: currency,
                      decoration: const InputDecoration(labelText: 'Divisa'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: cycle,
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Mensual'),
                        ),
                        DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                        DropdownMenuItem(value: 'custom', child: Text('Otro')),
                      ],
                      onChanged: (v) => cycle = v ?? 'monthly',
                      decoration: const InputDecoration(
                        labelText: 'Ciclo de facturación',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: billingDay,
                      decoration: const InputDecoration(
                        labelText: 'Día de cobro (opcional)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        final sub = Subscription(
                          id: editing?.id ?? '',
                          name: name.text.trim(),
                          amount: double.parse(amount.text),
                          currency:
                              currency.text.trim().isEmpty
                                  ? 'EUR'
                                  : currency.text.trim(),
                          category:
                              category.text.trim().isEmpty
                                  ? 'Other'
                                  : category.text.trim(),
                          billingCycle: cycle,
                          billingDay: int.tryParse(billingDay.text.trim()),
                          isFixed: true,
                        );
                        if (editing == null) {
                          await svc.addSubscription(sub);
                        } else {
                          await svc.updateSubscription(sub);
                        }
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _SubscriptionRow extends StatefulWidget {
  const _SubscriptionRow({
    super.key,
    required this.svc,
    required this.sub,
    required this.pk,
    required this.index,
    required this.onEdit,
  });

  final FinanceFirestoreService svc;
  final Subscription sub;
  final String pk;
  final int index;
  final VoidCallback onEdit;

  @override
  State<_SubscriptionRow> createState() => _SubscriptionRowState();
}

class _SubscriptionRowState extends State<_SubscriptionRow> {
  bool? _optimisticPaid; 

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      key: ValueKey('sb-${widget.sub.id}-${widget.pk}'),
      stream: widget.svc.watchSubscriptionPaidForMonth(
        widget.sub.id,
        widget.pk,
      ),
      builder: (context, paidSnap) {
        final paidFromStream = paidSnap.data ?? false;
        final paid = _optimisticPaid ?? paidFromStream;

        return ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: const Icon(Icons.drag_handle),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: paid,
                onChanged: (v) async {
                  setState(() => _optimisticPaid = v);
                  try {
                    if (v == true) {
                      await widget.svc.markSubscriptionPaidForMonth(
                        widget.sub,
                        DateTime.now(),
                      );
                    } else {
                      await widget.svc.unmarkSubscriptionPaidForMonth(
                        widget.sub,
                        DateTime.now(),
                      );
                    }
                  } catch (e) {
                    setState(
                      () => _optimisticPaid = null,
                    ); 
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ),
          title: Text(widget.sub.name),
          subtitle: Text(
            '${widget.sub.amount.toStringAsFixed(2)} ${widget.sub.currency} • ${widget.sub.category} '
            '${widget.sub.billingCycle}${widget.sub.billingDay != null ? " • día ${widget.sub.billingDay}" : ""}',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (op) async {
              if (op == 'edit') {
                widget.onEdit();
              } else if (op == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Eliminar'),
                        content: Text('¿Eliminar "${widget.sub.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                );
                if (ok == true)
                  await widget.svc.deleteSubscription(widget.sub.id);
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
          ),
        );
      },
    );
  }
}
