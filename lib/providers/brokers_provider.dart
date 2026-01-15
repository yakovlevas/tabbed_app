
// lib/providers/brokers_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/broker.dart';
import '../services/tinkoff_api_service.dart';
import '../models/portfolio.dart';
import '../models/account.dart';

class BrokersProvider extends ChangeNotifier {
  final List<Broker> _brokers = [
    Broker(
      id: 'tinkoff',
      name: 'Тинькофф Инвестиции',
      description: 'Брокер от Тинькофф Банка',
      primaryColor: const Color(0xFF0066FF),
      secondaryColor: const Color(0xFF0066FF).withOpacity(0.1),
      isEnabled: false,
      isConnected: false,
      apiKey: '',
      savedApiKey: '',
      connectionInfo: {},
      lastConnection: null,
      isSaved: false,
    ),
    Broker(
      id: 'bcs',
      name: 'БКС Брокер',
      description: 'Крупнейший российский брокер',
      primaryColor: const Color(0xFF00A86B),
      secondaryColor: const Color(0xFF00A86B).withOpacity(0.1),
      isEnabled: false,
      isConnected: false,
      apiKey: '',
      savedApiKey: '',
      connectionInfo: {},
      lastConnection: null,
      isSaved: false,
    ),
    Broker(
      id: 'finam',
      name: 'Финам',
      description: 'Один из старейших брокеров',
      primaryColor: const Color(0xFF0D47A1),
      secondaryColor: const Color(0xFF0D47A1).withOpacity(0.1),
      isEnabled: false,
      isConnected: false,
      apiKey: '',
      savedApiKey: '',
      connectionInfo: {},
      lastConnection: null,
      isSaved: false,
    ),
  ];

  // Данные для Tinkoff
  Portfolio? _tinkoffPortfolio;
  List<Account> _tinkoffAccounts = [];
  bool _isLoadingPortfolio = false;
  String? _portfolioError;
  TinkoffApiService? _tinkoffApiService;
  
  // Ключи для SharedPreferences
  static const String _prefsKey = 'brokers_data';
  static const String _tinkoffKey = 'tinkoff_api_key';
  static const String _bcsKey = 'bcs_api_key';
  static const String _finamKey = 'finam_api_key';

  List<Broker> get brokers => _brokers;
  List<Broker> get connectedBrokers => _brokers.where((b) => b.isConnected).toList();
  Portfolio? get tinkoffPortfolio => _tinkoffPortfolio;
  List<Account> get tinkoffAccounts => _tinkoffAccounts;
  bool get isLoadingPortfolio => _isLoadingPortfolio;
  String? get portfolioError => _portfolioError;

  BrokersProvider() {
    _loadSavedData();
  }

  // Итоговая стоимость портфеля
  double get totalPortfolioValue {
    double total = 0.0;
    
    if (_tinkoffPortfolio != null) {
      total += _tinkoffPortfolio!.getTotalValue();
    }
    
    return total;
  }

  // Распределение по брокерам
  Map<String, double> get portfolioByBroker {
    final Map<String, double> result = {};
    
    if (_tinkoffPortfolio != null) {
      result['tinkoff'] = _tinkoffPortfolio!.getTotalValue();
    }
    
    return result;
  }

  // === СОХРАНЕНИЕ ДАННЫХ ===

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Загружаем сохраненные ключи для каждого брокера
      for (int i = 0; i < _brokers.length; i++) {
        final broker = _brokers[i];
        final savedKey = prefs.getString(_getPrefsKeyForBroker(broker.id));
        
        if (savedKey != null && savedKey.isNotEmpty) {
          _brokers[i] = broker.copyWith(
            savedApiKey: savedKey,
            apiKey: savedKey,
            isSaved: true,
            isEnabled: true,
          );
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки сохраненных данных: $e');
    }
  }

  String _getPrefsKeyForBroker(String brokerId) {
    switch (brokerId) {
      case 'tinkoff': return _tinkoffKey;
      case 'bcs': return _bcsKey;
      case 'finam': return _finamKey;
      default: return '${brokerId}_api_key';
    }
  }

