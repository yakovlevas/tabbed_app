class StockInstrument {
  final String figi;
  final String ticker;
  final String name;
  final String currency;
  final int lot;

  StockInstrument({
    required this.figi,
    required this.ticker,
    required this.name,
    required this.currency,
    required this.lot,
  });

  factory StockInstrument.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return StockInstrument(
      figi: json['figi']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      lot: parseInt(json['lot'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'figi': figi,
    'ticker': ticker,
    'name': name,
    'currency': currency,
    'lot': lot,
  };
}