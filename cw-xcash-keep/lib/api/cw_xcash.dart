
import 'dart:async';

import 'package:flutter/services.dart';

class CwXCash {
  static const MethodChannel _channel =
      const MethodChannel('cw_xcash');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod<String>('getPlatformVersion') ?? '';
    return version;
  }
}