  // Сохранение API ключа брокера
  Future<void> saveBrokerApiKey(String brokerId, String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefsKeyForBroker(brokerId);
      
      await prefs.setString(key, apiKey);
      
      // Обновляем состояние брокера
      final index = _brokers.indexWhere((b) => b.id == brokerId);
      if (index != -1) {
        _brokers[index] = _brokers[index].copyWith(
          savedApiKey: apiKey,
          apiKey: apiKey,
          isSaved: true,
        );
        
        notifyListeners();
        print('✅ Ключ для брокера $brokerId сохранен');
      }
    } catch (e) {
      print('Ошибка сохранения ключа брокера $brokerId: $e');
      rethrow;
    }
  }

  // Удаление сохраненного ключа
  Future<void> removeSavedApiKey(String brokerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefsKeyForBroker(brokerId);
      
      await prefs.remove(key);
      
      final index = _brokers.indexWhere((b) => b.id == brokerId);
      if (index != -1) {
        _brokers[index] = _brokers[index].copyWith(
          savedApiKey: '',
          isSaved: false,
        );
        
        notifyListeners();
        print('🗑️ Ключ для брокера $brokerId удален');
      }
    } catch (e) {
      print('Ошибка удаления ключа брокера $brokerId: $e');
      rethrow;
    }
  }

  // Автоматическое подключение с сохраненным ключом
  Future<void> autoConnectWithSavedKey(String brokerId) async {
    final index = _brokers.indexWhere((b) => b.id == brokerId);
    if (index == -1) return;
    
    final broker = _brokers[index];
    
    // Если есть сохраненный ключ и брокер включен
    if (broker.isEnabled && broker.savedApiKey.isNotEmpty && !broker.isConnected) {
      try {
        // Устанавливаем текущий ключ из сохраненного
        _brokers[index] = broker.copyWith(apiKey: broker.savedApiKey);
        
        // Тестируем подключение
        await testConnection(brokerId);
        
        // Если подключение успешно, загружаем портфель для Tinkoff
        if (brokerId == 'tinkoff' && _brokers[index].isConnected) {
          await loadTinkoffPortfolio();
        }
        
      } catch (e) {
        print('Ошибка автоподключения для $brokerId: $e');
      }
    }
  }

  // === ОСНОВНЫЕ МЕТОДЫ ===

  void toggleEnabled(String brokerId, bool isEnabled) {
    final index = _brokers.indexWhere((b) => b.id == brokerId);
    if (index != -1) {
      final broker = _brokers[index];
      
      // Если включаем и есть сохраненный ключ
      if (isEnabled && broker.savedApiKey.isNotEmpty) {
        _brokers[index] = broker.copyWith(
          isEnabled: isEnabled,
          apiKey: broker.savedApiKey,
        );
        
        // Автоматически тестируем подключение
        WidgetsBinding.instance.addPostFrameCallback((_) {
          autoConnectWithSavedKey(brokerId);
        });
        
      } else {
        _brokers[index] = broker.copyWith(
          isEnabled: isEnabled,
          isConnected: isEnabled ? broker.isConnected : false,
        );
        
        if (!isEnabled) {
          _brokers[index] = _brokers[index].copyWith(
            apiKey: '',
          );
          
          if (brokerId == 'tinkoff') {
            _disconnectTinkoff();
          }
        }
      }
      
      notifyListeners();
    }
  }

  void updateApiKey(String brokerId, String apiKey) {
    final index = _brokers.indexWhere((b) => b.id == brokerId);
    if (index != -1) {
      _brokers[index] = _brokers[index].copyWith(
        apiKey: apiKey,
        isSaved: false, // Сбрасываем флаг сохранения при изменении ключа
      );
      notifyListeners();
    }
  }

  Future<void> testConnection(String brokerId) async {
    final index = _brokers.indexWhere((b) => b.id == brokerId);
    if (index == -1) return;

    try {
      // Для Tinkoff
      if (brokerId == 'tinkoff') {
        final apiKey = _brokers[index].apiKey;
        if (apiKey.isEmpty) {
          throw Exception('API ключ не указан');
        }

        _tinkoffApiService = TinkoffApiService(apiToken: apiKey);
        final userInfo = await _tinkoffApiService!.getUserInfo();
        
        _brokers[index] = _brokers[index].copyWith(
          isConnected: true,
          lastConnection: DateTime.now(),
          connectionInfo: {
            'userId': userInfo.userId,
            'premStatus': userInfo.premStatus,
            'qualStatus': userInfo.qualStatus,
            'tariff': userInfo.tariff,
          },
        );
        
        _tinkoffAccounts = await _tinkoffApiService!.getAccounts();
        
        final updatedInfo = Map<String, dynamic>.from(_brokers[index].connectionInfo!);
        updatedInfo['accountsCount'] = _tinkoffAccounts.length;
        updatedInfo['firstAccountId'] = _tinkoffAccounts.isNotEmpty ? _tinkoffAccounts.first.id : 'Нет счетов';
        
        _brokers[index] = _brokers[index].copyWith(
          connectionInfo: updatedInfo,
        );
      }
      
      // Для других брокеров можно добавить аналогичную логику
      
      notifyListeners();
      
    } catch (e) {
      _brokers[index] = _brokers[index].copyWith(
        isConnected: false,
        lastConnection: DateTime.now(),
        connectionInfo: {
          'error': e.toString(),
          'status': 'Ошибка подключения',
        },
      );
      notifyListeners();
      rethrow;
    }
  }

  // Метод для сохранения брокера (сохраняет ключ)
  Future<void> saveBroker(String brokerId) async {
    final index = _brokers.indexWhere((b) => b.id == brokerId);
    if (index != -1) {
      final broker = _brokers[index];
      
      if (broker.apiKey.isNotEmpty && broker.isConnected) {
        // Сохраняем ключ
        await saveBrokerApiKey(brokerId, broker.apiKey);
        
        // Показываем уведомление об успешном сохранении
        print('✅ Брокер ${broker.name} сохранен с ключом');
      }
    }
  }

  // Методы для работы с Tinkoff портфелем
  Future<void> loadTinkoffPortfolio() async {
    if (_tinkoffApiService == null || _tinkoffAccounts.isEmpty) {
      _portfolioError = 'Tinkoff API не инициализирован или нет счетов';
      notifyListeners();
      return;
    }

    try {
      _isLoadingPortfolio = true;
      _portfolioError = null;
      notifyListeners();

      final account = _tinkoffAccounts.first;
      _tinkoffPortfolio = await _tinkoffApiService!.getPortfolio(
        account.id,
        currency: 'RUB',
      );

      _isLoadingPortfolio = false;
      notifyListeners();

    } catch (e) {
      _isLoadingPortfolio = false;
      _portfolioError = 'Ошибка загрузки портфеля: $e';
      notifyListeners();
    }
  }

  Future<void> refreshPortfolio() async {
    if (_tinkoffApiService != null && _tinkoffAccounts.isNotEmpty) {
      await loadTinkoffPortfolio();
    }
  }

  void _disconnectTinkoff() {
    _tinkoffPortfolio = null;
    _tinkoffAccounts = [];
    _tinkoffApiService = null;
    _isLoadingPortfolio = false;
    _portfolioError = null;
  }

  // Подключение Tinkoff с токеном
  void connectTinkoffWithToken(String apiToken) {
    final tinkoffIndex = _brokers.indexWhere((b) => b.id == 'tinkoff');
    if (tinkoffIndex != -1) {
      _brokers[tinkoffIndex] = _brokers[tinkoffIndex].copyWith(
        apiKey: apiToken,
        isEnabled: true,
      );
      
      testConnection('tinkoff').then((_) {
        if (_brokers[tinkoffIndex].isConnected) {
          loadTinkoffPortfolio();
        }
      });
    }
  }

  // Получение брокера по ID
  Broker? getBrokerById(String id) {
    return _brokers.firstWhere((b) => b.id == id);
  }

  // Очистка всех данных
  void clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Очищаем все сохраненные ключи
      for (final broker in _brokers) {
        final key = _getPrefsKeyForBroker(broker.id);
        await prefs.remove(key);
      }
      
      // Сбрасываем состояние брокеров
      for (var broker in _brokers) {
        final index = _brokers.indexWhere((b) => b.id == broker.id);
        _brokers[index] = broker.copyWith(
          isEnabled: false,
          isConnected: false,
          apiKey: '',
          savedApiKey: '',
          isSaved: false,
          connectionInfo: {},
        );
      }
      
      _disconnectTinkoff();
      notifyListeners();
      
      print('🧹 Все данные очищены');
    } catch (e) {
      print('Ошибка очистки данных: $e');
    }
  }

  // Получение сохраненных ключей (для отладки)
  Future<Map<String, String>> getSavedApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> result = {};
    
    for (final broker in _brokers) {
      final key = _getPrefsKeyForBroker(broker.id);
      final savedKey = prefs.getString(key);
      if (savedKey != null) {
        result[broker.id] = savedKey;
      }
    }
    
    return result;
  }
}
