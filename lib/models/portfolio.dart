
// lib/models/portfolio.dart
class Portfolio {
  final String accountId;
  final List<PortfolioPosition> positions;
  final MoneyAmount totalAmountShares;
  final MoneyAmount totalAmountBonds;
  final MoneyAmount totalAmountEtf;
  final MoneyAmount totalAmountCurrencies;
  final MoneyAmount totalAmountPortfolio;
  final Quotation expectedYield;
  final MoneyAmount dailyYield;
  final Quotation dailyYieldRelative;

  Portfolio({
    required this.accountId,
    required this.positions,
    required this.totalAmountShares,
    required this.totalAmountBonds,
    required this.totalAmountEtf,
    required this.totalAmountCurrencies,
    required this.totalAmountPortfolio,
    required this.expectedYield,
    required this.dailyYield,
    required this.dailyYieldRelative,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      accountId: json['accountId'] ?? '',
      positions: (json['positions'] as List? ?? [])
          .map((position) => PortfolioPosition.fromJson(position))
          .toList(),
      totalAmountShares: MoneyAmount.fromJson(json['totalAmountShares'] ?? {}),
      totalAmountBonds: MoneyAmount.fromJson(json['totalAmountBonds'] ?? {}),
      totalAmountEtf: MoneyAmount.fromJson(json['totalAmountEtf'] ?? {}),
      totalAmountCurrencies: MoneyAmount.fromJson(json['totalAmountCurrencies'] ?? {}),
      totalAmountPortfolio: MoneyAmount.fromJson(json['totalAmountPortfolio'] ?? {}),
      expectedYield: Quotation.fromJson(json['expectedYield'] ?? {}),
      dailyYield: MoneyAmount.fromJson(json['dailyYield'] ?? {}),
      dailyYieldRelative: Quotation.fromJson(json['dailyYieldRelative'] ?? {}),
    );
  }

  double getTotalValue() {
    return totalAmountPortfolio.toDouble();
  }
}

class PortfolioPosition {
  final String figi;
  final String instrumentType;
  final Quotation quantity;
  final MoneyAmount averagePositionPrice;
  final Quotation expectedYield;
  final MoneyAmount currentPrice;
  final String ticker;
  final String classCode;

  PortfolioPosition({
    required this.figi,
    required this.instrumentType,
    required this.quantity,
    required this.averagePositionPrice,
    required this.expectedYield,
    required this.currentPrice,
    required this.ticker,
    required this.classCode,
  });

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      figi: json['figi'] ?? '',
      instrumentType: json['instrumentType'] ?? '',
      quantity: Quotation.fromJson(json['quantity'] ?? {}),
      averagePositionPrice: MoneyAmount.fromJson(json['averagePositionPrice'] ?? {}),
      expectedYield: Quotation.fromJson(json['expectedYield'] ?? {}),
      currentPrice: MoneyAmount.fromJson(json['currentPrice'] ?? {}),
      ticker: json['ticker'] ?? '',
      classCode: json['classCode'] ?? '',
    );
  }

  double getPositionValue() {
    return quantity.toDouble() * currentPrice.toDouble();
  }

  String getInstrumentTypeName() {
    switch (instrumentType) {
      case 'share': return 'Акция';
      case 'bond': return 'Облигация';
      case 'etf': return 'ETF';
      case 'currency': return 'Валюта';
      default: return instrumentType;
    }
  }

  // Новый метод для получения описания инструмента
  String getInstrumentDescription() {
    if (ticker.isNotEmpty) {
      return ticker;
    }
    return figi;
  }

  // Новый метод для проверки есть ли тикер
  bool get hasTicker => ticker.isNotEmpty;
}

class MoneyAmount {
  final String currency;
  final String units;
  final int nano;

  MoneyAmount({
    required this.currency,
    required this.units,
    required this.nano,
  });

  factory MoneyAmount.fromJson(Map<String, dynamic> json) {
    return MoneyAmount(
      currency: json['currency'] ?? '',
      units: json['units']?.toString() ?? '0',
      nano: json['nano'] ?? 0,
    );
  }

  double toDouble() {
    try {
      final unitsInt = int.tryParse(units) ?? 0;
      return unitsInt + (nano / 1000000000);
    } catch (e) {
      return 0.0;
    }
  }

  String formatCurrency({bool showCurrency = true}) {
    final value = toDouble();
    if (value == 0) return '0 ₽';
    
    final formatted = value.toStringAsFixed(currency == 'rub' ? 2 : 2);
    return showCurrency ? '$formatted ${_getCurrencySymbol()}' : formatted;
  }

  String _getCurrencySymbol() {
    switch (currency.toLowerCase()) {
      case 'rub': return '₽';
      case 'usd': return '\$';
      case 'eur': return '€';
      default: return currency.toUpperCase();
    }
  }
}

class Quotation {
  final String units;
  final int nano;

  Quotation({
    required this.units,
    required this.nano,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      units: json['units']?.toString() ?? '0',
      nano: json['nano'] ?? 0,
    );
  }

  double toDouble() {
    try {
      final unitsInt = int.tryParse(units) ?? 0;
      return unitsInt + (nano / 1000000000);
    } catch (e) {
      return 0.0;
    }
  }

  String format({bool showSign = false}) {
    final value = toDouble();
    final sign = showSign && value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}';
  }
}
