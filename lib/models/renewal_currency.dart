enum RenewalCurrency {
  inr('INR', '₹'),
  usd('USD', r'$'),
  eur('EUR', '€'),
  gbp('GBP', '£'),
  jpy('JPY', '¥');

  const RenewalCurrency(this.code, this.symbol);

  final String code;
  final String symbol;

  /// Formats [amount] as e.g. "₹ 5,000" or "$ 1,200".
  String formatAmount(double amount) {
    final intPart = amount.truncate().toInt();
    return '$symbol ${_commaSeparate(intPart)}';
  }

  static String _commaSeparate(int n) {
    final str = n.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return n < 0 ? '-${buf.toString()}' : buf.toString();
  }
}
