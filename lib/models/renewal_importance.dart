import 'package:flutter/material.dart';

enum RenewalImportance {
  critical('Critical', Color(0xFFDC2626)),
  important('Important', Color(0xFFD97706)),
  optional('Optional', Color(0xFF6B7280));

  const RenewalImportance(this.label, this.color);

  final String label;
  final Color color;
}
