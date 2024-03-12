import 'dart:async';
import 'dart:io';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_xcash/xcash_transaction_creation_credentials.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_xcash/xcash_transaction_creation_exception.dart';
import 'package:cw_xcash/xcash_transaction_info.dart';
import 'package:cw_xcash/xcash_wallet_addresses.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_xcash/api/structs/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_xcash/api/transaction_history.dart' as xcash_transaction_history;
//import 'package:cw_xcash/wallet.dart';
import 'package:cw_xcash/api/wallet.dart' as xcash_wallet;
import 'package:cw_xcash/api/transaction_history.dart' as transaction_history;
import 'package:cw_xcash/api/monero_output.dart';
import 'package:cw_xcash/pending_xcash_transaction.dart';
import 'package:cw_core/monero_wallet_keys.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_xcash/xcash_transaction_history.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_xcash/xcash_balance.dart';

part 'xcash_wallet.g.dart';

const moneroBlockSize = 1000;

class XCashWallet = XCashWalletBase with _$XCashWallet;

abstract class XCashWalletBase
    extends WalletBase<MoneroBalance, XCashTransactionHistory, XCashTransactionInfo> with Store {
  XCashWalletBase({required WalletInfo walletInfo})
      : balance = ObservableMap.of(getXCashBalance(accountIndex: 0)),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = XCashWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = XCashTransactionHistory();
    _onAccountChangeReaction = reaction((_) => walletAddresses.account, (Account? account) {
      if (account == null) {
        return;
      }
      balance.addAll(getXCashBalance(accountIndex: account.id));
      walletAddresses.updateSubaddressList(accountIndex: account.id);
    });
  }

  static const int _autoSaveInterval = 30;

  @override
  XCashWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MoneroBalance> balance;

  @override
  String get seed => xcash_wallet.getSeed();

  @override
  MoneroWalletKeys get keys => MoneroWalletKeys(
      privateSpendKey: xcash_wallet.getSecretSpendKey(),
      privateViewKey: xcash_wallet.getSecretViewKey(),
      publicSpendKey: xcash_wallet.getPublicSpendKey(),
      publicViewKey: xcash_wallet.getPublicViewKey());

  xcash_wallet.SyncListener? _listener;
  ReactionDisposer? _onAccountChangeReaction;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  Future<void> init() async {
    await walletAddresses.init();
    balance.addAll(getXCashBalance(accountIndex: walletAddresses.account?.id ?? 0));
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      xcash_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (xcash_wallet.getCurrentHeight() <= 1) {
        xcash_wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }

    _autoSaveTimer =
        Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction.dispose();
    _autoSaveTimer?.cancel();
  }
  
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await xcash_wallet.setupNode(
          address: node.uriRaw,
          login: node.login,
          password: node.password,
          useSSL: node.useSSL ?? false,
          isLightWallet: false, // FIXME: hardcoded value
          socksProxyAddress: node.socksProxyAddress);

      xcash_wallet.setTrustedDaemon(node.trusted);
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
    }
  }

  @override
  Future<void> startSync() async {
    try {
      _setInitialHeight();
    } catch (_) {}

    try {
      syncStatus = AttemptingSyncStatus();
      xcash_wallet.startRefresh();
      _setListeners();
      _listener?.start();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as XCashTransactionCreationCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final assetType = CryptoCurrency.fromString(_credentials.assetType.toLowerCase());
    final balances = getXCashBalance(accountIndex: walletAddresses.account!.id);
    final unlockedBalance = balances[assetType]!.unlockedBalance;

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw XCashTransactionCreationException('The wallet is not synced.');
    }

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw XCashTransactionCreationException(
            'You do not have enough coins to send this amount.');
      }

      final int totalAmount =
          outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      if (unlockedBalance < totalAmount) {
        throw XCashTransactionCreationException(
            'You do not have enough coins to send this amount.');
      }

      final moneroOutputs = outputs
          .map((output) => MoneroOutput(
              address: output.address, amount: output.cryptoAmount!.replaceAll(',', '.')))
          .toList();

      pendingTransactionDescription = await transaction_history.createTransactionMultDest(
          outputs: moneroOutputs,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account!.id);
    } else {
      final output = outputs.first;
      final address = output.isParsedAddress && (output.extractedAddress?.isNotEmpty ?? false)
          ? output.extractedAddress!
          : output.address;
      final amount = output.sendAll ? null : output.cryptoAmount!.replaceAll(',', '.');
      final int? formattedAmount = output.sendAll ? null : output.formattedCryptoAmount;

      if ((formattedAmount != null && unlockedBalance < formattedAmount) ||
          (formattedAmount == null && unlockedBalance <= 0)) {
        final formattedBalance = moneroAmountToString(amount: unlockedBalance);

        throw XCashTransactionCreationException(
            'You do not have enough unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
      }

      pendingTransactionDescription = await transaction_history.createTransaction(
          address: address,
          assetType: _credentials.assetType,
          amount: amount,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account!.id);
    }

    return PendingXCashTransaction(pendingTransactionDescription, assetType);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    // FIXME: hardcoded value;

    if (priority is MoneroTransactionPriority) {
      switch (priority) {
        case MoneroTransactionPriority.slow:
          return 24590000;
        case MoneroTransactionPriority.automatic:
          return 123050000;
        case MoneroTransactionPriority.medium:
          return 245029999;
        case MoneroTransactionPriority.fast:
          return 614530000;
        case MoneroTransactionPriority.fastest:
          return 26021600000;
      }
    }

    return 0;
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    await backupWalletFiles(name);
    await xcash_wallet.store();
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: name, type: type);
    final currentCacheFile = File(currentWalletPath);
    final currentKeysFile = File('$currentWalletPath.keys');
    final currentAddressListFile = File('$currentWalletPath.address.txt');

    final newWalletPath = await pathForWallet(name: newWalletName, type: type);

    // Copies current wallet files into new wallet name's dir and files
    if (currentCacheFile.existsSync()) {
      await currentCacheFile.copy(newWalletPath);
    }
    if (currentKeysFile.existsSync()) {
      await currentKeysFile.copy('$newWalletPath.keys');
    }
    if (currentAddressListFile.existsSync()) {
      await currentAddressListFile.copy('$newWalletPath.address.txt');
    }

    // Delete old name's dir and files
    await Directory(currentWalletPath).delete(recursive: true);
  }

  @override
  Future<void> changePassword(String password) async {
    xcash_wallet.setPasswordSync(password);
  }

  Future<int> getNodeHeight() async => xcash_wallet.getNodeHeight();

  Future<bool> isConnected() async => xcash_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    xcash_wallet.setRefreshFromBlockHeight(height: height);
    xcash_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    walletAddresses.accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      xcash_wallet.getAddress(accountIndex: accountIndex, addressIndex: addressIndex);

  @override
  Future<Map<String, XCashTransactionInfo>> fetchTransactions() async {
    xcash_transaction_history.refreshTransactions();
    return _getAllTransactions(null)
        .fold<Map<String, XCashTransactionInfo>>(<String, XCashTransactionInfo>{},
            (Map<String, XCashTransactionInfo> acc, XCashTransactionInfo tx) {
      acc[tx.id] = tx;
      return acc;
    });
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e) {
      print(e);
      _isTransactionUpdating = false;
    }
  }

  List<XCashTransactionInfo> _getAllTransactions(dynamic _) => xcash_transaction_history
      .getAllTransations()
      .map((row) => XCashTransactionInfo.fromRow(row))
      .toList();

  void _setListeners() {
    _listener?.stop();
    _listener = xcash_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = xcash_wallet.getCurrentHeight();

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      xcash_wallet.setRecoveringFromSeed(isRecovery: true);
      xcash_wallet.setRefreshFromBlockHeight(height: height);
    }
  }

  int _getHeightDistance(DateTime date) {
    final distance = DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final daysTmp = (distance / 86400).round();
    final days = daysTmp < 1 ? 1 : daysTmp;

    return days * 1000;
  }

  int _getHeightByDate(DateTime date) {
    final nodeHeight = xcash_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() =>
      balance.addAll(getXCashBalance(accountIndex: walletAddresses.account!.id));

  Future<void> _askForUpdateTransactionHistory() async => await updateTransactions();

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
      }

      if (blocksLeft < 1000) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
        syncStatus = SyncedSyncStatus();

        if (!_hasSyncAfterStartup) {
          _hasSyncAfterStartup = true;
          await save();
        }

        if (walletInfo.isRecovery) {
          await setAsRecovered();
        }
      } else {
        syncStatus = SyncingSyncStatus(blocksLeft, ptc);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _onNewTransaction() async {
    try {
      await _askForUpdateTransactionHistory();
      _askForUpdateBalance();
      await Future<void>.delayed(Duration(seconds: 1));
    } catch (e) {
      print(e.toString());
    }
  }
}
