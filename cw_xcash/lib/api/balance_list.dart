import 'dart:ffi';
import 'package:cw_xcash/api/signatures.dart';
import 'package:cw_xcash/api/types.dart';
import 'package:cw_xcash/api/xcash_api.dart';
import 'package:cw_xcash/api/structs/xcash_balance_row.dart';
import 'package:cw_xcash/api/structs/xcash_rate.dart';
import 'asset_types.dart';

List<XCashBalanceRow> getXCashFullBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getXCashFullBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<XCashBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<XCashBalanceRow> getXCashUnlockedBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getXCashUnlockedBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<XCashBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<XCashRate> getRate() {
  updateRateNative();
  final size = sizeOfRateNative();
  final ratePointer = getRateNative();
  final rate = ratePointer.asTypedList(size);

  return rate
      .map((addr) => Pointer<XCashRate>.fromAddress(addr).ref)
      .toList();
}

final getXCashFullBalanceNative = xcashApi
    .lookup<NativeFunction<get_full_balance>>('get_full_balance')
    .asFunction<GetXCashFullBalance>();

final getXCashUnlockedBalanceNative = xcashApi
    .lookup<NativeFunction<get_unlocked_balance>>('get_unlocked_balance')
    .asFunction<GetXCashUnlockedBalance>();

final getRateNative = xcashApi
    .lookup<NativeFunction<get_rate>>('get_rate')
    .asFunction<GetRate>();

final sizeOfRateNative = xcashApi
    .lookup<NativeFunction<size_of_rate>>('size_of_rate')
    .asFunction<SizeOfRate>();

final updateRateNative = xcashApi
    .lookup<NativeFunction<update_rate>>('update_rate')
    .asFunction<UpdateRate>();