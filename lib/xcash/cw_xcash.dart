part of 'xcash.dart';

class CWXCashAccountList extends XCashAccountList {
  CWXCashAccountList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Account> get accounts {
    final xcashWallet = _wallet as XCashWallet;
    final accounts = xcashWallet.walletAddresses.accountList.accounts
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
    return ObservableList<Account>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    xcashWallet.walletAddresses.accountList.update();
  }

  @override
  void refresh(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    xcashWallet.walletAddresses.accountList.refresh();
  }

  @override
  List<Account> getAll(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    return xcashWallet.walletAddresses.accountList
        .getAll()
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final xcashWallet = wallet as XCashWallet;
    await xcashWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final xcashWallet = wallet as XCashWallet;
    await xcashWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}

class CWXCashSubaddressList extends MoneroSubaddressList {
  CWXCashSubaddressList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Subaddress> get subaddresses {
    final xcashWallet = _wallet as XCashWallet;
    final subAddresses = xcashWallet.walletAddresses.subaddressList.subaddresses
        .map((sub) => Subaddress(id: sub.id, address: sub.address, label: sub.label))
        .toList();
    return ObservableList<Subaddress>.of(subAddresses);
  }

  @override
  void update(Object wallet, {required int accountIndex}) {
    final xcashWallet = wallet as XCashWallet;
    xcashWallet.walletAddresses.subaddressList.update(accountIndex: accountIndex);
  }

  @override
  void refresh(Object wallet, {required int accountIndex}) {
    final xcashWallet = wallet as XCashWallet;
    xcashWallet.walletAddresses.subaddressList.refresh(accountIndex: accountIndex);
  }

  @override
  List<Subaddress> getAll(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    return xcashWallet.walletAddresses.subaddressList
        .getAll()
        .map((sub) => Subaddress(id: sub.id, label: sub.label, address: sub.address))
        .toList();
  }

  @override
  Future<void> addSubaddress(Object wallet,
      {required int accountIndex, required String label}) async {
    final xcashWallet = wallet as XCashWallet;
    await xcashWallet.walletAddresses.subaddressList
        .addSubaddress(accountIndex: accountIndex, label: label);
  }

  @override
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label}) async {
    final xcashWallet = wallet as XCashWallet;
    await xcashWallet.walletAddresses.subaddressList
        .setLabelSubaddress(accountIndex: accountIndex, addressIndex: addressIndex, label: label);
  }
}

class CWXCashWalletDetails extends XCashWalletDetails {
  CWXCashWalletDetails(this._wallet);

  final Object _wallet;

  @computed
  @override
  Account get account {
    final xcashWallet = _wallet as XCashWallet;
    final acc = xcashWallet.walletAddresses.account as monero_account.Account;
    return Account(id: acc.id, label: acc.label);
  }

  @computed
  @override
  XCashBalance get balance {
    final xcashWallet = _wallet as XCashWallet;
    final balance = xcashWallet.balance;
    throw Exception('Unimplemented');
    //return XCashBalance(
    //	fullBalance: balance.fullBalance,
    //	unlockedBalance: balance.unlockedBalance);
  }
}

class CWXCash extends XCash {
  @override
  XCashAccountList getAccountList(Object wallet) {
    return CWXCashAccountList(wallet);
  }

