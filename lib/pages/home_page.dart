import 'package:flutter/material.dart';
import '../services/tinkoff_api_service.dart';
import '../models/operation.dart';
import '../models/portfolio.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _apiTokenController = TextEditingController();
  late TinkoffApiService _apiService;
  bool _isLoading = false;
  String _status = '';
  bool _tokenValid = false;
  List<String> _testResults = [];
  bool _showRawOperations = false;

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  void _loadSavedToken() {
    // Здесь можно добавить логику загрузки токена из secure storage
    // Например, из SharedPreferences или FlutterSecureStorage
  }

  void _addTestResult(String result, bool isSuccess) {
    setState(() {
      _testResults.add('${isSuccess ? '✅' : '❌'} $result');
    });
  }

  void _clearTestResults() {
    setState(() {
      _testResults.clear();
      _status = '';
    });
  }

  Future<void> _validateToken() async {
    if (_apiTokenController.text.isEmpty) {
      setState(() {
        _status = 'Введите API токен';
        _tokenValid = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Проверка токена...';
      _testResults.clear();
    });

    try {
      _apiService = TinkoffApiService(apiToken: _apiTokenController.text);
      
      // Простая проверка токена - запрос информации о пользователе
      final userInfo = await _apiService.getUserInfo();
      
      setState(() {
        _tokenValid = true;
        _status = '✅ Токен валиден!\n\n'
                 'User ID: ${userInfo.userId}\n'
                 'Премиум: ${userInfo.premStatus ? "Да" : "Нет"}\n'
                 'Квалиф. инвестор: ${userInfo.qualStatus ? "Да" : "Нет"}\n'
                 'Тариф: ${userInfo.tariff}';
        _addTestResult('Токен проверен', true);
      });

    } catch (e) {
      setState(() {
        _tokenValid = false;
        _status = '❌ Ошибка проверки токена: $e\n\n'
                 'Проверьте:\n'
                 '1. Токен должен быть из личного кабинета Tinkoff Invest\n'
                 '2. Токен должен быть полным (около 200 символов)\n'
                 '3. Убедитесь, что доступ к API активирован в настройках';
        _addTestResult('Токен невалиден: $e', false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testUserInfo() async {
    if (!_tokenValid) {
      await _validateToken();
      if (!_tokenValid) return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Получение информации о пользователе...';
    });

    try {
      final userInfo = await _apiService.getUserInfo();
      
      setState(() {
        _status = '✅ Информация о пользователе:\n'
                 '• User ID: ${userInfo.userId}\n'
                 '• Премиум статус: ${userInfo.premStatus ? "Да" : "Нет"}\n'
                 '• Квалиф. инвестор: ${userInfo.qualStatus ? "Да" : "Нет"}\n'
                 '• Тариф: ${userInfo.tariff}\n'
                 '• Уровень риска: ${userInfo.riskLevelCode}\n'
                 '• Доступные инструменты: ${userInfo.qualifiedForWorkWith.join(", ")}';
        _addTestResult('Информация о пользователе получена', true);
      });

    } catch (e) {
      setState(() {
        _status = '❌ Ошибка получения информации о пользователе: $e';
        _addTestResult('Ошибка получения информации о пользователе', false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAccounts() async {
    if (!_tokenValid) {
      await _validateToken();
      if (!_tokenValid) return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Получение списка счетов...';
    });

    try {
      final accounts = await _apiService.getAccounts();
      
      String accountsInfo = '✅ Найдено счетов: ${accounts.length}\n';
      for (var i = 0; i < accounts.length; i++) {
        final account = accounts[i];
        accountsInfo += '\n${i + 1}. ${account.name}\n'
                       '   ID: ${account.id}\n'
                       '   Тип: ${account.getDisplayType()}\n'
                       '   Статус: ${account.getDisplayStatus()}\n'
                       '   Открыт: ${account.openedDate.toLocal().toString().substring(0, 10)}';
        if (account.closedDate != null) {
          accountsInfo += '\n   Закрыт: ${account.closedDate!.toLocal().toString().substring(0, 10)}';
        }
      }

      setState(() {
        _status = accountsInfo;
        _addTestResult('Получено счетов: ${accounts.length}', true);
      });

    } catch (e) {
      setState(() {
        _status = '❌ Ошибка получения счетов: $e';
        _addTestResult('Ошибка получения счетов', false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMarketStocks() async {
    if (!_tokenValid) {
      await _validateToken();
      if (!_tokenValid) return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Получение рыночных данных...';
    });

    try {
      final stocks = await _apiService.getMarketStocks(limit: 20);
      
      // Фильтруем российские акции
      final russianStocks = stocks
          .where((s) => s.currency.toLowerCase() == 'rub' && s.ticker.isNotEmpty)
          .toList();

      String marketInfo = '✅ Получено акций: ${stocks.length}\n';
      
      if (russianStocks.isNotEmpty) {
        marketInfo += '\n📊 Примеры российских акций:\n';
        for (var i = 0; i < russianStocks.length && i < 5; i++) {
          final stock = russianStocks[i];
          marketInfo += '${i + 1}. ${stock.name}\n'
                       '   Тикер: ${stock.ticker}\n'
                       '   FIGI: ${stock.figi}\n'
                       '   Лот: ${stock.lot}\n';
        }
      } else {
        marketInfo += '\n📊 Примеры акций:\n';
        for (var i = 0; i < stocks.length && i < 5; i++) {
          final stock = stocks[i];
          marketInfo += '${i + 1}. ${stock.name}\n'
                       '   Тикер: ${stock.ticker}\n'
                       '   Валюта: ${stock.currency}\n'
                       '   FIGI: ${stock.figi}\n';
        }
      }

      setState(() {
        _status = marketInfo;
        _addTestResult('Получено рыночных данных', true);
      });

    } catch (e) {
      setState(() {
        _status = '❌ Ошибка получения рыночных данных: $e';
        _addTestResult('Ошибка получения рыночных данных', false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPortfolio() async {
    if (!_tokenValid) {
      await _validateToken();
      if (!_tokenValid) return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Получение портфеля...';
    });

    try {
      // Сначала получаем счета
      final accounts = await _apiService.getAccounts();
      
      if (accounts.isEmpty) {
        setState(() {
          _status = '⚠️ Нет доступных счетов для проверки портфеля';
          _addTestResult('Нет счетов для портфеля', false);
        });
        return;
      }

      // Берем первый счет
      final firstAccountId = accounts.first.id;
      
      // Получаем портфель с тикерами
      final portfolioData = await _apiService.getPortfolioWithTickers(firstAccountId);
      
      String portfolioInfo = '✅ Портфель получен:\n'
                           '• Всего позиций: ${portfolioData['positionsCount']}\n'
                           '• Общая стоимость: ${(portfolioData['totalValue'] as double).toStringAsFixed(2)} RUB\n'
                           '• Расчетная стоимость: ${(portfolioData['calculatedTotal'] as double).toStringAsFixed(2)} RUB\n';
      
      final positions = portfolioData['positions'] as List<dynamic>;
      if (positions.isNotEmpty) {
        portfolioInfo += '\n📊 Позиции:\n';
        for (var i = 0; i < positions.length && i < 5; i++) {
          final pos = positions[i] as Map<String, dynamic>;
          portfolioInfo += '${i + 1}. ${pos['ticker']} (${pos['instrumentType']})\n'
                         '   Количество: ${(pos['quantity'] as double).toStringAsFixed(2)}\n'
                         '   Цена: ${(pos['price'] as double).toStringAsFixed(2)} ${pos['currency']}\n'
                         '   Стоимость: ${(pos['value'] as double).toStringAsFixed(2)} ${pos['currency']}\n';
        }
        
        if (positions.length > 5) {
          portfolioInfo += '\n... и ещё ${positions.length - 5} позиций';
        }
      }

      setState(() {
        _status = portfolioInfo;
        _addTestResult('Портфель получен', true);
      });

    } catch (e) {
      setState(() {
        _status = '❌ Ошибка получения портфеля: $e';
        _addTestResult('Ошибка получения портфеля', false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testOperations() async {
    if (!_tokenValid) {
      await _validateToken();
      if (!_tokenValid) return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Получение операций...';
    });

    try {
      // Сначала получаем счета
      final accounts = await _apiService.getAccounts();
      
      if (accounts.isEmpty) {
        setState(() {
          _status = '⚠️ Нет доступных счетов для проверки операций';
          _addTestResult('Нет счетов для операций', false);
        });
        return;
      }

      // Берем первый счет
      final firstAccountId = accounts.first.id;
      
      // Операции за последние 30 дней
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));
      
      final operations = await _apiService.getOperations(
        accountId: firstAccountId,
        fromDate: monthAgo,
        toDate: now,
      );

      // Используем упрощенную статистику
      final simpleStats = _getSimpleOperationsStats(operations);
      
      String operationsInfo = '✅ Операции за последние 30 дней:\n'
                            '• Всего операций: ${simpleStats['total']}\n'
                            '• Уникальных инструментов: ${simpleStats['uniqueInstruments']}\n'
                            '• Общий доход: ${(simpleStats['totalPositive'] as double).toStringAsFixed(2)} RUB\n'
                            '• Общий расход: ${(simpleStats['totalNegative'] as double).toStringAsFixed(2)} RUB\n';
      
      final byType = simpleStats['byType'] as Map<String, int>;
      if (byType.isNotEmpty) {
        operationsInfo += '\n📊 Распределение по типам:\n';
        byType.entries.take(5).forEach((entry) {
          operationsInfo += '• ${entry.key}: ${entry.value}\n';
        });
      }

      if (_showRawOperations && operations.isNotEmpty) {
        operationsInfo += '\n📄 Пример операции:\n';
        final firstOp = operations.first;
        final analysis = _apiService.analyzeOperation(firstOp);
        operationsInfo += 'ID: ${firstOp.id}\n'
                        'Тип: ${firstOp.getOperationTypeName()}\n'
                        'Дата: ${firstOp.date}\n'
                        'Сумма: ${firstOp.payment.toDouble().toStringAsFixed(2)} ${firstOp.payment.currency}\n'
                        'FIGI: ${firstOp.figi}\n'
                        'Тикер: ${analysis['ticker']}';
      }

      setState(() {
        _status = operationsInfo;
        _addTestResult('Операций получено: ${operations.length}', true);
      });

    } catch (e) {
      setState(() {
        _status = '❌ Ошибка получения операций: $e';
        _addTestResult('Ошибка получения операций', false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Упрощенная статистика операций
  Map<String, dynamic> _getSimpleOperationsStats(List<Operation> operations) {
    if (operations.isEmpty) {
      return {'total': 0, 'byType': {}, 'totalPositive': 0.0, 'totalNegative': 0.0, 'uniqueInstruments': 0};
    }
    
    final byType = <String, int>{};
    double totalPositive = 0;
    double totalNegative = 0;
    final uniqueFigis = <String>{};
    
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
    }
    
    return {
      'total': operations.length,
      'byType': byType,
      'totalPositive': totalPositive,
      'totalNegative': totalNegative,
      'uniqueInstruments': uniqueFigis.length,
    };
  }

  Future<void> _runAllTests() async {
    _clearTestResults();
    
    if (!_tokenValid) {
      await _validateToken();
      if (!_tokenValid) return;
    }

    // Запускаем тесты последовательно
    await _testUserInfo();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testAccounts();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testMarketStocks();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testPortfolio();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testOperations();

    setState(() {
      _status = '✅ Все тесты завершены!\n\n'
               'Результаты:\n${_testResults.join('\n')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinkoff API Тестер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Где взять API токен?'),
                  content: const Text(
                    '1. Откройте приложение Tinkoff Invest\n'
                    '2. Перейдите в Настройки → Работа с API\n'
                    '3. Создайте новый токен\n'
                    '4. Скопируйте токен и вставьте здесь\n\n'
                    'Токен должен начинаться с "t." и содержать около 200 символов.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Настройки'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwitchListTile(
                            title: const Text('Показывать сырые данные операций'),
                            value: _showRawOperations,
                            onChanged: (value) {
                              setState(() => _showRawOperations = value);
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _apiTokenController,
                    decoration: InputDecoration(
                      labelText: 'API Токен Tinkoff Invest',
                      border: const OutlineInputBorder(),
                      hintText: 'Введите токен (начинается с "t.")',
                      suffixIcon: _tokenValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      if (value.length > 10) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                if (_apiTokenController.text.isNotEmpty)
                  Text(
                    '${_apiTokenController.text.length}',
                    style: TextStyle(
                      color: _apiTokenController.text.length < 100
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _apiTokenController.text.isEmpty
                  ? 'Введите токен'
                  : 'Длина токена: ${_apiTokenController.text.length} символов',
              style: TextStyle(
                color: _apiTokenController.text.isEmpty
                    ? Colors.red
                    : _apiTokenController.text.length < 100
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _validateToken,
                  icon: const Icon(Icons.vpn_key, size: 16),
                  label: const Text('Проверить токен'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_tokenValid ? null : _testUserInfo,
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Инфо'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_tokenValid ? null : _testAccounts,
                  icon: const Icon(Icons.account_balance, size: 16),
                  label: const Text('Счета'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_tokenValid ? null : _testMarketStocks,
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: const Text('Акции'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_tokenValid ? null : _testPortfolio,
                  icon: const Icon(Icons.pie_chart, size: 16),
                  label: const Text('Портфель'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_tokenValid ? null : _testOperations,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Операции'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_tokenValid ? null : _runAllTests,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Все тесты'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_testResults.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Результаты тестов:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ..._testResults.map((result) => Text(
                          result,
                          style: TextStyle(
                            color: result.startsWith('✅') ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        )),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: _clearTestResults,
                      child: const Text('Очистить результаты'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiTokenController.dispose();
    super.dispose();
  }
}