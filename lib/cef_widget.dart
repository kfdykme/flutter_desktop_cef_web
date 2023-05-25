library flutter_desktop_cef_web;

import 'package:flutter/material.dart';
import 'package:flutter_desktop_cef_web/flutter_desktop_cef_web.dart';

const DEFAULT_URL = "https://www.qq.com";
class CefWidget extends StatefulWidget {

  
  var web = FlutterDesktopCefWeb();

  late String url;
  CefWidget({Key? key, String url = DEFAULT_URL}) : super(key: key){
    
    web.setUrl(url);
  }

  @override
  State<StatefulWidget> createState() => CefState();
  
}

class CefState extends State<CefWidget> {
  
  
  @override
  void initState() { 
    super.initState();
    widget.web.loadCefContainer().then((value)  {
      widget.web.loadUrl(widget.url);
      widget.web.show();
    });
    
  }

  @override
  Widget build(BuildContext context) { 
    // return widget.web.generateCefContainer(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    return widget.web.generateCefContainer(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
  }

}