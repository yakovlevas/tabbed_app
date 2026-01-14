import 'package:flutter/material.dart';
import '../models/broker.dart';
import '../services/tinkoff_api_service.dart';

class BrokersProvider extends ChangeNotifier {
  final List<Broker> _brokers = Broker.allBrokers();

  List<Broker> get brokers => List.unmodifiable(_brokers);

  List<Broker> get connectedBrokers =>
      _brokers.where((b) => b.isConnected).toList();

  Broker getBroker(String id) =>
      _brokers.firstWhere((b) => b.id == id, orElse: () => _brokers.first);

  void updateBroker(String id, Broker updatedBroker) {
    final index = _brokers.indexWhere((b) => b.id == id);
    if (index != -1) {
      _brokers[index] = updatedBroker;
      notifyListeners();
    }
  }

  void updateApiKey(String id, String apiKey) {
    final index = _brokers.indexWhere((b) => b.id == id);
    if (index != -1) {
      _brokers[index] = _brokers[index].copyWith(apiKey: apiKey);
      notifyListeners();
    }
  }

  void toggleEnabled(String id, bool enabled) {
    final index = _brokers.indexWhere((b) => b.id == id);
    if (index != -1) {
      _brokers[index] = _brokers[index].copyWith(isEnabled: enabled);
      notifyListeners();
    }
  }

  Future<void> testConnection(String brokerId) async {
    final broker = getBroker(brokerId);
    
    if (broker.apiKey.isEmpty) {
      updateBroker(
        brokerId,
        broker.copyWith(
          isConnected: false,
          connectionInfo: {'error': 'API ключ не указан'},
        ),
      );
      return;
    }

    try {
      // Пока только Tinkoff
      if (brokerId == 'tinkoff') {
        final service = TinkoffApiService(apiToken: broker.apiKey);
        final userInfo = await service.getUserInfo();

        updateBroker(
          brokerId,
          broker.copyWith(
            isConnected: true,
            lastConnection: DateTime.now(),
            connectionInfo: {
              'userId': userInfo.userId,
              'premStatus': userInfo.premStatus,
              'qualStatus': userInfo.qualStatus,
              'tariff': userInfo.tariff,
              'riskLevel': userInfo.riskLevelCode,
            },
          ),
        );
      } else {
        // Заглушки для других брокеров
        await Future.delayed(const Duration(seconds: 1));
        
        updateBroker(
          brokerId,
          broker.copyWith(
            isConnected: true,
            lastConnection: DateTime.now(),
            connectionInfo: {
              'status': 'В разработке',
              'message': 'Интеграция с ${broker.name} в разработке',
            },
          ),
        );
      }
    } catch (e) {
      updateBroker(
        brokerId,
        broker.copyWith(
          isConnected: false,
          connectionInfo: {'error': e.toString()},
        ),
      );
    }
  }

  void saveBroker(String brokerId) {
    // Здесь будет логика сохранения в базу данных
    print('Сохранен брокер $brokerId');
  }

  Future<void> loadPortfolio(String brokerId) async {
    // Заглушка для загрузки портфеля
    print('Загрузка портфеля для $brokerId');
  }

  double get totalPortfolioValue {
    // Заглушка для расчета общей стоимости
    return 1500000.0;
  }

  Map<String, double> get portfolioByBroker {
    // Заглушка для распределения по брокерам
    return {
      'tinkoff': 800000.0,
      'bcs': 450000.0,
      'finam': 250000.0,
    };
  }
}