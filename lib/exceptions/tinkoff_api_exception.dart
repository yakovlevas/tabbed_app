class TinkoffApiException implements Exception {
  final String code;
  final String message;
  final String description;

  TinkoffApiException({
    required this.code,
    required this.message,
    this.description = '',
  });

  @override
  String toString() {
    return 'TinkoffApiException(code: $code, message: $message, description: $description)';
  }
}