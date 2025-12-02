// lib/services/trading_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trading_models.dart';

class TradingFirestoreService {
  TradingFirestoreService._();
  static final TradingFirestoreService I = TradingFirestoreService._();

  final _db = FirebaseFirestore.instance;
  // 🔐 Sin fallback a 'local': requiere usuario autenticado
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Raíces
  CollectionReference get _root => _db.collection('users').doc(_uid).collection('trading');
  CollectionReference get _tradesCol => _root.doc('data').collection('trades');
  CollectionReference get _strategiesCol => _root.doc('data').collection('strategies');
  CollectionReference get _watchlistsCol => _root.doc('data').collection('watchlists');
  CollectionReference symbolsCol(String wlId) => _watchlistsCol.doc(wlId).collection('symbols');
  CollectionReference get _tagsCol => _root.doc('data').collection('tags');
  CollectionReference get _journalsCol => _root.doc('data').collection('journals');
  DocumentReference get _metaDoc => _root.doc('meta');

  // ===== Trades
  Stream<List<Trade>> watchTrades({
    DateTime? from, DateTime? to,
    String? symbol, String? strategyId,
    Outcome? outcome,
  }) {
    Query q = _tradesCol.orderBy('entryDate', descending: true);
    if (from != null) q = q.where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    if (to != null) q = q.where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(to));
    if (symbol != null && symbol.isNotEmpty) q = q.where('symbol', isEqualTo: symbol);
    if (strategyId != null && strategyId.isNotEmpty) q = q.where('strategyId', isEqualTo: strategyId);
    if (outcome != null) q = q.where('outcome', isEqualTo: outcome.name);
    return q.snapshots().map((s) => s.docs.map(Trade.fromSnap).toList());
  }

  Future<void> addTrade(Trade t) async {
    // Calcula derivados si vienen los datos mínimos
    final derived = _derive(t);
    await _tradesCol.add(derived.toMap());
    await _touchMeta(derived);
  }

  Future<void> updateTrade(Trade t) async {
    final derived = _derive(t);
    await _tradesCol.doc(t.id).update(derived.toMap());
    await _touchMeta(derived);
  }

  Future<void> deleteTrade(String id) async => _tradesCol.doc(id).delete();

  Trade _derive(Trade t) {
    double pnl = t.pnl;
    double? r;
    Outcome out = t.outcome;

    if (t.outcome == Outcome.open && t.exitPrice != null) {
      // si hay exitPrice marcamos como cerrado (p.e. "Cerrar" en el form)
      out = Outcome.breakeven; // valor provisional, lo corregimos abajo
    }

    if (t.exitPrice != null) {
      final sign = (t.direction == Direction.long) ? 1.0 : -1.0;
      final gross = (t.exitPrice! - t.entryPrice) * sign * t.size;
      pnl = gross - t.fees;

      // Riesgo R por unidad = distancia al stop
      if (t.stopLoss != null) {
        final rCash = ((t.entryPrice - t.stopLoss!).abs()) * t.size;
        if (rCash > 0) r = pnl / rCash;
      }

      if (pnl > 0.000001) {
        out = Outcome.win;
      } else if (pnl < -0.000001) out = Outcome.loss;
      else out = Outcome.breakeven;
    }

    return Trade(
      id: t.id,
      symbol: t.symbol,
      assetClass: t.assetClass,
      direction: t.direction,
      entryDate: t.entryDate,
      exitDate: t.exitDate,
      entryPrice: t.entryPrice,
      exitPrice: t.exitPrice,
      size: t.size,
      fees: t.fees,
      stopLoss: t.stopLoss,
      takeProfit: t.takeProfit,
      strategyId: t.strategyId,
      tags: t.tags,
      rMultiple: r ?? t.rMultiple,
      pnl: pnl,
      pnlPct: t.pnlPct,
      outcome: out,
      notes: t.notes,
      screenshots: t.screenshots,
    );
  }

  Future<void> _touchMeta(Trade t) async {
    final monthKey = "${t.entryDate.year}-${t.entryDate.month.toString().padLeft(2,'0')}";
    await _metaDoc.set({
      'lastTradeAt': Timestamp.fromDate(DateTime.now()),
      'lastMonthKey': monthKey,
    }, SetOptions(merge: true));
  }

  // ===== Strategies
  Stream<List<Strategy>> watchStrategies() =>
    _strategiesCol.orderBy('name').snapshots().map((s) => s.docs.map(Strategy.fromSnap).toList());
  Future<void> addStrategy(Strategy x) async => _strategiesCol.add(x.toMap());
  Future<void> updateStrategy(Strategy x) async => _strategiesCol.doc(x.id).update(x.toMap());
  Future<void> deleteStrategy(String id) async => _strategiesCol.doc(id).delete();

  // ===== Watchlists
  Stream<List<Watchlist>> watchWatchlists() =>
    _watchlistsCol.orderBy('name').snapshots().map((s) => s.docs.map(Watchlist.fromSnap).toList());
  Stream<List<WatchSymbol>> watchSymbols(String wlId) =>
    symbolsCol(wlId).orderBy('priority').snapshots().map((s) => s.docs.map(WatchSymbol.fromSnap).toList());
  Future<String> addWatchlist(Watchlist w) async { final r = await _watchlistsCol.add(w.toMap()); return r.id; }
  Future<void> updateWatchlist(Watchlist w) async => _watchlistsCol.doc(w.id).update(w.toMap());
  Future<void> deleteWatchlist(String id) async => _watchlistsCol.doc(id).delete();
  Future<void> addSymbol(String wlId, WatchSymbol s) async => symbolsCol(wlId).add(s.toMap());
  Future<void> updateSymbol(String wlId, WatchSymbol s) async => symbolsCol(wlId).doc(s.id).update(s.toMap());
  Future<void> deleteSymbol(String wlId, String id) async => symbolsCol(wlId).doc(id).delete();

  // ===== Tags
  Stream<List<TradingTag>> watchTags() =>
    _tagsCol.orderBy('name').snapshots().map((s) => s.docs.map(TradingTag.fromSnap).toList());
  Future<void> addTag(TradingTag t) async => _tagsCol.add(t.toMap());
  Future<void> deleteTag(String id) async => _tagsCol.doc(id).delete();

  // ===== Journal
  Stream<List<JournalEntry>> watchJournal() =>
    _journalsCol.orderBy('date', descending: true).snapshots().map((s) => s.docs.map(JournalEntry.fromSnap).toList());
  Future<void> addJournal(JournalEntry j) async => _journalsCol.add(j.toMap());
  Future<void> updateJournal(JournalEntry j) async => _journalsCol.doc(j.id).update(j.toMap());
  Future<void> deleteJournal(String id) async => _journalsCol.doc(id).delete();

  // ===== Analytics (rápidos, sin agregaciones complejas)
  Future<Map<String, dynamic>> kpisForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final qs = await _tradesCol
      .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .get();

    int n = 0, wins = 0;
    double sumR = 0, sumPnl = 0;
    for (final d in qs.docs) {
      final t = Trade.fromSnap(d);
      n++;
      if (t.outcome == Outcome.win) wins++;
      if (t.rMultiple != null) sumR += t.rMultiple!;
      sumPnl += t.pnl;
    }
    return {
      'count': n,
      'winRate': n == 0 ? 0.0 : wins / n,
      'avgR': n == 0 ? 0.0 : sumR / n,
      'pnlMonth': sumPnl,
    };
  }

  Future<Map<DateTime, double>> equityCurveMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final qs = await _tradesCol
      .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .orderBy('entryDate')
      .get();

    final map = <DateTime, double>{};
    double cum = 0;
    for (final d in qs.docs) {
      final t = Trade.fromSnap(d);
      cum += t.pnl;
      final key = DateTime(t.entryDate.year, t.entryDate.month, t.entryDate.day);
      map[key] = cum;
    }
    return map;
  }


    CollectionReference get _candlesCol => _root.doc('data').collection('candles');

  // ===== CANDLES
  Stream<List<Candle>> watchCandles({
    required String symbol,
    required Timeframe timeframe,
    int limit = 200,
  }) {
    final q = _candlesCol
      .where('symbol', isEqualTo: symbol.toUpperCase())
      .where('timeframe', isEqualTo: timeframe.code)
      .orderBy('time', descending: true)
      .limit(limit);
    return q.snapshots().map((s) => s.docs.map(Candle.fromSnap).toList());
  }

  Future<List<Candle>> fetchLastCandles({
    required String symbol,
    required Timeframe timeframe,
    required int n,
  }) async {
    final qs = await _candlesCol
      .where('symbol', isEqualTo: symbol.toUpperCase())
      .where('timeframe', isEqualTo: timeframe.code)
      .orderBy('time', descending: true)
      .limit(n)
      .get();
    return qs.docs.map(Candle.fromSnap).toList();
  }

  Future<void> addCandle(Candle c) async => _candlesCol.add(c.toMap());
  Future<void> updateCandle(Candle c) async => _candlesCol.doc(c.id).update(c.toMap());
  Future<void> deleteCandle(String id) async => _candlesCol.doc(id).delete();

  // ===== ORB / Quartiles
  /// Devuelve Q1, Q2 (mediana), Q3, IQR, avg, min, max, n
  Future<Map<String, double>> quartilesFor({
    required String symbol,
    required Timeframe timeframe,
    required int n,
    CandleMetric metric = CandleMetric.range,
  }) async {
    final candles = await fetchLastCandles(symbol: symbol, timeframe: timeframe, n: n);
    if (candles.isEmpty) {
      return {'q1': 0, 'q2': 0, 'q3': 0, 'iqr': 0, 'avg': 0, 'min': 0, 'max': 0, 'n': 0};
    }
    final values = candles
        .map((c) => metric == CandleMetric.range ? c.range : c.body)
        .where((v) => v.isFinite && v > 0)
        .toList()
      ..sort();

    double median(List<double> xs) {
      final m = xs.length;
      if (m == 0) return 0;
      if (m.isOdd) return xs[m ~/ 2];
      return (xs[m ~/ 2 - 1] + xs[m ~/ 2]) / 2.0;
    }

    final m = values.length;
    final q2 = median(values);
    final lower = values.sublist(0, m ~/ 2);
    final upper = values.sublist((m + 1) ~/ 2);
    final q1 = median(lower);
    final q3 = median(upper);
    final iqr = (q3 - q1).abs();

    final sum = values.fold<double>(0, (a, b) => a + b);
    final avg = sum / m;
    final mn = values.first;
    final mx = values.last;

    return {
      'q1': q1,
      'q2': q2,
      'q3': q3,
      'iqr': iqr,
      'avg': avg,
      'min': mn,
      'max': mx,
      'n': m.toDouble(),
    };
  }
}
