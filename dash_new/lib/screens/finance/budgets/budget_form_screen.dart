import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/budget_model.dart';
import 'package:mi_dashboard_personal/services/finance/budget_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
  double _alertThreshold = 0.8; // 80%

  final _categories = [
    'General',
    'Alimentación',
    'Transporte',
    'Vivienda',
    'Ocio',
    'Salud',
    'Educación',
    'Compras',
    'Otros',
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: widget.budget == null ? 'Nuevo Presupuesto' : 'Editar Presupuesto',
            backgroundIcon: Icons.pie_chart,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    ).animate().fadeIn(duration: 300.ms);
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
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildLimitField() {
    return TextFormField(
      controller: _limitCtrl,
      decoration: InputDecoration(
        labelText: 'Límite de gasto *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.euro),
        suffixText: '€',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount <= 0) return 'Importe inválido';
        return null;
      },
      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Asocia el presupuesto a una categoría específica (opcional)',
      ),
      hint: const Text('Sin categoría específica'),
      items: _categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (v) => setState(() => _category = v),
    );
  }

  Widget _buildPeriodField() {
    return DropdownButtonFormField<String>(
      value: _period,
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
          _period = v!;
          if (_period == 'weekly') {
            _endDate = _startDate.add(const Duration(days: 7));
          } else if (_period == 'monthly') {
            _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
          } else if (_period == 'quarterly') {
            _endDate = DateTime(_startDate.year, _startDate.month + 3, 0);
          } else if (_period == 'yearly') {
            _endDate = DateTime(_startDate.year + 1, 1, 0);
          } else {
            _endDate = null; // custom requires manual selection
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
                if (_period != 'custom') {
                  // Recalculate end date
                  if (_period == 'weekly') {
                    _endDate = _startDate.add(const Duration(days: 7));
                  } else if (_period == 'monthly') {
                    _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
                  } else if (_period == 'quarterly') {
                    _endDate = DateTime(_startDate.year, _startDate.month + 3, 0);
                  } else if (_period == 'yearly') {
                    _endDate = DateTime(_startDate.year + 1, 1, 0);
                  }
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
            child: Text(
              DateFormat('d MMMM yyyy', 'es').format(_startDate),
              style: GoogleFonts.poppins(),
            ),
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
              if (picked != null) {
                setState(() => _endDate = picked);
              }
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
                style: GoogleFonts.poppins(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertThresholdField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Umbral de alerta',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recibe una alerta cuando alcances este porcentaje del presupuesto',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
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
              child: Text(
                '${(_alertThreshold * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'El sistema calculará automáticamente el gasto en tiempo real comparando con este presupuesto.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_period == 'custom' && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona una fecha de fin', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    final budget = Budget(
      id: widget.budget?.id ?? '',
      userId: widget.budget?.userId ?? '',
      name: _nameCtrl.text.trim(),
      amount: double.parse(_limitCtrl.text),
      limit: double.parse(_limitCtrl.text),
      category: _category ?? 'General',
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.budget == null ? 'Presupuesto creado' : 'Presupuesto actualizado',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins())),
        );
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
