// lib/services/tinkoff_api_service.dart
import 'dart:convert';
import '../models/user_info.dart';
import '../models/account.dart';
import '../models/stock_instrument.dart';
import '../models/portfolio.dart';
import '../models/operation.dart';
import '../models/instrument_by_response.dart';
import '../models/money_value.dart';
import '../models/candle_interval.dart';
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
    var result =
        instruments.map((json) => StockInstrument.fromJson(json)).toList();

    // Фильтрация и ограничение
    if (currency.isNotEmpty) {
      result = result
          .where((i) => i.currency.toLowerCase() == currency.toLowerCase())
          .toList();
    }

    if (limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  // 4. Портфель
  Future<Portfolio> getPortfolio(String accountId,
      {String currency = 'RUB'}) async {
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
    final result =
        operations.map((json) => Operation.fromJson(json)).toList();

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
        await Future.delayed(
            const Duration(milliseconds: 500)); // Задержка между запросами
      } catch (e) {
        print(
            'Ошибка при получении операций с $currentFrom по $endDate: $e');
        break;
      }
    }

    return allOperations;
  }

  // 7. Получение исторических данных (свечей) - ИСПРАВЛЕННЫЙ МЕТОД
  Future<List<Map<String, dynamic>>> getCandles({
    required String ticker,
    required DateTime from,
    required DateTime to,
    required CandleInterval interval,
  }) async {
    // Проверяем валидность периода для выбранного интервала
    if (!interval.isValidPeriod(from, to)) {
      final recommendedInterval = CandleIntervalHelper.getRecommendedInterval(from, to);
      print('⚠️ Период невалиден для интервала ${interval.displayName}. '
          'Рекомендуемый интервал: ${recommendedInterval.displayName}');
      
      // Автоматически подбираем подходящий интервал
      return await getCandles(
        ticker: ticker,
        from: from,
        to: to,
        interval: recommendedInterval,
      );
    }

    // Формируем instrumentId на основе тикера
    String instrumentId = _formatInstrumentId(ticker);

    // ИСПРАВЛЕНИЕ: правильное формирование запроса
    final request = {
      'from': _formatDateForApi(from),
      'to': _formatDateForApi(to),
      'interval': _formatIntervalForApi(interval),
      'instrumentId': instrumentId,
      'candleSourceType': 'CANDLE_SOURCE_UNSPECIFIED',
      'limit': '2400', // ВАЖНО: строка, а не число!
    };

    print('📊 Запрос свечей для: $instrumentId');
    print('📅 Период: ${from.toLocal()} - ${to.toLocal()}');
    print('⏱️ Интервал: ${interval.displayName}');
    print('📝 Request: $request');

    try {
      final response = await _client.callApi(
        'tinkoff.public.invest.api.contract.v1.MarketDataService/GetCandles',
        request,
      );

      final candles = response['candles'] as List? ?? [];

      // Преобразуем свечи в удобный формат
      final List<Map<String, dynamic>> formattedCandles = [];

      for (final candle in candles) {
        try {
          final parsedCandle = _parseCandle(candle as Map<String, dynamic>);
          formattedCandles.add(parsedCandle);
        } catch (e) {
          print('⚠️ Пропускаем свечу из-за ошибки парсинга: $e');
        }
      }

      print('✅ Получено свечей: ${formattedCandles.length}');

      // Если есть свечи, выводим информацию о первой для отладки
      if (formattedCandles.isNotEmpty) {
        print('📊 Первая свеча: ${formattedCandles.first}');
      }

      // Ограничиваем количество свечей (максимум 500 по API)
      if (formattedCandles.length > 500) {
        print('⚠️ Получено ${formattedCandles.length} свечей. Обрезаем до 500.');
        return formattedCandles.take(500).toList();
      }

      return formattedCandles;
    } catch (e) {
      // Если ошибка, пробуем альтернативный формат instrumentId
      print('❌ Ошибка при запросе свечей: $e');
      print('🔄 Пробуем альтернативный формат instrumentId...');
      
      return await _getCandlesWithAlternativeFormats(ticker, from, to, interval);
    }
  }

  // Метод для парсинга одной свечи
  Map<String, dynamic> _parseCandle(Map<String, dynamic> candleData) {
    try {
      final time = DateTime.parse(candleData['time'] as String);
      final open = MoneyValue.fromJson(candleData['open'] ?? {}).toDouble();
      final high = MoneyValue.fromJson(candleData['high'] ?? {}).toDouble();
      final low = MoneyValue.fromJson(candleData['low'] ?? {}).toDouble();
      final close = MoneyValue.fromJson(candleData['close'] ?? {}).toDouble();
      
      // Обработка volume (может быть string или int)
      final volumeDynamic = candleData['volume'];
      int volume;
      if (volumeDynamic is String) {
        volume = int.tryParse(volumeDynamic) ?? 0;
      } else if (volumeDynamic is int) {
        volume = volumeDynamic;
      } else if (volumeDynamic is double) {
        volume = volumeDynamic.toInt();
      } else {
        volume = 0;
      }

      return {
        'time': time.toIso8601String(),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
        'isComplete': candleData['isComplete'] as bool? ?? true,
      };
    } catch (e, stackTrace) {
      print('⚠️ Ошибка парсинга свечи: $e');
      print('⚠️ Stack trace: $stackTrace');
      print('⚠️ Данные свечи: $candleData');
      rethrow;
    }
  }

  // Метод для проб разных форматов instrumentId
  Future<List<Map<String, dynamic>>> _getCandlesWithAlternativeFormats(
    String ticker,
    DateTime from,
    DateTime to,
    CandleInterval interval,
  ) async {
    // Пробуем разные форматы instrumentId
    final List<String> alternativeFormats = [
      _formatInstrumentId(ticker), // Первоначальный формат
      '${ticker}_TQBR',  // Российские акции (Московская биржа)
      '${ticker}_SPBXM', // Иностранные акции (СПБ биржа)
      '${ticker}_MOEX',  // Московская биржа (альтернативный формат)
      '${ticker}_TQTF',  // ETF на Московской бирже
      '${ticker}_TQOB',  // Облигации на Московской бирже
      '${ticker}_TQTE',  // Иностранные ценные бумаги
      ticker,            // Просто тикер без суффикса
    ];

    for (final format in alternativeFormats) {
      try {
        print('🔄 Пробуем формат: $format');
        
        final request = {
          'from': _formatDateForApi(from),
          'to': _formatDateForApi(to),
          'interval': _formatIntervalForApi(interval),
          'instrumentId': format,
          'candleSourceType': 'CANDLE_SOURCE_UNSPECIFIED',
          'limit': '2400',
        };

        final response = await _client.callApi(
          'tinkoff.public.invest.api.contract.v1.MarketDataService/GetCandles',
          request,
        );

        final candles = response['candles'] as List? ?? [];
        
        if (candles.isNotEmpty) {
          // Преобразуем свечи в удобный формат
          final List<Map<String, dynamic>> formattedCandles = [];

          for (final candle in candles) {
            try {
              final parsedCandle = _parseCandle(candle as Map<String, dynamic>);
              formattedCandles.add(parsedCandle);
            } catch (e) {
              print('⚠️ Пропускаем свечу из-за ошибки парсинга: $e');
            }
          }

          if (formattedCandles.isNotEmpty) {
            print('✅ Успех с форматом: $format (свечей: ${formattedCandles.length})');
            return formattedCandles;
          }
        }
      } catch (e) {
        print('⚠️ Формат $format не сработал: $e');
        continue;
      }
    }

    print('❌ Ни один формат instrumentId не сработал для тикера: $ticker');
    throw Exception('Не удалось получить данные для тикера $ticker');
  }

  // 8. Получение последней цены по FIGI
  Future<double> getLastPrice(String figi) async {
    final request = {
      'figi': figi,
    };

    final response = await _client.callApi(
      'tinkoff.public.invest.api.contract.v1.MarketDataService/GetLastPrices',
      request,
    );

    final lastPrices = response['lastPrices'] as List? ?? [];
    if (lastPrices.isNotEmpty) {
      final lastPrice = lastPrices.first;
      final priceValue = MoneyValue.fromJson(lastPrice['price'] ?? {});
      return priceValue.toDouble();
    }

    return 0.0;
  }

  // 9. Получение информации об инструменте
  Future<Map<String, dynamic>> getInstrumentInfo(String figi) async {
    try {
      final request = {
        'idType': 'INSTRUMENT_ID_TYPE_FIGI',
        'classCode': '',
        'id': figi,
      };

      final response = await _client.callApi(
        'tinkoff.public.invest.api.contract.v1.InstrumentsService/GetInstrumentBy',
        request,
      );

      final instrument = response['instrument'] as Map<String, dynamic>? ?? {};

      // Возвращаем основные поля инструмента
      return {
        'figi': instrument['figi'] ?? '',
        'ticker': instrument['ticker'] ?? '',
        'name': instrument['name'] ?? '',
        'currency': instrument['currency'] ?? '',
        'lot': instrument['lot'] ?? 1,
        'type': instrument['instrumentType'] ?? '',
        'classCode': instrument['classCode'] ?? '',
      };
    } catch (e) {
      print('Ошибка получения информации об инструменте $figi: $e');
      return {};
    }
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  // Форматирование даты для API
  String _formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  // Форматирование instrumentId из тикера
  String _formatInstrumentId(String ticker) {
    // Убираем лишние пробелы и приводим к верхнему регистру
    final cleanTicker = ticker.trim().toUpperCase();
    
    // Если уже содержит суффикс биржи, возвращаем как есть
    if (cleanTicker.contains('_')) {
      return cleanTicker;
    }
    
    // По умолчанию для российских тикеров используем TQBR
    return '${cleanTicker}_TQBR';
  }

  // Форматирование интервала для API
  String _formatIntervalForApi(CandleInterval interval) {
    // Используем value из enum, если он правильный
    final value = interval.value;
    
    // Проверяем, соответствует ли value формату API
    if (value.startsWith('CANDLE_INTERVAL_')) {
      return value;
    }
    
    // Если value не в правильном формате, конвертируем
    switch (interval) {
      case CandleInterval.day:
        return 'CANDLE_INTERVAL_DAY';
      case CandleInterval.hour:
        return 'CANDLE_INTERVAL_HOUR';
      case CandleInterval.minute1:
        return 'CANDLE_INTERVAL_1_MIN';
      case CandleInterval.minute5:
        return 'CANDLE_INTERVAL_5_MIN';
      case CandleInterval.minute15:
        return 'CANDLE_INTERVAL_15_MIN';
      case CandleInterval.minute30:
        return 'CANDLE_INTERVAL_30_MIN';
      default:
        return 'CANDLE_INTERVAL_DAY';
    }
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

  // Получение информации об инструменте (через клиент)
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
  Future<Map<String, dynamic>> getPortfolioWithTickers(
      String accountId) async {
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

  Map<String, dynamic> _groupPositionsByType(
      List<Map<String, dynamic>> positions) {
    final result = <String, double>{};
    for (final pos in positions) {
      final type = pos['instrumentType'] as String;
      result[type] = (result[type] ?? 0) + (pos['value'] as double);
    }
    return result;
  }

  Map<String, dynamic> _groupPositionsByCurrency(
      List<Map<String, dynamic>> positions) {
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