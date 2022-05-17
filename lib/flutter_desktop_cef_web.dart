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

  FlutterDesktopCefWeb() {
    mMethodChannel = const MethodChannel(kMethodChannelName);
  }

  Container generateCefContainer(double width, double height) {
    return Container(
      key: _containerKey,
      width: width,
      height: height,
      color: Colors.amberAccent,
    );
  }

  loadCefContainer() {
    var size = _containerKey.currentContext!.findRenderObject()!.paintBounds;
    RenderObject renderObject =
        _containerKey.currentContext!.findRenderObject()!;
    RenderBox? box = renderObject as RenderBox?;
    Offset position = box!.localToGlobal(Offset.zero);

    invokeLoadCef(position.dx.toInt(), position.dy.toInt(), size.width.toInt(),
        size.height.toInt());
  }

  invokeLoadCef(int x, int y, int width, int height) {
    print("loadCef ${x} ${y} ${width} ${height}");
    mMethodChannel.invokeMethod("loadCef", <String, Object>{
      'x': x.toString(),
      'y': y.toString(),
      "width": width.toString(),
      "height": height.toString()
    });
  }
}
