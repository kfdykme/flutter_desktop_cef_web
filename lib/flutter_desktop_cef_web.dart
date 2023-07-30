library flutter_desktop_cef_web;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kMethodChannelName = "flutter_desktop_cef_web";

/// A Calculator.
class FlutterDesktopCefWeb {
  late MethodChannel mMethodChannel;
  bool hasGeneratedContainer = false;
  
  final int MAX_LOAD_COUNT = 10;

  int titleHeight = 30;
  static registerWith() {
    print("FlutterDesktopCefWeb registerWith");
  }

  final GlobalKey _containerKey = GlobalKey();

  static int global_cef_id = 0;

  static List<FlutterDesktopCefWeb> allWebViews = [];

  int cefId = FlutterDesktopCefWeb.global_cef_id++;

  List<String> paddingJsCode = [];
  bool isShowing = true;
  bool hasDefaultUrl = false;

  FlutterDesktopCefWeb() {
    mMethodChannel = const MethodChannel(kMethodChannelName);
    if (Platform.isWindows) {
      titleHeight = 0;
    }
    mMethodChannel.setMethodCallHandler((call) {
      // print("${kMethodChannelName} call.method ${call.method}");
      var result = Future<dynamic>(() {
        return false;
      });

      if (call.method == "onResize") {
        // print("${kMethodChannelName} onResize  args:${call.arguments}");
        var delay  = false;
        if (call.arguments != null) {
          delay = call.arguments['delay'] as bool;
          print("${kMethodChannelName} is delay ${delay}");
        } 
        loadCefContainer(delay: delay);
      }
      if (call.method == "releaseFocus") {
        releaseFocus();
      }

      if (call.method == "ipcRender") {
        print("${kMethodChannelName} ipcRender ${call}");
        handleIpcRenderMessage(call.arguments);
      }
      return result;
    });

    FlutterDesktopCefWeb.allWebViews.add(this);
  }

  Future<bool> handleIpcRenderMessage(dynamic arguments) {
    return Future.value(false);
  }

  setUrl(String url) {
    invokeMethod("setUrl", <String, Object>{'url': url});
    hasDefaultUrl = true;
  }

  executeJs(String content) {
    if (isShowing)
      invokeMethod("executeJs", <String, Object>{'content': content});
    else {
      paddingJsCode.add(content);
    }
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
          color: Colors.transparent,
          height: height == -1 ? null : height,
        ));
    hasGeneratedContainer = true;
    return container;
  }

  bool innerloadCefContainer() {
    if (_containerKey.currentContext == null) {
      print("loadCefContainer cancel hasGeneratedContainer ${hasGeneratedContainer}");
      return false;
    }
    print("innerloadCefContainer titleHeight ${titleHeight}");
    
    var size = _containerKey.currentContext!.findRenderObject()!.paintBounds;
    RenderObject renderObject =
        _containerKey.currentContext!.findRenderObject()!;
    RenderBox? box = renderObject as RenderBox?;
    if (box != null) {
      Offset position = box.localToGlobal(Offset.zero);
      // if (size.width.toInt() - 1)
      invokeLoadCef(
          position.dx.toInt() + 1,
          position.dy.toInt() - 1 + titleHeight,
          size.width.toInt() - 1 > 0 ? size.width.toInt() - 1 : 1,
          size.height.toInt() - 1);
    } else {
      print("loadCefContainer error box is null");
    }
    return true;
  }

  Future<bool> loadCefContainer({bool delay = false , int count = 0}) {
    // print("loadCefContainer ${delay}");
    var loadCompleter = new Completer<bool>(); 
    if (delay) {
      Future.delayed(Duration(seconds: 1), () {
        var res = innerloadCefContainer();
        if (res && count < MAX_LOAD_COUNT) {
          loadCompleter.complete(delay);
        } else {
          loadCefContainer(delay: true, count: count +1);
        }
      });
    } else {
      var res = innerloadCefContainer();
      if (res) {
        loadCompleter.complete(delay);
      } else {
        loadCefContainer(delay: true, count: count +1);
      } 
    }

    return loadCompleter.future;
  }

  loadUrl(String url) {
    loadCefContainer();
    if (!hasDefaultUrl) {
      invokeMethod("loadUrl", <String, Object>{
        "url": url
      });
    } else {
      executeJs("window.open('$url','_self')");
    }
  }

  invokeMethod(String invoke, dynamic arguments) {
    arguments["id"] = cefId.toString();
    mMethodChannel.invokeMethod(invoke, arguments);
  }

  invokeLoadCef(int x, int y, int width, int height) {
    invokeMethod("loadCef", <String, Object>{
      'x': x.toString(),
      'y': y.toString(),
      "width": width.toString(),
      "height": height.toString()
    });
  }

  void toggle() {
    if (isShowing) {
      hide();
    } else {
      show();
    }
  }

  void show() {
    invokeMethod("show", {});
    isShowing = true;

    paddingJsCode.forEach((jsCode) { 
      executeJs(jsCode);
    });
    paddingJsCode = [];
  }

  void hide() {
    invokeMethod("hide", {});
    isShowing = false;
  }
  
  void releaseFocus() {
    Future.delayed(Duration(seconds: 1), () {
         allWebViews.forEach((element) { 
      element.invokeMethod("releaseFocus", {});
    });
      });
   
  }
}

