import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

enum BackgroundStyle {
  none,
  gradientSunrise,
  gradientOcean,
  gradientForest,
  gradientOrchid,
}

class ThemePrefs {
  static const _kPreset = 'theme_preset';
  static const _kMode = 'theme_mode';
  static const _kBg = 'theme_bg_style';

  static Future<void> save({
    required ThemePreset preset,
    required ThemeMode mode,
    required BackgroundStyle bg,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kPreset, preset.index);
    await sp.setInt(_kMode, mode.index);
    await sp.setInt(_kBg, bg.index);
  }

  static Future<(ThemePreset, ThemeMode, BackgroundStyle)> load() async {
    final sp = await SharedPreferences.getInstance();
    final p =
        ThemePreset.values[sp.getInt(_kPreset) ?? ThemePreset.ocean.index];
    final m = ThemeMode.values[sp.getInt(_kMode) ?? ThemeMode.system.index];
    final b =
        BackgroundStyle.values[sp.getInt(_kBg) ?? BackgroundStyle.none.index];
    return (p, m, b);
  }
}
