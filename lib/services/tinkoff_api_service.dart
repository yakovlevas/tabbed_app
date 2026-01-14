import 'dart:convert';
import '../models/user_info.dart';
import '../models/account.dart';
import '../models/stock_instrument.dart';
import '../models/portfolio.dart';
import '../models/operation.dart';
import '../models/instrument_by_response.dart';
import 'tinkoff_api_client.dart';

class TinkoffApiService {
  final TinkoffApiClient _client;
  final Map<String, String> _figiToTickerCache = {};

  TinkoffApiService({required String apiToken})
      : _client = TinkoffApiClient(apiToken: apiToken);

  // === ОСНОВНЫЕ МЕТОДЫ API ===

  // 1. Информация о пользователе
  Future<UserInfo> getUserInfo() async {
    final response = await _client.callApi(
      'tinkoff.public.invest.api.contract.v1.UsersService/GetInfo',
      {},
    );
    return UserInfo.fromJson(response);
  }

  // 2. Счета пользователя
  Future<List<Account>> getAccounts() async {
    final response = await _client.callApi(
      'tinkoff.public.invest.api.contract.v1.UsersService/GetAccounts',
      {},
    );

    final accounts = response['accounts'] as List? ?? [];
    return accounts.map((json) => Account.fromJson(json)).toList();
  }

