library flutter_desktop_cef_web;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kMethodChannelName = "flutter_desktop_cef_web";

/// A Calculator.
class FlutterDesktopCefWeb {
  late MethodChannel mMethodChannel;
  bool hasGeneratedContainer = false;
  static registerWith() {
    print("FlutterDesktopCefWeb registerWith");
  }

  final GlobalKey _containerKey = GlobalKey();

  static int global_cef_id = 0;

  static List<FlutterDesktopCefWeb> allWebViews = [];

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
      if (call.method == "ipcRender") {
        handleIpcRenderMessage(call.arguments);
      }
      return result;
    });

    FlutterDesktopCefWeb.allWebViews.add(this);
  }

  bool handleIpcRenderMessage(dynamic arguments) {
    return false;
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

  GlobalKey key() {
    return _containerKey;
  }

  Widget generateCefContainer(double width, double height) {
    var container = Expanded(
        key: _containerKey,
        child: Container(
          width: null,
          height: height == -1 ? null : height,
        ));
    hasGeneratedContainer = true;
    return container;
  }

  loadCefContainer() {

    if (_containerKey.currentContext == null) {
      print("loadCefContainer cancel ${hasGeneratedContainer}");
      return ;
    };
    var size = _containerKey.currentContext!.findRenderObject()!.paintBounds;
    RenderObject renderObject =
        _containerKey.currentContext!.findRenderObject()!;
    RenderBox? box = renderObject as RenderBox?;
    if (box != null) {
      Offset position = box.localToGlobal(Offset.zero);
      // if (size.width.toInt() - 1)
      invokeLoadCef(
          position.dx.toInt() + 1,
          position.dy.toInt() - 1,
          size.width.toInt() - 1 > 0 ? size.width.toInt() - 1 : 1,
          size.height.toInt() - 1);
    } else {
      print("loadCefContainer error box is null");
    }
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
    // invokeMethod("loadCef", <String, Object>{
    //   'x':'0',
    //   'y': '0',
    //   "width": '400',
    //   "height": '400',
    // });
    invokeMethod("loadCef", <String, Object>{
      'x': x.toString(),
      'y': y.toString(),
      "width": width.toString(),
      "height": height.toString()
    });
  }
  void show() {
    invokeMethod("show", {});
  }

  void hide() {
    invokeMethod("hide", {});
  }
}

class FlutterDesktopEditor extends FlutterDesktopCefWeb {
  int callbackIdCount = 0;
  Map<int, Completer<String>> callbacks = new Map();

  Map<String, Function> invokeFunctions = new Map();


  // for try insert first
  bool needInsertFirst  = false;
  String needInsertContent = "";
  String needInsertPath = "";

  bool handleIpcRenderMessage(dynamic arguments) {
    print("handleIpcRenderMessage ${arguments} ${arguments['callbackid']}");
    if (arguments['callbackid'] != null) {
      int id = double.parse(arguments['callbackid'].toString()).toInt();
      if (callbacks[id] != null) {
        callbacks[id]!.complete(arguments['content'].toString());
      } else {
        print("handleIpcRenderMessage without callback");
      }
    } else {
      String name =
          arguments['name'] != null ? arguments['name'].toString() : '';

      Function? func = invokeFunctions[name];
      if (func != null) {
        func(arguments['data']);
      } else {

        print("handleIpcRenderMessage without function");
      }
    }
    return false;
  }

  void toggleInsertFirst() {
    needInsertFirst = !needInsertFirst;
  }


  void tryInsertFirst() {
    print("tryInsertFirst ${needInsertFirst} ${needInsertContent} ${needInsertPath}");
    if (needInsertFirst) {
      insertByContentNId(needInsertContent, needInsertPath);
      toggleInsertFirst();
    }
  }

  void insertByContentNId(String content, String editorId) {
    executeJs(
        'window.denkGetKey("insertIntoEditor")(decodeURIComponent(\"${Uri.encodeComponent(content)}\"), "${editorId}")');
  }


  void registerFunction(String name, Function func) {
    invokeFunctions[name] = func;
  }

  Future<String> getEditorContent(String currentFilePath , ) {
    Completer<String> completer = new Completer();
    // window.webkit.messageHandlers.ipcRender.postMessage({'a':1})
    int callbackId = callbackIdCount++;
    callbacks[callbackId] = completer;
    Future.delayed(Duration(milliseconds: 1000))
      .then((value) => {
        if (!completer.isCompleted) {
          completer.completeError("getEditorContent timeout")
        }
      });
    executeJs(
        "window.webkit.messageHandlers.ipcRender.postMessage({'content': window.denkGetKey('getEditorByFilePath')('${currentFilePath}').getValue(), 'callbackid': ${callbackId}}) ");
    return completer.future;
  }
}
