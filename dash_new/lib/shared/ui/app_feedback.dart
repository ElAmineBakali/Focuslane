import 'package:flutter/material.dart';
import '../../ui/feedback/focus_feedback.dart';

class AppFeedback {
  static void showSuccess(BuildContext context, String message) {
    FocusFeedback.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    FocusFeedback.showError(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    FocusFeedback.showInfo(context, message);
  }
}