  @override
  MoneroSubaddressList getSubaddressList(Object wallet) {
    return CWXCashSubaddressList(wallet);
  }

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    return xcashWallet.transactionHistory;
  }

  @override
  XCashWalletDetails getMoneroWalletDetails(Object wallet) {
    return CWXCashWalletDetails(wallet);
  }

  @override
  int getHeightByDate({required DateTime date}) => getXCashHeightByDate(date: date);

  @override
  Future<int> getCurrentHeight() => getXCashCurrentHeight();

  @override
  TransactionPriority getDefaultTransactionPriority() {
    return MoneroTransactionPriority.automatic;
  }

  @override
  TransactionPriority deserializeMoneroTransactionPriority({required int raw}) {
    return MoneroTransactionPriority.deserialize(raw: raw);
  }

  @override
  List<TransactionPriority> getTransactionPriorities() {
    return MoneroTransactionPriority.all;
  }

  @override
  List<String> getMoneroWordList(String language) {
    switch (language.toLowerCase()) {
      case 'english':
        return EnglishMnemonics.words;
      case 'chinese (simplified)':
        return ChineseSimplifiedMnemonics.words;
      case 'dutch':
        return DutchMnemonics.words;
      case 'german':
        return GermanMnemonics.words;
      case 'japanese':
        return JapaneseMnemonics.words;
      case 'portuguese':
        return PortugueseMnemonics.words;
      case 'russian':
        return RussianMnemonics.words;
      case 'spanish':
        return SpanishMnemonics.words;
      case 'french':
        return FrenchMnemonics.words;
      case 'italian':
        return ItalianMnemonics.words;
      default:
        return EnglishMnemonics.words;
    }
  }

  @override
  WalletCredentials createXCashRestoreWalletFromKeysCredentials(
      {required String name,
      required String spendKey,
      required String viewKey,
      required String address,
      required String password,
      required String language,
      required int height}) {
    return XCashRestoreWalletFromKeysCredentials(
        name: name,
        spendKey: spendKey,
        viewKey: viewKey,
        address: address,
        password: password,
        language: language,
        height: height);
  }

  @override
  WalletCredentials createXCashRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required int height,
      required String mnemonic}) {
    return XCashRestoreWalletFromSeedCredentials(
        name: name, password: password, height: height, mnemonic: mnemonic);
  }

  @override
  WalletCredentials createXCashNewWalletCredentials(
      {required String name, required String language, String? password}) {
    return XCashNewWalletCredentials(name: name, password: password, language: language);
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    final keys = xcashWallet.keys;
    return <String, String>{
      'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey
    };
  }

  @override
  Object createXCashTransactionCreationCredentials(
      {required List<Output> outputs,
      required TransactionPriority priority,
      required String assetType}) {
    return XCashTransactionCreationCredentials(
        outputs: outputs
            .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount))
            .toList(),
        priority: priority as MoneroTransactionPriority,
        assetType: assetType);
  }

  @override
  String formatterMoneroAmountToString({required int amount}) {
    return moneroAmountToString(amount: amount);
  }

  @override
  double formatterMoneroAmountToDouble({required int amount}) {
    return moneroAmountToDouble(amount: amount);
  }

  @override
  int formatterMoneroParseAmount({required String amount}) {
    return moneroParseAmount(amount: amount);
  }

  @override
  Account getCurrentAccount(Object wallet) {
    final xcashWallet = wallet as XCashWallet;
    final acc = xcashWallet.walletAddresses.account as monero_account.Account;
    return Account(id: acc.id, label: acc.label);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label) {
    final xcashWallet = wallet as XCashWallet;
    xcashWallet.walletAddresses.account = monero_account.Account(id: id, label: label);
  }

  @override
  void onStartup() {
    monero_wallet_api.onStartup();
  }

  @override
  int getTransactionInfoAccountId(TransactionInfo tx) {
    final xcashTransactionInfo = tx as XCashTransactionInfo;
    return xcashTransactionInfo.accountIndex;
  }

  @override
  WalletService createXCashWalletService(Box<WalletInfo> walletInfoSource) {
    return XCashWalletService(walletInfoSource);
  }

  @override
  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    final xcashWallet = wallet as XCashWallet;
    return xcashWallet.getTransactionAddress(accountIndex, addressIndex);
  }

  @override
  CryptoCurrency assetOfTransaction(TransactionInfo tx) {
    final transaction = tx as XCashTransactionInfo;
    final asset = CryptoCurrency.fromString(transaction.assetType);
    return asset;
  }

  @override
  List<AssetRate> getAssetRate() =>
      getRate().map((rate) => AssetRate(rate.getAssetType(), rate.getRate())).toList();
}
