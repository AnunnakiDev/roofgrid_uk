import 'package:flutter/material.dart';

class FormValidator {
  static bool validatePositiveNumbers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      final value = double.tryParse(controller.text);
      if (value == null || value <= 0) {
        return false;
      }
    }
    return true;
  }
}
