library flutter_desktop_cef_web;

import 'package:flutter/services.dart';

const kMethodChannelName = "flutter_desktop_cef_web";

/// A Calculator.
class FlutterDesktopCefWeb {
  late MethodChannel mMethodChannel;

  static registerWith() {
    print("FlutterDesktopCefWeb registerWith");
  }

  FlutterDesktopCefWeb() {
    mMethodChannel = const MethodChannel(kMethodChannelName);
  }

  loadCef(int x, int y, int width, int height) {
    print("loadCef ${x} ${y} ${width} ${height}");
    mMethodChannel.invokeMethod("loadCef", <String, Object>{
      'x': x.toString(),
      'y': y.toString(),
      "width": width.toString(),
      "height": height.toString()
    });
  }
}
