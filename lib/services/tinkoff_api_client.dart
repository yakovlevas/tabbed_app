import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../exceptions/tinkoff_api_exception.dart';
import '../models/instrument_by_response.dart';

class TinkoffApiClient {
  static const String _baseUrl = 'https://invest-public-api.tinkoff.ru/rest/';
  final String _apiToken;
  final Map<String, String> _figiToTickerCache = {};
  late final http.Client _client; // Используем late final вместо final

  TinkoffApiClient({required String apiToken}) : _apiToken = apiToken {
    // Инициализируем клиент в теле конструктора
    _client = http.Client();
  }

  Future<Map<String, dynamic>> _sendRequest(
    String method,
    Map<String, dynamic> request,
  ) async {
    final url = Uri.parse('$_baseUrl$method');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
      'User-Agent': 'TinkoffApiTester/1.0',
    };

    // Форматируем JSON без пробелов для совместимости
    final body = jsonEncode(request);
    
    print('[API Request] $method');
    print('[Request Body] $body');

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('[Response Status] ${response.statusCode}');
      print('[Response Length] ${response.body.length} chars');

      // Сохраняем сырой ответ для отладки
      _saveResponseToFile(method, response.body);

      if (response.statusCode != 200) {
        _handleErrorResponse(response);
      }

      final responseJson = jsonDecode(response.body);
      return responseJson;
    } on http.ClientException catch (e) {
      throw TinkoffApiException(
        code: 'NETWORK_ERROR',
        message: 'Ошибка сети: ${e.message}',
        description: 'Проверьте подключение к интернету',
      );
    } on TimeoutException {
      throw TinkoffApiException(
        code: 'TIMEOUT',
        message: 'Таймаут запроса',
        description: 'Сервер не ответил за 30 секунд',
      );
    } on FormatException catch (e) {
      throw TinkoffApiException(
        code: 'JSON_PARSE_ERROR',
        message: 'Ошибка парсинга JSON',
        description: e.message,
      );
    } catch (e) {
      throw TinkoffApiException(
        code: 'UNKNOWN_ERROR',
        message: 'Неизвестная ошибка: $e',
        description: 'Произошла непредвиденная ошибка',
      );
    }
  }

  void _handleErrorResponse(http.Response response) {
    try {
      final errorJson = jsonDecode(response.body);
      final code = errorJson['code']?.toString() ?? 'UNKNOWN_ERROR';
      final message = errorJson['message']?.toString() ?? 'No error message';
      final description = errorJson['description']?.toString() ?? '';

      String errorMessage;
      switch (code) {
        case '3':
          errorMessage = 'Неверный токен авторизации';
          break;
        case '5':
          errorMessage = 'Доступ запрещен';
          break;
        case '7':
          errorMessage = 'Недостаточно прав';
          break;
        case '8':
          errorMessage = 'Некорректный запрос';
          break;
        case '13':
          errorMessage = 'Внутренняя ошибка сервера';
          break;
        case '15001':
          errorMessage = 'Превышен лимит запросов';
          break;
        default:
          errorMessage = 'Код ошибки: $code';
      }

      throw TinkoffApiException(
        code: code,
        message: '$errorMessage: $message',
        description: description,
      );
    } catch (e) {
      // Если не удалось распарсить JSON с ошибкой
      throw TinkoffApiException(
        code: 'HTTP_${response.statusCode}',
        message: response.body.isNotEmpty ? response.body : 'Empty response',
        description: 'Failed to parse error response: $e',
      );
    }
  }

  void _saveResponseToFile(String method, String responseBody) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final methodName = method.split('/').last;
      final filename = 'response_${methodName}_$timestamp.json';
      final file = File(filename);
      file.writeAsStringSync(responseBody);
      print('[Debug] Raw response saved to: $filename');
    } catch (e) {
      print('[Debug] Could not save response: $e');
    }
  }

  // Обертка для вызова API
  Future<Map<String, dynamic>> callApi(
    String method,
    Map<String, dynamic> request,
  ) async {
    return await _sendRequest(method, request);
  }

  // Получение тикера по FIGI
  Future<String> getTickerForFigi(String figi) async {
    if (figi.isEmpty) return '';

    // Проверяем кэш
    if (_figiToTickerCache.containsKey(figi)) {
      return _figiToTickerCache[figi]!;
    }

    try {
      final request = {
        'idType': 'INSTRUMENT_ID_TYPE_FIGI',
        'classCode': '',
        'id': figi,
      };

      final response = await _sendRequest(
        'tinkoff.public.invest.api.contract.v1.InstrumentsService/GetInstrumentBy',
        request,
      );

      final instrumentResponse = InstrumentByResponse.fromJson(response);
      final ticker = instrumentResponse.instrument.ticker;

      if (ticker.isNotEmpty) {
        _figiToTickerCache[figi] = ticker;
        return ticker;
      }
    } catch (e) {
      print('⚠️ Ошибка получения тикера для $figi: $e');
    }

    return '';
  }

  // Получение тикеров для нескольких FIGI
  Future<Map<String, String>> getTickersForFigis(List<String> figis) async {
    if (figis.isEmpty) return {};

    print('🔄 Получение тикеров для ${figis.length} инструментов...');

    final results = <String, String>{};
    int successCount = 0;

    for (final figi in figis) {
      if (figi.isEmpty || results.containsKey(figi)) continue;

      try {
        final ticker = await getTickerForFigi(figi);
        if (ticker.isNotEmpty) {
          results[figi] = ticker;
          successCount++;
          print('  ✅ $figi -> $ticker');
        } else {
          print('  ⚠️ Для FIGI $figi тикер не найден');
        }
      } catch (e) {
        print('  ⚠️ Ошибка получения тикера для $figi: $e');
      }

      // Небольшая задержка, чтобы не нагружать API
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Получено тикеров: $successCount/${figis.length}');
    return results;
  }

  // Получение информации об инструменте по FIGI
  Future<InstrumentByResponse> getInstrumentByFigi(String figi) async {
    final request = {
      'idType': 'INSTRUMENT_ID_TYPE_FIGI',
      'classCode': '',
      'id': figi,
    };

    final response = await _sendRequest(
      'tinkoff.public.invest.api.contract.v1.InstrumentsService/GetInstrumentBy',
      request,
    );

    return InstrumentByResponse.fromJson(response);
  }

  // Очистка кэша тикеров
  void clearTickerCache() {
    _figiToTickerCache.clear();
    print('🧹 Кэш тикеров очищен');
  }

  // Получение статистики кэша
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedTickers': _figiToTickerCache.length,
      'cacheKeys': _figiToTickerCache.keys.toList(),
    };
  }

  void dispose() {
    _client.close();
    print('🔌 HTTP клиент закрыт');
  }
}