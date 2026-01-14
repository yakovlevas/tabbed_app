import 'package:flutter/material.dart';

class Broker {
  final String id;
  final String name;
  final String logoAsset;
  final int primaryColorValue; // Храним как int для сериализации
  final String apiKey;
  final bool isEnabled;
  final bool isConnected;
  final DateTime? lastConnection;
  final Map<String, dynamic>? connectionInfo;

  Broker({
    required this.id,
    required this.name,
    required this.logoAsset,
    required this.primaryColorValue,
    this.apiKey = '',
    this.isEnabled = false,
    this.isConnected = false,
    this.lastConnection,
    this.connectionInfo,
  });

  // Геттер для Color
  Color get primaryColor => Color(primaryColorValue);

  Broker copyWith({
    String? id,
    String? name,
    String? logoAsset,
    int? primaryColorValue,
    String? apiKey,
    bool? isEnabled,
    bool? isConnected,
    DateTime? lastConnection,
    Map<String, dynamic>? connectionInfo,
  }) {
    return Broker(
      id: id ?? this.id,
      name: name ?? this.name,
      logoAsset: logoAsset ?? this.logoAsset,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      apiKey: apiKey ?? this.apiKey,
      isEnabled: isEnabled ?? this.isEnabled,
      isConnected: isConnected ?? this.isConnected,
      lastConnection: lastConnection ?? this.lastConnection,
      connectionInfo: connectionInfo ?? this.connectionInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoAsset': logoAsset,
      'primaryColorValue': primaryColorValue,
      'apiKey': apiKey,
      'isEnabled': isEnabled,
      'isConnected': isConnected,
      'lastConnection': lastConnection?.toIso8601String(),
      'connectionInfo': connectionInfo,
    };
  }

  factory Broker.fromJson(Map<String, dynamic> json) {
    return Broker(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoAsset: json['logoAsset'] ?? '',
      primaryColorValue: json['primaryColorValue'] ?? 0xFF0066FF,
      apiKey: json['apiKey'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      isConnected: json['isConnected'] ?? false,
      lastConnection: json['lastConnection'] != null
          ? DateTime.parse(json['lastConnection'])
          : null,
      connectionInfo: json['connectionInfo'] != null
          ? Map<String, dynamic>.from(json['connectionInfo'])
          : null,
    );
  }

  static Broker tinkoff() {
    return Broker(
      id: 'tinkoff',
      name: 'Тинькофф Инвестиции',
      logoAsset: 'assets/logos/tinkoff.png',
      primaryColorValue: 0xFF0066FF,
    );
  }

  static Broker bcs() {
    return Broker(
      id: 'bcs',
      name: 'БКС Брокер',
      logoAsset: 'assets/logos/bcs.png',
      primaryColorValue: 0xFF00A86B,
      isEnabled: false,
    );
  }

  static Broker finam() {
    return Broker(
      id: 'finam',
      name: 'ФИНАМ',
      logoAsset: 'assets/logos/finam.png',
      primaryColorValue: 0xFF0D47A1,
      isEnabled: false,
    );
  }

  static List<Broker> allBrokers() {
    return [
      tinkoff(),
      bcs(),
      finam(),
    ];
  }
}