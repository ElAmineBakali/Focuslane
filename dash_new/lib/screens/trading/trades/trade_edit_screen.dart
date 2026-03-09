import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'package:mi_dashboard_personal/design/widgets/ui_scaffold.dart';

class TradeEditScreen extends StatefulWidget {
  const TradeEditScreen({super.key});
  static const route = '/trading/trade/edit';

  @override
  State<TradeEditScreen> createState() => _TradeEditScreenState();
}

class _TradeEditScreenState extends State<TradeEditScreen> {
  final _form = GlobalKey<FormState>();

  final _symbol = TextEditingController();
  AssetClass _asset = AssetClass.stock;
  Direction _dir = Direction.long;

  DateTime _entryDate = DateTime.now();
  DateTime? _exitDate;

  final _entry = TextEditingController();
  final _exit = TextEditingController();
  final _size = TextEditingController(text: '0');
  final _fees = TextEditingController(text: '0');
  final _sl = TextEditingController();
  final _tp = TextEditingController();

  final _strategyId = TextEditingController();
  final _tags = TextEditingController();
  final _notes = TextEditingController();

  Trade? editing;

  // Calculadora de riesgo
  final _capital = TextEditingController(text: '10000');
  final _riskPct = TextEditingController(text: '1.0');
  final _stopDist =
      TextEditingController(); // precio de stop (distancia absoluta o SL)
  double? _calcSize;
  double? _expR; // R esperado si define TP

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Trade && editing == null) {
      editing = arg;
      _symbol.text = arg.symbol;
      _asset = arg.assetClass;
      _dir = arg.direction;
      _entryDate = arg.entryDate;
      _exitDate = arg.exitDate;
      _entry.text = arg.entryPrice.toString();
      _exit.text = arg.exitPrice?.toString() ?? '';
      _size.text = arg.size.toString();
      _fees.text = arg.fees.toString();
      _sl.text = arg.stopLoss?.toString() ?? '';
      _tp.text = arg.takeProfit?.toString() ?? '';
      _strategyId.text = arg.strategyId ?? '';
      _tags.text = arg.tags.join(',');
      _notes.text = arg.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nuevo trade' : 'Editar trade'),
        actions: [
          if (editing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await svc.deleteTrade(editing!.id);
                if (mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _symbol,
                        decoration: const InputDecoration(labelText: 'Símbolo'),
                        textCapitalization: TextCapitalization.characters,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<AssetClass>(
                      value: _asset,
                      items:
                          AssetClass.values
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _asset = v ?? _asset),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<Direction>(
                      value: _dir,
                      items:
                          Direction.values
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _dir = v ?? _dir),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _entry,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio entrada',
                        ),
                        validator:
                            (v) =>
                                double.tryParse(v ?? '') == null
                                    ? 'Inválido'
                                    : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _size,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tamaño (unidades)',
                        ),
                        validator:
                            (v) =>
                                double.tryParse(v ?? '') == null
                                    ? 'Inválido'
                                    : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Stop Loss (precio)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _tp,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Take Profit (precio)',
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _exit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio salida (si cerrado)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _fees,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Comisiones',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    'Entrada: ${_entryDate.toLocal().toString().split(" ").first}',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _entryDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _entryDate = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available),
                  title: Text(
                    'Salida: ${_exitDate != null ? _exitDate!.toLocal().toString().split(" ").first : "–"}',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _exitDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _exitDate = d);
                  },
                ),
                const Divider(height: 24),

                Text(
                  'Calculadora de riesgo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _capital,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Capital'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _riskPct,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Riesgo %',
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stopDist,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Stop (precio stop)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _calcRisk,
                      child: const Text('Calcular tamaño'),
                    ),
                  ],
                ),
                if (_calcSize != null || _expR != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tamaño sugerido: ${_calcSize?.toStringAsFixed(2) ?? "-"}  •  R esperado: ${_expR?.toStringAsFixed(2) ?? "-"}',
                    ),
                  ),

                const Divider(height: 24),

                TextField(
                  controller: _strategyId,
                  decoration: const InputDecoration(
                    labelText: 'Estrategia ID (opcional)',
                  ),
                ),
                TextField(
                  controller: _tags,
                  decoration: const InputDecoration(labelText: 'Tags (coma)'),
                ),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final t = Trade(
                      id: editing?.id ?? '',
                      symbol: _symbol.text.trim().toUpperCase(),
                      assetClass: _asset,
                      direction: _dir,
                      entryDate: _entryDate,
                      exitDate: _exitDate,
                      entryPrice: double.parse(_entry.text),
                      exitPrice:
                          _exit.text.trim().isEmpty
                              ? null
                              : double.parse(_exit.text),
                      size: double.parse(_size.text),
                      fees: double.tryParse(_fees.text) ?? 0,
                      stopLoss:
                          _sl.text.trim().isEmpty
                              ? null
                              : double.parse(_sl.text),
                      takeProfit:
                          _tp.text.trim().isEmpty
                              ? null
                              : double.parse(_tp.text),
                      strategyId:
                          _strategyId.text.trim().isEmpty
                              ? null
                              : _strategyId.text.trim(),
                      tags:
                          _tags.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                      notes:
                          _notes.text.trim().isEmpty
                              ? null
                              : _notes.text.trim(),
                      outcome: editing?.outcome ?? Outcome.open,
                      pnl: editing?.pnl ?? 0.0,
                    );
                    if (editing == null) {
                      await svc.addTrade(t);
                    } else {
                      await svc.updateTrade(t);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),

                if (editing != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.rule),
                          label: const Text('Marcar BE (0 R)'),
                          onPressed: () async {
                            final t = editing!;
                            final e = Trade(
                              id: t.id,
                              symbol: t.symbol,
                              assetClass: t.assetClass,
                              direction: t.direction,
                              entryDate: t.entryDate,
                              exitDate: DateTime.now(),
                              entryPrice: t.entryPrice,
                              exitPrice: t.entryPrice,
                              size: t.size,
                              fees: t.fees,
                              stopLoss: t.stopLoss,
                              takeProfit: t.takeProfit,
                              strategyId: t.strategyId,
                              tags: t.tags,
                              rMultiple: 0,
                              pnl: 0,
                              pnlPct: 0,
                              outcome: Outcome.breakeven,
                              notes: t.notes,
                              screenshots: t.screenshots,
                            );
                            await svc.updateTrade(e);
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar (usar precio salida)'),
                          onPressed: () async {
                            if (_exit.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Introduce precio de salida'),
                                ),
                              );
                              return;
                            }
                            final t = editing!;
                            final e = Trade(
                              id: t.id,
                              symbol: t.symbol,
                              assetClass: t.assetClass,
                              direction: t.direction,
                              entryDate: t.entryDate,
                              exitDate: DateTime.now(),
                              entryPrice: t.entryPrice,
                              exitPrice: double.parse(_exit.text),
                              size: double.parse(_size.text),
                              fees: double.tryParse(_fees.text) ?? t.fees,
                              stopLoss: t.stopLoss,
                              takeProfit: t.takeProfit,
                              strategyId: t.strategyId,
                              tags: t.tags,
                              rMultiple: t.rMultiple,
                              pnl: t.pnl,
                              pnlPct: t.pnlPct,
                              outcome: t.outcome,
                              notes: t.notes,
                              screenshots: t.screenshots,
                            );
                            await svc.updateTrade(e);
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _calcRisk() {
    final capital = double.tryParse(_capital.text) ?? 0;
    final riskPct = (double.tryParse(_riskPct.text) ?? 0) / 100.0;
    final entry = double.tryParse(_entry.text) ?? 0;
    final stop = double.tryParse(_stopDist.text) ?? 0;
    final take = double.tryParse(_tp.text) ?? 0;

    if (capital <= 0 || riskPct <= 0 || entry <= 0 || stop <= 0) {
      setState(() {
        _calcSize = null;
        _expR = null;
      });
      return;
    }

    // riesgo en â‚¬ = capital * %; riesgo por unidad = |entry - stop|
    final riskCash = capital * riskPct;
    final riskPerUnit = (entry - stop).abs();
    final size = riskPerUnit > 0 ? (riskCash / riskPerUnit) : 0;

    double? expR;
    if (take > 0 && stop > 0) {
      final gainPerUnit = (take - entry) * (_dir == Direction.long ? 1 : -1);
      final lossPerUnit = (entry - stop).abs();
      if (lossPerUnit > 0) expR = gainPerUnit / lossPerUnit;
    }

    setState(() {
      _calcSize = size as double?;
      _expR = expR;
    });
  }
}

