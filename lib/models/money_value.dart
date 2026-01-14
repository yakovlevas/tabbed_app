class MoneyValue {
  final String currency;
  final Quotation unitsNano;

  MoneyValue({
    required this.currency,
    required this.unitsNano,
  });

  factory MoneyValue.fromJson(Map<String, dynamic> json) {
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

    Map<String, dynamic>? unitsNanoJson;
    if (json['unitsNano'] != null && json['unitsNano'] is Map) {
      unitsNanoJson = Map<String, dynamic>.from(json['unitsNano'] as Map);
    }

    final units = parseLong(
      json['units'] ?? unitsNanoJson?['units'] ?? 0,
    );
    final nano = parseLong(
      json['nano'] ?? unitsNanoJson?['nano'] ?? 0,
    );

    return MoneyValue(
      currency: json['currency']?.toString() ?? '',
      unitsNano: Quotation(units: units, nano: nano),
    );
  }

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'units': unitsNano.units,
    'nano': unitsNano.nano,
  };

  double toDouble() => unitsNano.toDouble();
}

class Quotation {
  final int units;
  final int nano;

  Quotation({required this.units, required this.nano});

  factory Quotation.fromJson(Map<String, dynamic> json) {
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

    return Quotation(
      units: parseLong(json['units'] ?? 0),
      nano: parseLong(json['nano'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'units': units,
    'nano': nano,
  };

  double toDouble() => units + (nano / 1000000000);
}