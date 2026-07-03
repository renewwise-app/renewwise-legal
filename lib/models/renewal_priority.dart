import 'package:flutter/material.dart';

enum RenewalPriority {
  critical('Critical', Color(0xFFDC2626)),
  high('High', Color(0xFFEA580C)),
  medium('Medium', Color(0xFF2563EB)),
  low('Low', Color(0xFF16A34A));

  const RenewalPriority(this.label, this.color);

  final String label;
  final Color color;
}
