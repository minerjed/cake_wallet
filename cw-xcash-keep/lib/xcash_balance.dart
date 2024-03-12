import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_xcash/api/balance_list.dart';
import 'package:cw_xcash/api/structs/xcash_balance_row.dart';

const inactiveBalances = [
  CryptoCurrency.xcad,
  CryptoCurrency.xjpy,
  CryptoCurrency.xnok,
  CryptoCurrency.xnzd]; 

Map<CryptoCurrency, MoneroBalance> getXCashBalance({required int accountIndex}) {
  final fullBalances = getXCashFullBalance(accountIndex: accountIndex);
  final unlockedBalances = getXCashUnlockedBalance(accountIndex: accountIndex);
  final xcashBalances = <CryptoCurrency, MoneroBalance>{};
  final balancesLength = fullBalances.length;
  
  for (int i = 0; i < balancesLength; i++) {
    final assetType = fullBalances[i].getAssetType();
    final fullBalance = fullBalances[i].getAmount();
    final unlockedBalance = unlockedBalances[i].getAmount();
    final moneroBalance = MoneroBalance(
        fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    final currency = CryptoCurrency.fromString(assetType);

    if (inactiveBalances.indexOf(currency) >= 0) {
      continue;
    }

    xcashBalances[currency] = moneroBalance;
  }

  return xcashBalances;
}