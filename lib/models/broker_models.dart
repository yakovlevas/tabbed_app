// Модели для UI
class Broker {
  final String id;
  final String name;
  final String description;
  final String logoAsset;
  final String apiDocsUrl;
  
  Broker({
    required this.id,
    required this.name,
    required this.description,
    required this.logoAsset,
    required this.apiDocsUrl,
  });
}

// Вспомогательные модели для конвертации
class AccountInfo {
  final String brokerAccountId;
  final String brokerAccountType;
  final String status;
  final DateTime openedDate;
  final DateTime lastUpdate;
  final double totalBalance;
  final double expectedYield;
  final String currency;
  final int totalAccounts;
  
  AccountInfo({
    required this.brokerAccountId,
    required this.brokerAccountType,
    required this.status,
    required this.openedDate,
    required this.lastUpdate,
    required this.totalBalance,
    required this.expectedYield,
    required this.currency,
    required this.totalAccounts,
  });

  // Конвертация из Map
  factory AccountInfo.fromMap(Map<String, dynamic> map) {
    return AccountInfo(
      brokerAccountId: map['brokerAccountId']?.toString() ?? '',
      brokerAccountType: map['brokerAccountType']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      openedDate: DateTime.tryParse(map['openedDate']?.toString() ?? '') ?? DateTime.now(),
      lastUpdate: DateTime.tryParse(map['lastUpdate']?.toString() ?? '') ?? DateTime.now(),
      totalBalance: (map['totalBalance'] as num?)?.toDouble() ?? 0.0,
      expectedYield: (map['expectedYield'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'RUB',
      totalAccounts: (map['totalAccounts'] as num?)?.toInt() ?? 0,
    );
  }

  // Конвертация в Map
  Map<String, dynamic> toMap() {
    return {
      'brokerAccountId': brokerAccountId,
      'brokerAccountType': brokerAccountType,
      'status': status,
      'openedDate': openedDate.toString(),
      'lastUpdate': lastUpdate.toString(),
      'totalBalance': totalBalance,
      'expectedYield': expectedYield,
      'currency': currency,
      'totalAccounts': totalAccounts,
    };
  }
}