class FlutterDesktopEditor extends FlutterDesktopCefWeb {
  int callbackIdCount = 0;
  Map<int, Completer<String>> callbacks = new Map();

  Map<String, Function> invokeFunctions = new Map();
  Map<String, Function> invokeFunctionsForResult = new Map();
  Map<String, dynamic> paddingInvokeFunctions = new Map();
  // for try insert first
  bool needInsertFirst = false;
  String needInsertContent = "";
  String needInsertPath = "";

  Future<bool> handleIpcRenderMessage(dynamic arguments) async {
    if (arguments.runtimeType == String) {
      print("handleIpcRenderMessage as string: ${arguments}");
      arguments = jsonDecode(arguments);
    }
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
      Function? resultFunc = invokeFunctionsForResult[name];
      if (func != null) {
        func(arguments['data']);
      } else if (resultFunc != null) {
        dynamic result = resultFunc(arguments['data']);
        if (result is Future) {
          result = await (result);
        }
        String callbackId = arguments['data']['callbackId'];
        executeJs('window.denkGetKey("invokeCallback")("$callbackId", "$result")');
      } else {
        paddingInvokeFunctions[name] = arguments;
        print("handleIpcRenderMessage without function");
      }
    }
    return false;
  }

  void toggleInsertFirst() {
    needInsertFirst = !needInsertFirst;
  }

  void tryInsertFirst() {
    if (needInsertFirst) {
      insertByContentNId(needInsertContent, needInsertPath);
      toggleInsertFirst();
    }
  }

  void insertByContentNId(String content, String editorId, { String force = 'false'}) {
    executeJs(
        'window.denkGetKey("insertIntoEditor")(decodeURIComponent(\"${Uri.encodeComponent(content)}\"), "${editorId}", ${force})');
  }

  void registerFunction(String name, Function func) {
    invokeFunctions[name] = func;
    if (paddingInvokeFunctions.containsKey(name)) {
      handleIpcRenderMessage(paddingInvokeFunctions[name]);
      paddingInvokeFunctions.remove(name);
    }
  }

  void registerFunctionWithResult(String name, Function func) {
    invokeFunctionsForResult[name] = func;
  }

  Future<String> getEditorContent(
    String currentFilePath,
  ) {
    Completer<String> completer = new Completer();
    int callbackId = callbackIdCount++;
    callbacks[callbackId] = completer;
    Future.delayed(Duration(milliseconds: 1000)).then((value) => {
          if (!completer.isCompleted)
            {completer.completeError("getEditorContent timeout")}
        });
    if (Platform.isWindows) {
      currentFilePath.replaceAll("\\", "\\\\");
    }
    executeJs(
        "window.denkGetKey('sendIpcMessage')({'content': window.denkGetKey('getEditorByFilePath')('${currentFilePath}').getValue(), 'callbackid': ${callbackId}}) ");
    return completer.future;
  }
}
