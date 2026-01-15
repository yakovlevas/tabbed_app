
// lib/models/broker.dart
import 'package:flutter/material.dart';

class Broker {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isEnabled;
  final bool isConnected;
  final String apiKey;
  final String savedApiKey; // Сохраненный ключ
  final Map<String, dynamic>? connectionInfo;
  final DateTime? lastConnection;
  final bool isSaved; // Флаг сохранения

  Broker({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    this.isEnabled = false,
    this.isConnected = false,
    this.apiKey = '',
    this.savedApiKey = '',
    this.connectionInfo,
    this.lastConnection,
    this.isSaved = false,
  });

  Broker copyWith({
    String? id,
    String? name,
    String? description,
    Color? primaryColor,
    Color? secondaryColor,
    bool? isEnabled,
    bool? isConnected,
    String? apiKey,
    String? savedApiKey,
    Map<String, dynamic>? connectionInfo,
    DateTime? lastConnection,
    bool? isSaved,
  }) {
    return Broker(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isEnabled: isEnabled ?? this.isEnabled,
      isConnected: isConnected ?? this.isConnected,
      apiKey: apiKey ?? this.apiKey,
      savedApiKey: savedApiKey ?? this.savedApiKey,
      connectionInfo: connectionInfo ?? this.connectionInfo,
      lastConnection: lastConnection ?? this.lastConnection,
      isSaved: isSaved ?? this.isSaved,
    );
  }
  
  // Проверяет, есть ли сохраненный ключ
  bool get hasSavedKey => savedApiKey.isNotEmpty;
}
