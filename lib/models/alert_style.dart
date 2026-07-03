import 'package:flutter/material.dart';

/// User-selected alert delivery style for a reminder (Package 7A).
enum AlertStyle {
  standard('Standard', '🟢', Color(0xFF16A34A)),
  important('Important', '🟡', Color(0xFFCA8A04)),
  critical('Critical', '🔴', Color(0xFFDC2626));

  const AlertStyle(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;

  String get dropdownLabel => '$emoji $label';

  bool get supportsSnooze => this != AlertStyle.standard;

  bool get isPersistent => this != AlertStyle.standard;
}
