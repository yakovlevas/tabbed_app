import '../utils/json_utils.dart';

class UserInfo {
  final bool premStatus;
  final bool qualStatus;
  final List<String> qualifiedForWorkWith;
  final String tariff;
  final String userId;
  final String riskLevelCode;

  UserInfo({
    required this.premStatus,
    required this.qualStatus,
    required this.qualifiedForWorkWith,
    required this.tariff,
    required this.userId,
    required this.riskLevelCode,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      premStatus: JsonUtils.parseBool(json['premStatus']),
      qualStatus: JsonUtils.parseBool(json['qualStatus']),
      qualifiedForWorkWith: List<String>.from(
        json['qualifiedForWorkWith'] ?? [],
      ),
      tariff: json['tariff']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      riskLevelCode: json['riskLevelCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'premStatus': premStatus,
    'qualStatus': qualStatus,
    'qualifiedForWorkWith': qualifiedForWorkWith,
    'tariff': tariff,
    'userId': userId,
    'riskLevelCode': riskLevelCode,
  };
}