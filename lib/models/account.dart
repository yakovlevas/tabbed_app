class Account {
  final String id;
  final String type;
  final String name;
  final String status;
  final DateTime openedDate;
  final DateTime? closedDate;

  Account({
    required this.id,
    required this.type,
    required this.name,
    required this.status,
    required this.openedDate,
    this.closedDate,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      openedDate: DateTime.parse(json['openedDate']?.toString() ?? '1970-01-01'),
      closedDate: json['closedDate'] != null 
        ? DateTime.parse(json['closedDate']?.toString() ?? '')
        : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    'status': status,
    'openedDate': openedDate.toIso8601String(),
    'closedDate': closedDate?.toIso8601String(),
  };

  String getDisplayType() {
    switch (type) {
      case 'ACCOUNT_TYPE_TINKOFF':
        return 'Брокерский счет Tinkoff';
      case 'ACCOUNT_TYPE_TINKOFF_IIS':
        return 'ИИС Tinkoff';
      case 'ACCOUNT_TYPE_INVEST_BOX':
        return 'Инвесткопилка';
      default:
        return type;
    }
  }

  String getDisplayStatus() {
    switch (status) {
      case 'ACCOUNT_STATUS_NEW':
        return 'Новый';
      case 'ACCOUNT_STATUS_OPEN':
        return 'Открыт';
      case 'ACCOUNT_STATUS_CLOSED':
        return 'Закрыт';
      default:
        return status;
    }
  }
}