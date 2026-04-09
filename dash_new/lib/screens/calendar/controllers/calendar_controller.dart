import 'dart:async';

import 'package:flutter/material.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/services/calendar_aggregator_service.dart';
import 'package:focuslane/screens/calendar/services/calendar_service.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({
    CalendarService? service,
    CalendarAggregatorService? aggregator,
    DateTime? initialDate,
    int initialViewIndex = 1,
  }) : _svc = service ?? CalendarService.I,
       _agg = aggregator ?? CalendarAggregatorService.I,
       _focused = initialDate ?? DateTime.now(),
       _selected = initialDate ?? DateTime.now(),
       _rangeFrom = initialDate ?? DateTime.now(),
       _rangeTo = initialDate ?? DateTime.now(),
       _activeViewIndex = initialViewIndex {
    agendaSearchCtrl.addListener(_onAgendaSearchChanged);
  }

  static const double monthRowHeight = 42;
  static const double dayListHeaderHeight = 48;
  static const double dayListBodyHeight = 190;

  static const int timelineStartHour = 6;
  static const int timelineEndHour = 23;
  static const double timeAxisWidth = 64;
  static const double weekDayColumnWidth = 184;

  final CalendarService _svc;
  final CalendarAggregatorService _agg;

  final TextEditingController agendaSearchCtrl = TextEditingController();

  DateTime _focused;
  DateTime _selected;
  DateTime _rangeFrom;
  DateTime _rangeTo;
  int _activeViewIndex;
  double _slotHeight = 56;

  Map<DateTime, List<CalendarItem>> _itemsByDay = const {};
  List<CalendarItem> _rangeItems = const [];
  PlannerPrefs? _prefs;

  StreamSubscription<List<CalendarItem>>? _rangeSub;
  StreamSubscription<PlannerPrefs>? _prefsSub;

  DateTime get focused => _focused;
  DateTime get selected => _selected;
  DateTime get rangeFrom => _rangeFrom;
  DateTime get rangeTo => _rangeTo;
  int get activeViewIndex => _activeViewIndex;
  double get slotHeight => _slotHeight;
  PlannerPrefs? get prefs => _prefs;
  List<CalendarItem> get rangeItems => _rangeItems;

  double get timelineHeight =>
      (timelineEndHour - timelineStartHour + 1) * _slotHeight;

  void start() {
    _watchForActiveView();
    _prefsSub = _svc.watchPrefs().listen((p) {
      _prefs = p;
      _watchForActiveView();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    agendaSearchCtrl.removeListener(_onAgendaSearchChanged);
    agendaSearchCtrl.dispose();
    _rangeSub?.cancel();
    _prefsSub?.cancel();
    super.dispose();
  }

  void _onAgendaSearchChanged() {
    notifyListeners();
  }

  void setActiveView(int index) {
    if (_activeViewIndex == index) return;
    _activeViewIndex = index;
    _watchForActiveView();
    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selected = selectedDay;
    _focused = focusedDay;
    notifyListeners();
  }

  void onMonthPageChanged(DateTime focusedDay) {
    _focused = focusedDay;
    _watchWindow(focusedDay);
    notifyListeners();
  }

  void selectDay(DateTime day) {
    _selected = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  void setFocused(DateTime day) {
    _focused = day;
    notifyListeners();
  }

  void goToday() {
    final now = DateTime.now();
    _focused = now;
    _selected = now;
    _watchForActiveView();
    notifyListeners();
  }

  void shiftVisible(int delta) {
    switch (_activeViewIndex) {
      case 0:
        _focused = DateTime(_focused.year + delta, 1, 1);
        _selected = DateTime(_focused.year, _selected.month, _selected.day);
        break;
      case 1:
        _focused = DateTime(_focused.year, _focused.month + delta, 1);
        _selected = DateTime(_focused.year, _focused.month, 1);
        break;
      case 2:
        _selected = _selected.add(Duration(days: 7 * delta));
        _focused = _selected;
        break;
      case 3:
        _selected = _selected.add(Duration(days: delta));
        _focused = _selected;
        break;
      case 4:
        _selected = _selected.add(Duration(days: 7 * delta));
        _focused = _selected;
        break;
    }
    _watchForActiveView();
    notifyListeners();
  }

  void setSlotHeight(double value) {
    final next = value.clamp(34.0, 120.0);
    if (next == _slotHeight) return;
    _slotHeight = next;
    notifyListeners();
  }

  List<CalendarItem> itemsFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return List<CalendarItem>.of(_itemsByDay[key] ?? const <CalendarItem>[]);
  }

  DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  List<DateTime> weekDays(DateTime anchor) {
    final start = weekStart(anchor);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  double topFor(DateTime time) {
    final baseMin = timelineStartHour * 60;
    final mins = (time.hour * 60 + time.minute) - baseMin;
    return (mins / 60.0) * _slotHeight;
  }

  void jumpToMonth(DateTime target) {
    _focused = target;
    _selected = target;
    _activeViewIndex = 1;
    _watchWindow(target);
    notifyListeners();
  }

  void focusEditedDay(DateTime when) {
    _focused = DateTime(when.year, when.month, 15);
    _selected = DateTime(when.year, when.month, when.day);
    _watchForActiveView();
    notifyListeners();
  }

  Future<void> setTypeEnabled(CalendarType type, bool enabled) async {
    final p = _prefs;
    if (p == null) return;

    final next = {...p.enabled};
    if (enabled) {
      next.add(type);
    } else {
      next.remove(type);
    }

    await _svc.savePrefs(
      PlannerPrefs(
        enabled: next,
        highOnly: p.highOnly,
        defaultTimetableId: p.defaultTimetableId,
      ),
    );
  }

  Future<void> setHighOnly(bool highOnly) async {
    final p = _prefs;
    if (p == null) return;

    await _svc.savePrefs(
      PlannerPrefs(
        enabled: p.enabled,
        highOnly: highOnly,
        defaultTimetableId: p.defaultTimetableId,
      ),
    );
  }

  String appBarTitle() {
    switch (_activeViewIndex) {
      case 0:
        return 'Calendario ${_focused.year}';
      case 1:
        return '${monthLabel(_focused.month)} ${_focused.year}';
      case 2:
        final ws = weekStart(_selected);
        final we = ws.add(const Duration(days: 6));
        return 'Semana ${humanDate(ws)} - ${humanDate(we)}';
      case 3:
        return 'Dia ${humanDate(_selected)}';
      case 4:
        return 'Agenda';
      default:
        return 'Calendario';
    }
  }

  String monthLabel(int month) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  String humanDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String humanDateLong(DateTime d) {
    const w = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final wd = w[(d.weekday - 1).clamp(0, 6)];
    return '$wd ${humanDate(d)}';
  }

  String weekdayShort(int weekday) {
    const w = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return w[(weekday - 1).clamp(0, 6)];
  }

  String humanDateTime(DateTime d, bool allDay) {
    if (allDay) return '${humanDate(d)} (todo el dia)';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${humanDate(d)} â€¢ $hh:$mm';
  }

  List<CalendarYearMonthStat> yearStats(int year) {
    final map = <int, List<CalendarItem>>{};
    for (final item in _rangeItems) {
      if (item.startAt.year != year) continue;
      (map[item.startAt.month] ??= <CalendarItem>[]).add(item);
    }

    return List.generate(12, (i) {
      final month = i + 1;
      final list = map[month] ?? const <CalendarItem>[];
      final high =
          list.where((e) => e.priority == CalendarPriority.high).length;
      final done =
          list
              .where((e) => e.type == CalendarType.task && e.completed == true)
              .length;
      return CalendarYearMonthStat(
        month: month,
        totalItems: list.length,
        highItems: high,
        doneTasks: done,
      );
    });
  }

  List<CalendarAgendaRow> agendaRows() {
    final query = agendaSearchCtrl.text.trim().toLowerCase();
    final items = _rangeItems
      .where((item) {
        final day = DateTime(
          item.startAt.year,
          item.startAt.month,
          item.startAt.day,
        );
        if (day.isBefore(
          DateTime(_rangeFrom.year, _rangeFrom.month, _rangeFrom.day),
        )) {
          return false;
        }
        if (day.isAfter(
          DateTime(_rangeTo.year, _rangeTo.month, _rangeTo.day),
        )) {
          return false;
        }
        if (query.isEmpty) return true;
        final hay =
            '${item.title} ${item.description ?? ''} ${item.sourceModule.name}'
                .toLowerCase();
        return hay.contains(query);
      })
      .toList(growable: false)..sort((a, b) => a.startAt.compareTo(b.startAt));

    final rows = <CalendarAgendaRow>[];
    DateTime? currentDay;
    for (final item in items) {
      final day = DateTime(
        item.startAt.year,
        item.startAt.month,
        item.startAt.day,
      );
      final changed =
          currentDay == null ||
          day.year != currentDay.year ||
          day.month != currentDay.month ||
          day.day != currentDay.day;
      if (changed) {
        currentDay = day;
        rows.add(CalendarAgendaRow.header(day));
      }
      rows.add(CalendarAgendaRow.item(item));
    }
    return rows;
  }

  void _watchForActiveView() {
    if (_activeViewIndex == 0) {
      _watchYear(_focused);
    } else {
      _watchWindow(_focused);
    }
  }

  void _watchYear(DateTime anchor) {
    final from = DateTime(anchor.year, 1, 1);
    final to = DateTime(anchor.year, 12, 31, 23, 59, 59);
    _watchSpan(from, to);
  }

  void _watchWindow(DateTime anchor) {
    final monthStart = DateTime(anchor.year, anchor.month, 1);
    final from = monthStart.subtract(const Duration(days: 14));
    final to = DateTime(anchor.year, anchor.month + 2, 14, 23, 59, 59);
    _watchSpan(from, to);
  }

  void _watchSpan(DateTime from, DateTime to) {
    _rangeFrom = from;
    _rangeTo = to;

    _rangeSub?.cancel();
    _rangeSub = _agg.combinedItems(from, to).listen((items) {
      final byDay = <DateTime, List<CalendarItem>>{};
      for (final item in items) {
        final key = DateTime(
          item.startAt.year,
          item.startAt.month,
          item.startAt.day,
        );
        (byDay[key] ??= <CalendarItem>[]).add(item);
      }
      for (final list in byDay.values) {
        list.sort((a, b) => a.startAt.compareTo(b.startAt));
      }

      _rangeItems = items;
      _itemsByDay = byDay;
      notifyListeners();
    });
  }
}

class CalendarAgendaRow {
  final DateTime? headerDay;
  final CalendarItem? item;

  const CalendarAgendaRow._({this.headerDay, this.item});

  factory CalendarAgendaRow.header(DateTime day) =>
      CalendarAgendaRow._(headerDay: day);

  factory CalendarAgendaRow.item(CalendarItem item) =>
      CalendarAgendaRow._(item: item);
}

class CalendarYearMonthStat {
  final int month;
  final int totalItems;
  final int highItems;
  final int doneTasks;

  const CalendarYearMonthStat({
    required this.month,
    required this.totalItems,
    required this.highItems,
    required this.doneTasks,
  });
}

