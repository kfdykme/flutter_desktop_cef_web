import 'package:flutter/material.dart'; 
import 'package:flutter_desktop_cef_web/cef_widget.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {  
  @override
  void initState() {
    super.initState(); 
  }
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [  
              CefWidget(url: "https://flutter.dev/",)
            ],
          ),
        ),
      ),
    );
  }
}
