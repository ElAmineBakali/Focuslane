import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/screens/finance/models/budget_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/budget_service.dart';

import '../../widgets/finance_shell.dart';
import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/feedback/focus_feedback.dart';

class BudgetFormScreen extends StatefulWidget {
  const BudgetFormScreen({super.key, this.budget});
  static const route = '/finance/budgets/form';
  final Budget? budget;

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String? _category;
  late String _period;
  late DateTime _startDate;
  DateTime? _endDate;
  double _alertThreshold = 0.8;

  final _categories = [
    'alimentacion',
    'transporte',
    'hogar',
    'suscripciones',
    'salud',
    'ocio',
    'educacion',
    'trabajo',
    'ahorro',
    'otros',
  ];

  final _periods = {
    'weekly': 'Semanal',
    'monthly': 'Mensual',
    'quarterly': 'Trimestral',
    'yearly': 'Anual',
    'custom': 'Personalizado',
  };

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    if (b != null) {
      _nameCtrl.text = b.name;
      _limitCtrl.text = b.limit.toStringAsFixed(2);
      _category = b.category;
      _period = b.period.name;
      _startDate = b.startDate;
      _endDate = b.endDate;
      _alertThreshold = b.alertThreshold;
    } else {
      _period = 'monthly';
      _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.budget == null
      ? 'Nuevo presupuesto'
      : 'Editar presupuesto';

    return FinanceShell(
      selectedIndex: 2,
      title: 'Finanzas',
      subtitle: subtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        heroTag: null,
        icon: const Icon(Icons.check),
        label: const Text('Guardar'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 1024 ? 16.0 : 12.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  32,
                ),
                child: Form(
                  key: _formKey,
                  child: FocusCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildLimitField(),
                        const SizedBox(height: 16),
                        _buildCategoryField(),
                        const SizedBox(height: 16),
                        _buildPeriodField(),
                        const SizedBox(height: 16),
                        _buildDateFields(),
                        const SizedBox(height: 16),
                        _buildAlertThresholdField(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre del presupuesto *',
        hintText: 'Ej: Presupuesto mensual',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildLimitField() {
    return TextFormField(
      controller: _limitCtrl,
      decoration: InputDecoration(
        labelText: 'Limite de gasto *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.euro),
        suffixText: 'EUR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount <= 0) return 'Importe invalido';
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Categoria',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text('Sin categoria especifica'),
      items: _categories
          .map(
            (cat) => DropdownMenuItem(
              value: cat,
              child: Text(labelForCategory(cat)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _category = v),
    );
  }

  Widget _buildPeriodField() {
    return DropdownButtonFormField<String>(
      initialValue: _period,
      decoration: InputDecoration(
        labelText: 'Periodo *',
        prefixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _periods.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        setState(() {
          _period = v ?? 'monthly';
          if (_period == 'weekly') {
            _endDate = _startDate.add(const Duration(days: 7));
          } else if (_period == 'monthly') {
            _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
          } else if (_period == 'quarterly') {
            _endDate = DateTime(_startDate.year, _startDate.month + 3, 0);
          } else if (_period == 'yearly') {
            _endDate = DateTime(_startDate.year + 1, 1, 0);
          } else {
            _endDate = null;
          }
        });
      },
    );
  }

  Widget _buildDateFields() {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _startDate = picked;
                if (_period == 'weekly') {
                  _endDate = _startDate.add(const Duration(days: 7));
                } else if (_period == 'monthly') {
                  _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
                } else if (_period == 'quarterly') {
                  _endDate = DateTime(_startDate.year, _startDate.month + 3, 0);
                } else if (_period == 'yearly') {
                  _endDate = DateTime(_startDate.year + 1, 1, 0);
                }
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Fecha de inicio',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(DateFormat('d MMMM yyyy', 'es').format(_startDate)),
          ),
        ),
        if (_period == 'custom') ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                firstDate: _startDate,
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de fin',
                prefixIcon: const Icon(Icons.event),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _endDate != null
                    ? DateFormat('d MMMM yyyy', 'es').format(_endDate!)
                    : 'Selecciona una fecha',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertThresholdField() {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Umbral de alerta',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recibe una alerta cuando alcances este porcentaje del presupuesto',
          ),
          const SizedBox(height: 12),
          Slider(
            value: _alertThreshold,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            label: '${(_alertThreshold * 100).toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _alertThreshold = v),
          ),
          Center(
            child: Text('${(_alertThreshold * 100).toStringAsFixed(0)}%'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'El sistema calculara automaticamente el gasto en tiempo real.',
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_period == 'custom' && _endDate == null) {
      FocusFeedback.showInfo(context, 'Selecciona una fecha de fin');
      return;
    }

    final budget = Budget(
      id: widget.budget?.id ?? '',
      userId: widget.budget?.userId ?? '',
      name: _nameCtrl.text.trim(),
      amount: double.parse(_limitCtrl.text),
      limit: double.parse(_limitCtrl.text),
      category: _category ?? 'otros',
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == _period,
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: _startDate,
      endDate: _endDate,
      alertThreshold: _alertThreshold,
    );

    try {
      if (widget.budget == null) {
        await BudgetService.I.create(budget);
      } else {
        await BudgetService.I.update(budget);
      }
      if (mounted) {
        Navigator.pop(context, true);
        FocusFeedback.showSuccess(
          context,
          widget.budget == null
              ? 'Presupuesto creado'
              : 'Presupuesto actualizado',
        );
      }
    } catch (e) {
      if (mounted) {
        FocusFeedback.showError(context, 'Error: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }
}


