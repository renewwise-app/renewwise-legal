import 'package:flutter/material.dart';

enum RenewalCategory {
  insurance('Insurance', Icons.shield_outlined),
  vehicle('Vehicle', Icons.directions_car_outlined),
  drivingLicence('Driving Licence', Icons.badge_outlined),
  passport('Passport', Icons.flight_outlined),
  internet('Internet', Icons.wifi_outlined),
  electricity('Electricity', Icons.bolt_outlined),
  water('Water', Icons.water_drop_outlined),
  gas('Gas', Icons.local_fire_department_outlined),
  gym('Gym', Icons.fitness_center_outlined),
  subscription('Subscription', Icons.subscriptions_outlined),
  loanEmi('Loan EMI', Icons.account_balance_outlined),
  creditCard('Credit Card', Icons.credit_card_outlined),
  warranty('Warranty', Icons.verified_outlined),
  other('Other', Icons.category_outlined);

  const RenewalCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}
