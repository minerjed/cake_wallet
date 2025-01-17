import 'dart:ffi';
import 'package:ffi/ffi.dart';

class XCashRate extends Struct {
  @Int64()
  external int rate;
  
  external Pointer<Utf8> assetType;

  int getRate() => rate;
  String getAssetType() => assetType.toDartString();
}
