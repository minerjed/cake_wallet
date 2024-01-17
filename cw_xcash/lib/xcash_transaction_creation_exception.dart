class XCashTransactionCreationException implements Exception {
  XCashTransactionCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}