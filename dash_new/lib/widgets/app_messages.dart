// Deprecated: Migrate to blocks/toast/app_toast.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/blocks/toast/app_toast.dart';

class AppMessages {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info,
    Color? color,
  }) {
    AppToast.show(context, message, icon: icon, color: color);
  }

  static void success(BuildContext context, String message) =>
      AppToast.success(context, message);
  static void error(BuildContext context, String message) =>
      AppToast.error(context, message);
  static void info(BuildContext context, String message) =>
      AppToast.info(context, message);
}
