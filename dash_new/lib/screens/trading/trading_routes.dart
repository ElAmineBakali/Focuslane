import 'package:flutter/material.dart';
import 'dashboard/trading_home_screen.dart';

import 'trades/trades_list_screen.dart';
import 'trades/trade_edit_screen.dart';

import 'strategies/strategies_screen.dart';
import 'strategies/strategy_detail_screen.dart';

import 'watchlists/watchlists_screen.dart';
import 'watchlists/watchlist_edit_screen.dart';
import 'watchlists/symbol_edit_screen.dart';

import 'journal/journal_screen.dart';
import 'journal/journal_edit_screen.dart';

import 'analytics/trading_analytics_screen.dart';

import 'tags/trading_tags_screen.dart';
import 'orb/orb_tools_screen.dart';
import 'orb/candle_edit_screen.dart';

Map<String, WidgetBuilder> tradingRoutes = {
  TradingHomeScreen.route: (_) => const TradingHomeScreen(),

  TradesListScreen.route: (_) => const TradesListScreen(),
  TradeEditScreen.route: (_) => const TradeEditScreen(),

  StrategiesScreen.route: (_) => const StrategiesScreen(),
  StrategyDetailScreen.route: (_) => const StrategyDetailScreen(),

  WatchlistsScreen.route: (_) => const WatchlistsScreen(),
  WatchlistEditScreen.route: (_) => const WatchlistEditScreen(),
  SymbolEditScreen.route: (_) => const SymbolEditScreen(),

  JournalScreen.route: (_) => const JournalScreen(),
  TradingJournalEditScreen.route: (_) => const TradingJournalEditScreen(),

  TradingAnalyticsScreen.route: (_) => const TradingAnalyticsScreen(),

  TradingTagsScreen.route: (_) => const TradingTagsScreen(),
  OrbToolsScreen.route: (_) => const OrbToolsScreen(),
  CandleEditScreen.route: (_) => const CandleEditScreen(),

};
