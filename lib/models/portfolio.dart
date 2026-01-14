import "dart:ui";

import 'money_value.dart';
class Portfolio {
  final MoneyValue totalAmountPortfolio;
  final List<PortfolioPosition> positions;

  Portfolio({
    required this.totalAmountPortfolio,
    required this.positions,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final positions = (json['positions'] as List? ?? [])
        .map((p) => PortfolioPosition.fromJson(p))
        .toList();

    return Portfolio(
      totalAmountPortfolio: MoneyValue.fromJson(
        json['totalAmountPortfolio'] ?? {},
      ),
      positions: positions,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalAmountPortfolio': totalAmountPortfolio.toJson(),
    'positions': positions.map((p) => p.toJson()).toList(),
  };

  double getTotalValue() => totalAmountPortfolio.toDouble();
}

class PortfolioPosition {
  final String figi;
  final String instrumentType;
  final Quotation quantity;
  final MoneyValue currentPrice;

  PortfolioPosition({
    required this.figi,
    required this.instrumentType,
    required this.quantity,
    required this.currentPrice,
  });

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      figi: json['figi']?.toString() ?? '',
      instrumentType: json['instrumentType']?.toString() ?? '',
      quantity: Quotation.fromJson(json['quantity'] ?? {}),
      currentPrice: MoneyValue.fromJson(json['currentPrice'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'figi': figi,
    'instrumentType': instrumentType,
    'quantity': quantity.toJson(),
    'currentPrice': currentPrice.toJson(),
  };

  double getPositionValue() => 
      quantity.toDouble() * currentPrice.toDouble();

  String getInstrumentTypeName() {
    switch (instrumentType.toLowerCase()) {
      case 'bond':
        return 'Облигация';
      case 'share':
        return 'Акция';
      case 'currency':
        return 'Валюта';
      case 'etf':
        return 'Фонд';
      case 'future':
        return 'Фьючерс';
      case 'option':
        return 'Опцион';
      default:
        return instrumentType;
    }
  }
}