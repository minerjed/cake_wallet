import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_xcash/xcash_transaction_info.dart';

part 'xcash_transaction_history.g.dart';

class XCashTransactionHistory = XCashTransactionHistoryBase
    with _$XCashTransactionHistory;

abstract class XCashTransactionHistoryBase
    extends TransactionHistoryBase<XCashTransactionInfo> with Store {
  XCashTransactionHistoryBase() {
    transactions = ObservableMap<String, XCashTransactionInfo>();
  }

  @override
  Future<void> save() async {}

  @override
  void addOne(XCashTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, XCashTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);
}
