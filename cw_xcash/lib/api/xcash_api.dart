import 'dart:ffi';
import 'dart:io';

final DynamicLibrary xcashApi = Platform.isAndroid
    ? DynamicLibrary.open("libcw_xcash.so")
    : DynamicLibrary.open("cw_xcash.framework/cw_xcash");