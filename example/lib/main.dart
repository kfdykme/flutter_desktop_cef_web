import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_desktop_cef_web/flutter_desktop_cef_web.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  GlobalKey _myKey = new GlobalKey();
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      // platformVersion =
      //     await FlutterDesktopCefWeb.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = "platformVersion";
    });
  }

  @override
  Widget build(BuildContext context) {
    var container = Container(
      key: _myKey,
      width: 400,
      height: 400,
      color: Colors.amberAccent,
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              MaterialButton(
                onPressed: () {
                  var web = FlutterDesktopCefWeb();
                  var size =
                      _myKey.currentContext!.findRenderObject()!.paintBounds;
                  RenderObject renderObject =
                      _myKey.currentContext!.findRenderObject()!;
                  RenderBox? box = renderObject as RenderBox?;
                  Offset position = box!.localToGlobal(Offset.zero);

                  print(
                      "position ${position} semanticBounds:${renderObject.semanticBounds.size} paintBounds:${renderObject.paintBounds.size} size:${_myKey.currentContext?.size}");

                  web.loadCef(position.dx.toInt(), position.dy.toInt(),
                      size.width.toInt(), size.height.toInt());
                },
                child: Text("Load Cef"),
              ),
              container
            ],
          ),
        ),
      ),
    );
  }
}
