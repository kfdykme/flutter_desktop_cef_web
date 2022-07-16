library flutter_desktop_cef_web;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kMethodChannelName = "flutter_desktop_cef_web";

/// A Calculator.
class FlutterDesktopCefWeb {
  late MethodChannel mMethodChannel;

  static registerWith() {
    print("FlutterDesktopCefWeb registerWith");
  }

  final GlobalKey _containerKey = GlobalKey();

  static int global_cef_id = 0;

  int cefId = FlutterDesktopCefWeb.global_cef_id++;

  FlutterDesktopCefWeb() {
    mMethodChannel = const MethodChannel(kMethodChannelName);

    mMethodChannel.setMethodCallHandler((call) {
      print("${kMethodChannelName} call.method ${call.method}");
      var result = Future<dynamic>(() {
        return false;
      });

      if (call.method == "onResize") {
        print("${kMethodChannelName} onResize");
        loadCefContainer();
      }
      return result;
    });
  }

  setUrl(String url) {
    invokeMethod("setUrl", <String, Object>{'url': url});
  }

  executeJs(String content) {
    invokeMethod("executeJs", <String, Object>{'content': content});
  }

  showDevtools() {
    invokeMethod("showDevtools", {});
  }

  Container generateCefContainer(double width, double height) {
    return Container(
      key: _containerKey,
      width: width,
      height: height == -1 ? null : height,
      color: Colors.amberAccent,
    );
  }

  loadCefContainer() {
    if (_containerKey.currentContext == null) return;
    var size = _containerKey.currentContext!.findRenderObject()!.paintBounds;
    RenderObject renderObject =
        _containerKey.currentContext!.findRenderObject()!;
    RenderBox? box = renderObject as RenderBox?;
    Offset position = box!.localToGlobal(Offset.zero);

    invokeLoadCef(position.dx.toInt() + 1, position.dy.toInt() - 1,
        size.width.toInt() - 1, size.height.toInt() - 1);
  }

  loadUrl(String url) {
    // mMethodChannel.invokeMethod("loadUrl", <String, Object>{'url': url});
    invokeMethod("loadUrl", <String, Object>{'url': url});
  }

  invokeMethod(String invoke, dynamic arguments) {
    arguments["id"] = cefId.toString();
    mMethodChannel.invokeMethod(invoke, arguments);
  }

  invokeLoadCef(int x, int y, int width, int height) {
    print("loadCef ${x} ${y} ${width} ${height} id:${cefId}\n");
    invokeMethod("loadCef", <String, Object>{
      'x': x.toString(),
      'y': y.toString(),
      "width": width.toString(),
      "height": height.toString()
    });
  }
}