  // 3. Рыночные данные (акции)
  Future<List<StockInstrument>> getMarketStocks({
    String instrumentStatus = 'INSTRUMENT_STATUS_ALL',
    String currency = '',
    int limit = 100,
  }) async {
    final request = {
      'instrumentStatus': instrumentStatus,
    };

    if (currency.isNotEmpty) {
      request['currency'] = currency;
    }

    final response = await _client.callApi(
      'tinkoff.public.invest.api.contract.v1.InstrumentsService/Shares',
      request,
    );

    final instruments = response['instruments'] as List? ?? [];
    var result = instruments.map((json) => StockInstrument.fromJson(json)).toList();

    // Фильтрация и ограничение
    if (currency.isNotEmpty) {
      result = result.where((i) => i.currency.toLowerCase() == currency.toLowerCase()).toList();
    }

    if (limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  // 4. Портфель
  Future<Portfolio> getPortfolio(String accountId, {String currency = 'RUB'}) async {
    final response = await _client.callApi(
      'tinkoff.public.invest.api.contract.v1.OperationsService/GetPortfolio',
      {
        'accountId': accountId,
        'currency': currency,
      },
    );
    return Portfolio.fromJson(response);
  }

  // 5. Операции
  Future<List<Operation>> getOperations({
    required String accountId,
    required DateTime fromDate,
    required DateTime toDate,
    String state = 'OPERATION_STATE_EXECUTED',
  }) async {
    final response = await _client.callApi(
      'tinkoff.public.invest.api.contract.v1.OperationsService/GetOperations',
      {
        'accountId': accountId,
        'from': _formatDateForApi(fromDate),
        'to': _formatDateForApi(toDate),
        'state': state,
      },
    );

    final operations = response['operations'] as List? ?? [];
    final result = operations.map((json) => Operation.fromJson(json)).toList();

    // Получаем тикеры для всех уникальных FIGI
    await _cacheTickersForOperations(result);

    return result;
  }

  // 6. История операций с пагинацией
  Future<List<Operation>> getOperationsWithPagination({
    required String accountId,
    required DateTime fromDate,
    required DateTime toDate,
    int pageSize = 100,
  }) async {
    final allOperations = <Operation>[];
    DateTime currentFrom = fromDate;
    
    while (currentFrom.isBefore(toDate)) {
      final currentTo = currentFrom.add(const Duration(days: 30));
      final endDate = currentTo.isAfter(toDate) ? toDate : currentTo;

      try {
        final batch = await getOperations(
          accountId: accountId,
          fromDate: currentFrom,
          toDate: endDate,
        );
        
        allOperations.addAll(batch);
        
        if (batch.length < pageSize) {
          break;
        }
        
        currentFrom = endDate;
        await Future.delayed(const Duration(milliseconds: 500)); // Задержка между запросами
      } catch (e) {
        print('Ошибка при получении операций с $currentFrom по $endDate: $e');
        break;
      }
    }

    return allOperations;
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  // Форматирование даты для API
  String _formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  // Кэширование тикеров для операций
  Future<void> _cacheTickersForOperations(List<Operation> operations) async {
    final uniqueFigis = operations
        .where((op) => op.figi.isNotEmpty)
        .map((op) => op.figi)
        .toSet()
        .toList();

    if (uniqueFigis.isNotEmpty) {
      final tickers = await _client.getTickersForFigis(uniqueFigis);
      _figiToTickerCache.addAll(tickers);
    }
  }

  // Получение тикера по FIGI (с кэшированием)
  Future<String> getTickerForFigi(String figi) async {
    if (_figiToTickerCache.containsKey(figi)) {
      return _figiToTickerCache[figi]!;
    }

    final ticker = await _client.getTickerForFigi(figi);
    if (ticker.isNotEmpty) {
      _figiToTickerCache[figi] = ticker;
    }
    return ticker;
  }

  // Получение информации об инструменте
  Future<InstrumentByResponse> getInstrumentByFigi(String figi) async {
    return await _client.getInstrumentByFigi(figi);
  }

  // === АНАЛИТИЧЕСКИЕ МЕТОДЫ ===

  // Анализ операции
  Map<String, dynamic> analyzeOperation(Operation operation) {
    final paymentValue = operation.payment.toDouble();
    final priceValue = operation.price.toDouble();

    final issues = <String>[];

    // Проверка логики операции
    switch (operation.operationType) {
      case 'OPERATION_TYPE_BUY':
        if (paymentValue >= 0) {
          issues.add('Для покупки ожидается отрицательный платеж');
        }
        if (operation.figi.isEmpty) {
          issues.add('Отсутствует FIGI инструмента');
        }
        break;

      case 'OPERATION_TYPE_SELL':
        if (paymentValue <= 0) {
          issues.add('Для продажи ожидается положительный платеж');
        }
        if (operation.figi.isEmpty) {
          issues.add('Отсутствует FIGI инструмента');
        }
        break;

      case 'OPERATION_TYPE_INPUT':
        if (paymentValue <= 0) {
          issues.add('Для пополнения ожидается положительный платеж');
        }
        break;

      case 'OPERATION_TYPE_OUTPUT':
        if (paymentValue >= 0) {
          issues.add('Для вывода ожидается отрицательный платеж');
        }
        break;
    }

    // Расчетные поля
    double? calculatedTotal;
    if (operation.quantity != 0 && priceValue != 0) {
      calculatedTotal = operation.quantity * priceValue;
    }

    return {
      'id': operation.id,
      'type': operation.getOperationTypeName(),
      'state': operation.getOperationStateName(),
      'date': operation.date,
      'figi': operation.figi,
      'payment': {
        'amount': paymentValue,
        'currency': operation.payment.currency,
        'isPositive': paymentValue > 0,
        'isNegative': paymentValue < 0,
      },
      'price': {
        'amount': priceValue,
        'currency': operation.price.currency,
      },
      'quantity': operation.quantity,
      'quantityRest': operation.quantityRest,
      'ticker': _figiToTickerCache[operation.figi] ?? '',
      'calculatedTotal': calculatedTotal,
      'issues': issues,
      'hasIssues': issues.isNotEmpty,
      'tradesCount': operation.trades.length,
      'commissions': operation.commission.map((c) => c.toDouble()).toList(),
    };
  }

  // Получение портфеля с тикерами
  Future<Map<String, dynamic>> getPortfolioWithTickers(String accountId) async {
    final portfolio = await getPortfolio(accountId);
    
    final positionsWithTickers = <Map<String, dynamic>>[];
    double totalValue = 0;

    for (final position in portfolio.positions) {
      final ticker = await getTickerForFigi(position.figi);
      final positionValue = position.getPositionValue();
      totalValue += positionValue;

      positionsWithTickers.add({
        'figi': position.figi,
        'ticker': ticker.isNotEmpty ? ticker : position.figi,
        'instrumentType': position.getInstrumentTypeName(),
        'quantity': position.quantity.toDouble(),
        'price': position.currentPrice.toDouble(),
        'value': positionValue,
        'currency': position.currentPrice.currency,
      });
    }

    return {
      'totalValue': portfolio.getTotalValue(),
      'calculatedTotal': totalValue,
      'positionsCount': portfolio.positions.length,
      'positions': positionsWithTickers,
      'summary': {
        'byType': _groupPositionsByType(positionsWithTickers),
        'byCurrency': _groupPositionsByCurrency(positionsWithTickers),
      },
    };
  }

  Map<String, dynamic> _groupPositionsByType(List<Map<String, dynamic>> positions) {
    final result = <String, double>{};
    for (final pos in positions) {
      final type = pos['instrumentType'] as String;
      result[type] = (result[type] ?? 0) + (pos['value'] as double);
    }
    return result;
  }

  Map<String, dynamic> _groupPositionsByCurrency(List<Map<String, dynamic>> positions) {
    final result = <String, double>{};
    for (final pos in positions) {
      final currency = pos['currency'] as String;
      result[currency] = (result[currency] ?? 0) + (pos['value'] as double);
    }
    return result;
  }

  // Упрощенная статистика операций (безопасная версия)
  Map<String, dynamic> getSimpleOperationsStats(List<Operation> operations) {
    if (operations.isEmpty) {
      return {
        'total': 0,
        'byType': <String, int>{},
        'totalPositive': 0.0,
        'totalNegative': 0.0,
        'uniqueInstruments': 0,
      };
    }

    final byType = <String, int>{};
    double totalPositive = 0.0;
    double totalNegative = 0.0;
    final uniqueFigis = <String>{};

    DateTime minDate = operations.first.date;
    DateTime maxDate = operations.first.date;

    for (final op in operations) {
      final type = op.getOperationTypeName();
      byType[type] = (byType[type] ?? 0) + 1;

      final payment = op.payment.toDouble();
      if (payment > 0) {
        totalPositive += payment;
      } else {
        totalNegative += payment.abs();
      }

      if (op.figi.isNotEmpty) {
        uniqueFigis.add(op.figi);
      }

      if (op.date.isBefore(minDate)) minDate = op.date;
      if (op.date.isAfter(maxDate)) maxDate = op.date;
    }

    return {
      'total': operations.length,
      'byType': byType,
      'totalPositive': totalPositive,
      'totalNegative': totalNegative,
      'uniqueInstruments': uniqueFigis.length,
      'period': {
        'from': minDate,
        'to': maxDate,
        'days': maxDate.difference(minDate).inDays + 1,
      },
    };
  }

  // Проверка доступности API
  Future<bool> checkApiAvailability() async {
    try {
      await getUserInfo();
      return true;
    } catch (e) {
      print('API недоступен: $e');
      return false;
    }
  }

  // Получение информации о кэше
  Map<String, dynamic> getCacheInfo() {
    return {
      'tickerCacheSize': _figiToTickerCache.length,
      'cachedFigis': _figiToTickerCache.keys.toList(),
      'clientCacheStats': _client.getCacheStats(),
    };
  }

  // Очистка кэша
  void clearCache() {
    _figiToTickerCache.clear();
    _client.clearTickerCache();
    print('🧹 Все кэши очищены');
  }

  void dispose() {
    _client.dispose();
    print('🔌 TinkoffApiService завершен');
  }
}