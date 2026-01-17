
// lib/models/candle_interval.dart

// lib/models/candle_interval.dart
import 'package:flutter/material.dart';

enum CandleInterval {
  minute1('CANDLE_INTERVAL_1_MIN', '1 мин', '1m'),
  minute5('CANDLE_INTERVAL_5_MIN', '5 мин', '5m'),
  minute15('CANDLE_INTERVAL_15_MIN', '15 мин', '15m'),
  minute30('CANDLE_INTERVAL_30_MIN', '30 мин', '30m'),
  hour('CANDLE_INTERVAL_HOUR', '1 час', '1h'),
  day('CANDLE_INTERVAL_DAY', '1 день', '1d'),
  week('CANDLE_INTERVAL_WEEK', '1 неделя', '1w'),
  month('CANDLE_INTERVAL_MONTH', '1 месяц', '1M');

  final String value;
  final String displayName;
  final String shortName;

  const CandleInterval(this.value, this.displayName, this.shortName);

  // Проверка валидности периода для интервала
  bool isValidPeriod(DateTime from, DateTime to) {
    final duration = to.difference(from);
    
    switch (this) {
      case CandleInterval.minute1:
        return duration.inDays <= 1; // Максимум 1 день для 1-минутных свечей
      case CandleInterval.minute5:
        return duration.inDays <= 7; // Максимум 7 дней для 5-минутных свечей
      case CandleInterval.minute15:
        return duration.inDays <= 30; // Максимум 30 дней для 15-минутных свечей
      case CandleInterval.minute30:
        return duration.inDays <= 60; // Максимум 60 дней для 30-минутных свечей
      case CandleInterval.hour:
        return duration.inDays <= 180; // Максимум 180 дней для часовых свечей
      case CandleInterval.day:
        return duration.inDays <= 365 * 3; // Максимум 3 года для дневных свечей
      case CandleInterval.week:
        return duration.inDays <= 365 * 10; // Максимум 10 лет для недельных свечей
      case CandleInterval.month:
        return duration.inDays <= 365 * 20; // Максимум 20 лет для месячных свечей
    }
  }
}

// Хелпер для работы с интервалами
class CandleIntervalHelper {
  // Получение рекомендуемого интервала для периода
  static CandleInterval getRecommendedInterval(DateTime from, DateTime to) {
    final duration = to.difference(from);
    
    if (duration.inDays <= 1) {
      return CandleInterval.minute5;
    } else if (duration.inDays <= 7) {
      return CandleInterval.hour;
    } else if (duration.inDays <= 30) {
      return CandleInterval.day;
    } else if (duration.inDays <= 90) {
      return CandleInterval.day;
    } else if (duration.inDays <= 180) {
      return CandleInterval.week;
    } else if (duration.inDays <= 365) {
      return CandleInterval.week;
    } else {
      return CandleInterval.month;
    }
  }
  
  // Получение интервала по значению
  static CandleInterval? fromValue(String value) {
    for (var interval in CandleInterval.values) {
      if (interval.value == value) {
        return interval;
      }
    }
    return null;
  }
}

extension CandleIntervalExtension on CandleInterval {
  String get displayName {
    switch (this) {
      case CandleInterval.minute1:
        return '1 минута';
      
      case CandleInterval.minute5:
        return '5 минут';
      
      case CandleInterval.minute15:
        return '15 минут';
      case CandleInterval.minute30:
        return '30 минут';
      case CandleInterval.hour:
        return '1 час';
      case CandleInterval.day:
        return '1 день';
      case CandleInterval.week:
        return '1 неделя';
      case CandleInterval.month:
        return '1 месяц';
    }
  }

  String get shortName {
    switch (this) {
      case CandleInterval.minute1:
        return '1м';
      case CandleInterval.minute5:
        return '5м';
      case CandleInterval.minute15:
        return '15м';
      case CandleInterval.minute30:
        return '30м';
      case CandleInterval.hour:
        return '1ч';
      case CandleInterval.day:
        return '1д';
      case CandleInterval.week:
        return '1н';
      case CandleInterval.month:
        return '1мс';
    }
  }

  Duration get duration {
    switch (this) {
      case CandleInterval.minute1:
        return const Duration(minutes: 1);
      case CandleInterval.minute5:
        return const Duration(minutes: 5);
      case CandleInterval.minute15:
        return const Duration(minutes: 15);
      case CandleInterval.minute30:
        return const Duration(minutes: 30);
      case CandleInterval.hour:
        return const Duration(hours: 1);
      case CandleInterval.day:
        return const Duration(days: 1);
      case CandleInterval.week:
        return const Duration(days: 7);
      case CandleInterval.month:
        return const Duration(days: 30);
    }
  }

  // Максимальный период для интервала
  Duration get maxPeriod {
    switch (this) {
      case CandleInterval.minute1:
      case CandleInterval.minute5:
        return const Duration(days: 1);
      case CandleInterval.minute15:
      case CandleInterval.minute30:
        return const Duration(days: 7);
      case CandleInterval.hour:
        return const Duration(days: 30);
      case CandleInterval.day:
        return const Duration(days: 365);
      case CandleInterval.week:
      case CandleInterval.month:
        return const Duration(days: 365 * 2);
    }
  }

  // Минимальный период для интервала
  Duration get minPeriod {
    switch (this) {
      case CandleInterval.minute1:
      case CandleInterval.minute5:
      case CandleInterval.minute15:
      case CandleInterval.minute30:
        return const Duration(minutes: 5);
      case CandleInterval.hour:
        return const Duration(hours: 1);
      case CandleInterval.day:
        return const Duration(days: 1);
      case CandleInterval.week:
        return const Duration(days: 7);
      case CandleInterval.month:
        return const Duration(days: 30);
    }
  }

  // Проверка валидности периода
  bool isValidPeriod(DateTime from, DateTime to) {
    final period = to.difference(from);
    return period <= maxPeriod && period >= minPeriod;
  }
}



