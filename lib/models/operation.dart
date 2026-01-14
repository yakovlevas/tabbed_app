import 'money_value.dart';
class Operation {
  final String id;
  final String parentOperationId;
  final String currency;
  final MoneyValue payment;
  final MoneyValue price;
  final String state;
  final int quantity;
  final int quantityRest;
  final String figi;
  final String instrumentType;
  final DateTime date;
  final String operationType;
  final List<OperationTrade> trades;
  final String assetUid;
  final String positionUid;
  final String instrumentUid;
  final int? operationStatus;
  final List<MoneyValue> commission;
  final String tradesStatus;
  final String name;
  final String description;
  final DateTime? dateExecuted;

  Operation({
    required this.id,
    required this.parentOperationId,
    required this.currency,
    required this.payment,
    required this.price,
    required this.state,
    required this.quantity,
    required this.quantityRest,
    required this.figi,
    required this.instrumentType,
    required this.date,
    required this.operationType,
    required this.trades,
    required this.assetUid,
    required this.positionUid,
    required this.instrumentUid,
    this.operationStatus,
    required this.commission,
    required this.tradesStatus,
    required this.name,
    required this.description,
    this.dateExecuted,
  });

  factory Operation.fromJson(Map<String, dynamic> json) {
    int parseLong(dynamic value) {
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

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    final trades = (json['trades'] as List? ?? [])
        .map((t) => OperationTrade.fromJson(t))
        .toList();

    final commission = (json['commission'] as List? ?? [])
        .map((c) => MoneyValue.fromJson(c))
        .toList();

    return Operation(
      id: json['id']?.toString() ?? '',
      parentOperationId: json['parentOperationId']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      payment: MoneyValue.fromJson(json['payment'] ?? {}),
      price: MoneyValue.fromJson(json['price'] ?? {}),
      state: json['state']?.toString() ?? '',
      quantity: parseLong(json['quantity'] ?? 0),
      quantityRest: parseLong(json['quantityRest'] ?? 0),
      figi: json['figi']?.toString() ?? '',
      instrumentType: json['instrumentType']?.toString() ?? '',
      date: parseDateTime(json['date']) ?? DateTime.now(),
      operationType: json['operationType']?.toString() ?? '',
      trades: trades,
      assetUid: json['assetUid']?.toString() ?? '',
      positionUid: json['positionUid']?.toString() ?? '',
      instrumentUid: json['instrumentUid']?.toString() ?? '',
      operationStatus: parseLong(json['operationStatus']),
      commission: commission,
      tradesStatus: json['tradesStatus']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dateExecuted: parseDateTime(json['dateExecuted']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parentOperationId': parentOperationId,
    'currency': currency,
    'payment': payment.toJson(),
    'price': price.toJson(),
    'state': state,
    'quantity': quantity,
    'quantityRest': quantityRest,
    'figi': figi,
    'instrumentType': instrumentType,
    'date': date.toIso8601String(),
    'operationType': operationType,
    'trades': trades.map((t) => t.toJson()).toList(),
    'assetUid': assetUid,
    'positionUid': positionUid,
    'instrumentUid': instrumentUid,
    'operationStatus': operationStatus,
    'commission': commission.map((c) => c.toJson()).toList(),
    'tradesStatus': tradesStatus,
    'name': name,
    'description': description,
    'dateExecuted': dateExecuted?.toIso8601String(),
  };

  String getOperationTypeName() {
    switch (operationType) {
      case 'OPERATION_TYPE_UNSPECIFIED':
        return 'Не указано';
      case 'OPERATION_TYPE_INPUT':
        return 'Пополнение счета';
      case 'OPERATION_TYPE_OUTPUT':
        return 'Вывод средств';
      case 'OPERATION_TYPE_BUY':
        return 'Покупка';
      case 'OPERATION_TYPE_SELL':
        return 'Продажа';
      case 'OPERATION_TYPE_BROKER_FEE':
        return 'Брокерская комиссия';
      case 'OPERATION_TYPE_DIVIDEND':
        return 'Дивиденды';
      case 'OPERATION_TYPE_COUPON':
        return 'Купон';
      case 'OPERATION_TYPE_TAX':
        return 'Налог';
      case 'OPERATION_TYPE_SERVICE_FEE':
        return 'Комиссия за обслуживание';
      case 'OPERATION_TYPE_DIVIDEND_TAX':
        return 'Налог на дивиденды';
      default:
        if (operationType.startsWith('OPERATION_TYPE_')) {
          return operationType.substring('OPERATION_TYPE_'.length);
        }
        return operationType;
    }
  }

  String getOperationStateName() {
    switch (state) {
      case 'OPERATION_STATE_UNSPECIFIED':
        return 'Не указано';
      case 'OPERATION_STATE_EXECUTED':
        return 'Исполнена';
      case 'OPERATION_STATE_CANCELED':
        return 'Отменена';
      case 'OPERATION_STATE_PROGRESS':
        return 'В процессе';
      default:
        if (state.startsWith('OPERATION_STATE_')) {
          return state.substring('OPERATION_STATE_'.length);
        }
        return state;
    }
  }

  bool get isPaymentPositive => payment.toDouble() > 0;
  bool get isPaymentNegative => payment.toDouble() < 0;
  double get paymentAmount => payment.toDouble().abs();
}

class OperationTrade {
  final String tradeId;
  final DateTime dateTime;
  final int quantity;
  final MoneyValue price;

  OperationTrade({
    required this.tradeId,
    required this.dateTime,
    required this.quantity,
    required this.price,
  });

  factory OperationTrade.fromJson(Map<String, dynamic> json) {
    int parseLong(dynamic value) {
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

    return OperationTrade(
      tradeId: json['tradeId']?.toString() ?? '',
      dateTime: DateTime.parse(json['dateTime']?.toString() ?? '1970-01-01'),
      quantity: parseLong(json['quantity'] ?? 0),
      price: MoneyValue.fromJson(json['price'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    'dateTime': dateTime.toIso8601String(),
    'quantity': quantity,
    'price': price.toJson(),
  };
}