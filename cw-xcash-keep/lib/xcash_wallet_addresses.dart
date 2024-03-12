import 'package:cw_core/wallet_addresses_with_account.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/account.dart';
import 'package:cw_xcash/xcash_account_list.dart';
import 'package:cw_xcash/xcash_subaddress_list.dart';
import 'package:cw_core/subaddress.dart';
import 'package:mobx/mobx.dart';

part 'xcash_wallet_addresses.g.dart';

class XCashWalletAddresses = XCashWalletAddressesBase
    with _$XCashWalletAddresses;

abstract class XCashWalletAddressesBase extends WalletAddressesWithAccount<Account> with Store {
  XCashWalletAddressesBase(WalletInfo walletInfo)
    : accountList = XCashAccountList(),
      subaddressList = XCashSubaddressList(),
      address = '',
      super(walletInfo);

  @override
  @observable
  String address;
  
  // @override
  @observable
  Account? account;

  @observable
  Subaddress? subaddress;

  XCashSubaddressList subaddressList;
  
  XCashAccountList accountList;

  @override
  Future<void> init() async {
    accountList.update();
    account = accountList.accounts.first;
    updateSubaddressList(accountIndex: account?.id ?? 0);
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      final _subaddressList = XCashSubaddressList();

      addressesMap.clear();

      accountList.accounts.forEach((account) {
        _subaddressList.update(accountIndex: account.id);
        _subaddressList.subaddresses.forEach((subaddress) {
          addressesMap[subaddress.address] = subaddress.label;
        });
      });

      await saveAddressesInBox();
    } catch (e) {
      print(e.toString());
    }
  }

  bool validate() {
    accountList.update();
    final accountListLength = accountList.accounts.length;

    if (accountListLength <= 0) {
      return false;
    }

    subaddressList.update(accountIndex: accountList.accounts.first.id);
    final subaddressListLength = subaddressList.subaddresses.length;

    if (subaddressListLength <= 0) {
      return false;
    }

    return true;
  }

  void updateSubaddressList({required int accountIndex}) {
    subaddressList.update(accountIndex: accountIndex);
    subaddress = subaddressList.subaddresses.first;
    address = subaddress!.address;
  }

  @override
  bool containsAddress(String address) =>
      addressInfos[account?.id ?? 0]?.any((it) => it.address == address) ?? false;
}
