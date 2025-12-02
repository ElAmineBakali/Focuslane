import 'package:cloud_firestore/cloud_firestore.dart';

enum AssetClass { stock, crypto, fx, future }
enum Direction { long, short }
enum Outcome { win, loss, breakeven, open }

class Trade {
  final String id;
  final String symbol;
  final AssetClass assetClass;
  final Direction direction;
  final DateTime entryDate;
  final DateTime? exitDate;
  final double entryPrice;
  final double? exitPrice;
  final double size; // unidades/contratos
  final double fees;
  final double? stopLoss;
  final double? takeProfit;
  final String? strategyId;
  final List<String> tags;
  final double? rMultiple; // calculado
  final double pnl;        // calculado
  final double? pnlPct;    // opcional, sobre capital o sobre entrada
  final Outcome outcome;
  final String? notes;
  final List<String> screenshots;

  Trade({
    required this.id,
    required this.symbol,
    required this.assetClass,
    required this.direction,
    required this.entryDate,
    this.exitDate,
    required this.entryPrice,
    this.exitPrice,
    required this.size,
    this.fees = 0.0,
    this.stopLoss,
    this.takeProfit,
    this.strategyId,
    this.tags = const [],
    this.rMultiple,
    this.pnl = 0.0,
    this.pnlPct,
    this.outcome = Outcome.open,
    this.notes,
    this.screenshots = const [],
  });

  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'assetClass': assetClass.name,
    'direction': direction.name,
    'entryDate': Timestamp.fromDate(entryDate),
    'exitDate': exitDate != null ? Timestamp.fromDate(exitDate!) : null,
    'entryPrice': entryPrice,
    'exitPrice': exitPrice,
    'size': size,
    'fees': fees,
    'stopLoss': stopLoss,
    'takeProfit': takeProfit,
    'strategyId': strategyId,
    'tags': tags,
    'rMultiple': rMultiple,
    'pnl': pnl,
    'pnlPct': pnlPct,
    'outcome': outcome.name,
    'notes': notes,
    'screenshots': screenshots,
  };

  static Trade fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Trade(
      id: s.id,
      symbol: (d['symbol'] ?? '') as String,
      assetClass: AssetClass.values.firstWhere(
        (e) => e.name == (d['assetClass'] ?? 'stock'),
        orElse: () => AssetClass.stock,
      ),
      direction: Direction.values.firstWhere(
        (e) => e.name == (d['direction'] ?? 'long'),
        orElse: () => Direction.long,
      ),
      entryDate: (d['entryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exitDate: (d['exitDate'] as Timestamp?)?.toDate(),
      entryPrice: ((d['entryPrice'] ?? 0) as num).toDouble(),
      exitPrice: (d['exitPrice'] as num?)?.toDouble(),
      size: ((d['size'] ?? 0) as num).toDouble(),
      fees: ((d['fees'] ?? 0) as num).toDouble(),
      stopLoss: (d['stopLoss'] as num?)?.toDouble(),
      takeProfit: (d['takeProfit'] as num?)?.toDouble(),
      strategyId: d['strategyId'],
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      rMultiple: (d['rMultiple'] as num?)?.toDouble(),
      pnl: ((d['pnl'] ?? 0) as num).toDouble(),
      pnlPct: (d['pnlPct'] as num?)?.toDouble(),
      outcome: Outcome.values.firstWhere(
        (e) => e.name == (d['outcome'] ?? 'open'),
        orElse: () => Outcome.open,
      ),
      notes: d['notes'],
      screenshots: (d['screenshots'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class Strategy {
  final String id;
  final String name;
  final String? description;
  final String timeframe; // "M1", "H1", "D1", etc.
  final String? rulesEntry;
  final String? rulesExit;
  final double? riskPerTradePct;
  Strategy({
    required this.id,
    required this.name,
    this.description,
    this.timeframe = 'D1',
    this.rulesEntry,
    this.rulesExit,
    this.riskPerTradePct,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'timeframe': timeframe,
    'rulesEntry': rulesEntry,
    'rulesExit': rulesExit,
    'riskPerTradePct': riskPerTradePct,
  };

  static Strategy fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Strategy(
      id: s.id,
      name: d['name'] ?? '',
      description: d['description'],
      timeframe: d['timeframe'] ?? 'D1',
      rulesEntry: d['rulesEntry'],
      rulesExit: d['rulesExit'],
      riskPerTradePct: (d['riskPerTradePct'] as num?)?.toDouble(),
    );
  }
}

class Watchlist {
  final String id;
  final String name;
  Watchlist({required this.id, required this.name});
  Map<String, dynamic> toMap() => {'name': name};
  static Watchlist fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Watchlist(id: s.id, name: d['name'] ?? '');
  }
}

class WatchSymbol {
  final String id;
  final String ticker;
  final String? note;
  final int priority; // 1..3
  WatchSymbol({required this.id, required this.ticker, this.note, this.priority = 2});
  Map<String, dynamic> toMap() => {'ticker': ticker, 'note': note, 'priority': priority};
  static WatchSymbol fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return WatchSymbol(
      id: s.id,
      ticker: d['ticker'] ?? '',
      note: d['note'],
      priority: (d['priority'] ?? 2) as int,
    );
  }
}

class TradingTag {
  final String id;
  final String name;
  final String? color;
  TradingTag({required this.id, required this.name, this.color});
  Map<String, dynamic> toMap() => {'name': name, 'color': color};
  static TradingTag fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return TradingTag(id: s.id, name: d['name'] ?? '', color: d['color']);
  }
}

class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final int mood; // 1..5
  final List<String> checklist; // “seguí plan”, etc.
  JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.mood = 3,
    this.checklist = const [],
  });

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'title': title,
    'content': content,
    'mood': mood,
    'checklist': checklist,
  };

  static JournalEntry fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return JournalEntry(
      id: s.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: d['title'] ?? '',
      content: d['content'] ?? '',
      mood: (d['mood'] ?? 3) as int,
      checklist: (d['checklist'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

// ====== Candles / ORB ======
enum Timeframe { m1, m5, m15, m30, h1, h4, d1 }
extension TimeframeX on Timeframe {
  String get code => switch (this) {
    Timeframe.m1 => '1m',
    Timeframe.m5 => '5m',
    Timeframe.m15 => '15m',
    Timeframe.m30 => '30m',
    Timeframe.h1 => '1h',
    Timeframe.h4 => '4h',
    Timeframe.d1 => '1d',
  };
  static Timeframe fromCode(String s) {
    return Timeframe.values.firstWhere(
      (e) => e.code == s,
      orElse: () => Timeframe.m5,
    );
  }
}

enum CandleMetric { range, body } // range = high-low; body = |close-open|

class Candle {
  final String id;
  final String symbol;
  final Timeframe timeframe;
  final DateTime time; // inicio de la vela
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;
  final bool manual; // true si la has insertado tú

  Candle({
    required this.id,
    required this.symbol,
    required this.timeframe,
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
    this.manual = true,
  });

  double get range => (high - low).abs();
  double get body => (close - open).abs();

  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'timeframe': timeframe.code,
    'time': Timestamp.fromDate(time),
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'volume': volume,
    'manual': manual,
  };

  static Candle fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Candle(
      id: s.id,
      symbol: (d['symbol'] ?? '').toString().toUpperCase(),
      timeframe: TimeframeX.fromCode(d['timeframe'] ?? '5m'),
      time: (d['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      open: ((d['open'] ?? 0) as num).toDouble(),
      high: ((d['high'] ?? 0) as num).toDouble(),
      low: ((d['low'] ?? 0) as num).toDouble(),
      close: ((d['close'] ?? 0) as num).toDouble(),
      volume: (d['volume'] as num?)?.toDouble(),
      manual: (d['manual'] ?? true) as bool,
    );
  }
}
