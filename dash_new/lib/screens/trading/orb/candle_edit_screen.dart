import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'package:mi_dashboard_personal/design/widgets/ui_scaffold.dart';

class CandleEditScreen extends StatefulWidget {
  const CandleEditScreen({super.key});
  static const route = '/trading/orb/candle/edit';

  @override
  State<CandleEditScreen> createState() => _CandleEditScreenState();
}

class _CandleEditScreenState extends State<CandleEditScreen> {
  final _form = GlobalKey<FormState>();

  final _symbol = TextEditingController();
  Timeframe _tf = Timeframe.m5;
  DateTime _time = DateTime.now();

  final _open = TextEditingController();
  final _high = TextEditingController();
  final _low = TextEditingController();
  final _close = TextEditingController();
  final _volume = TextEditingController();

  Candle? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      if (args['symbol'] is String) _symbol.text = (args['symbol'] as String);
      if (args['tf'] is Timeframe) _tf = args['tf'] as Timeframe;
      if (args['edit'] is Candle && editing == null) {
        editing = args['edit'] as Candle;
        _symbol.text = editing!.symbol;
        _tf = editing!.timeframe;
        _time = editing!.time;
        _open.text = editing!.open.toString();
        _high.text = editing!.high.toString();
        _low.text = editing!.low.toString();
        _close.text = editing!.close.toString();
        if (editing!.volume != null) _volume.text = editing!.volume.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Añadir vela' : 'Editar vela'),
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
                    DropdownButton<Timeframe>(
                      value: _tf,
                      items:
                          Timeframe.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.code),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _tf = v ?? _tf),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text('Inicio vela: ${_time.toLocal()}'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _time,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d == null) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_time),
                    );
                    if (t == null) return;
                    setState(
                      () =>
                          _time = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t.hour,
                            t.minute,
                          ),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _open,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Open'),
                        validator: _v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _high,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'High'),
                        validator: _v,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _low,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Low'),
                        validator: _v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _close,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Close'),
                        validator: _v,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _volume,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Volumen (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final c = Candle(
                      id: editing?.id ?? '',
                      symbol: _symbol.text.trim().toUpperCase(),
                      timeframe: _tf,
                      time: _time,
                      open: double.parse(_open.text),
                      high: double.parse(_high.text),
                      low: double.parse(_low.text),
                      close: double.parse(_close.text),
                      volume:
                          _volume.text.trim().isEmpty
                              ? null
                              : double.tryParse(_volume.text),
                      manual: true,
                    );
                    if (editing == null) {
                      await svc.addCandle(c);
                    } else {
                      await svc.updateCandle(c);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                if (editing != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    onPressed: () async {
                      await svc.deleteCandle(editing!.id);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _v(String? v) =>
      (double.tryParse(v ?? '') == null) ? 'Inválido' : null;
}

