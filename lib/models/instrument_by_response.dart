import 'stock_instrument.dart';

class InstrumentByResponse {
  final StockInstrument instrument;

  InstrumentByResponse({required this.instrument});

  factory InstrumentByResponse.fromJson(Map<String, dynamic> json) {
    return InstrumentByResponse(
      instrument: StockInstrument.fromJson(json['instrument'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'instrument': instrument.toJson(),
  };
}