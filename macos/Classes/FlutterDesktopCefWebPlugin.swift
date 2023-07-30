import Cocoa
import FlutterMacOS
import WebKit

class ImageSchemehandler: NSObject, WKURLSchemeHandler {
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
       let requestUrl = urlSchemeTask.request.url;
        print("urlSchemeTask webView start " + requestUrl!.absoluteString);
        if (requestUrl == nil) {
            print("urlSchemeTask url nil");
            return;
        }
        let prefix = "lowh://";
        if (!requestUrl!.absoluteString.contains(prefix)) {
            print("urlSchemeTask url not hit");
            return;
        }
        
        let absolutePath = urlSchemeTask.request.url?.absoluteString;
        var fullPath = absolutePath!.substring(from: absolutePath!.index(absolutePath!.startIndex, offsetBy: prefix.count))
        
        var fileHandle = FileHandle(forReadingAtPath: fullPath);
        
        if #available(macOS 10.15.4, *) {
            var fileData = try? fileHandle?.readToEnd()
            
            if (fileData != nil) {
                urlSchemeTask.didReceive(URLResponse(url: urlSchemeTask.request.url!, mimeType: "image/png", expectedContentLength: fileData!.count, textEncodingName: "utf-8"));
                
                urlSchemeTask.didReceive(fileData!);
                urlSchemeTask.didFinish();
                print("urlSchemeTask finish");
            } else {
                // 404 image
                
                let fullPath404 = Bundle.main.bundlePath + "/Contents/Resources/manoco-editor/404.png"
                print(fullPath404);
                fileHandle?.closeFile();
                fileHandle = FileHandle(forReadingAtPath: fullPath404);
                fileData = try! fileHandle?.readToEnd();
                urlSchemeTask.didReceive(URLResponse(url: urlSchemeTask.request.url!, mimeType: "image/png", expectedContentLength: fileData!.count, textEncodingName: "utf-8"));
                
                urlSchemeTask.didReceive(fileData!);
                urlSchemeTask.didFinish();
                
            }
            
        } else {
            
//                urlSchemeTask.didReceive(URLResponse(url: urlSchemeTask.request.url!, statusCode: 405, httpVersion: nil, headerFields: nil))
//                urlSchemeTask.didFinish();
//            urlSchemeTask.
            print("version error")
        };
        fileHandle?.closeFile()
        
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let requestUrl = urlSchemeTask.request.url;
        print("load webView stop " + requestUrl!.absoluteString);
        if (requestUrl == nil) {
            return;
        }
        if (!requestUrl!.absoluteString.contains("lowh://")) {
            return;
        }
        
    }
}

class FlutterDesktopWebViewController: NSViewController, WKUIDelegate,  WKScriptMessageHandler {
    
    
  var webView: WKWebView!

  var views: [Int: WKWebView] = [:]
  var penddingRequests: [Int: URLRequest] = [:]
  var userContentController: WKUserContentController?

  var window: NSWindow? = nil

  func createWebView(rect:CGRect?, id: Int) -> WKWebView? {
    let webConfiguration = WKWebViewConfiguration()

    if (userContentController == nil) {
      userContentController = WKUserContentController()
    }
    webConfiguration.userContentController = userContentController!
    webConfiguration.userContentController.add(self, name: "ipcRender")
      if #available(macOS 10.13, *) {
        print("kfdebug createWebView setURLSchemeHandler")
          webConfiguration.setURLSchemeHandler(ImageSchemehandler(), forURLScheme: "lowh")
      } else {
          // Fallback on earlier versions
        print("kfdebug createWebView setURLSchemeHandler nil")
      }
    if (rect != nil) {
      let mainwindow = NSApplication.shared.mainWindow!
      webView = WKWebView(frame: rect!, configuration: webConfiguration)
      webView.uiDelegate = self
      // views.updateValue(value: webView, forKey: id)
      views[id] = webView
      return webView
    }  else {
      return nil
    }
  }
    
  func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
  ) {
    // print("userContentController receive", message.body)
    FlutterDesktopCefWebPlugin.channel?.invokeMethod("ipcRender", arguments: message.body)
  }

  func getTitleHeight() -> Int {
    if (self.window != nil) {

      print(self.window!.styleMask)
    } else {
      print("getTitleHeight without window")
    }
    if (self.window?.styleMask.rawValue == 16399) {
      return 0
    } else {
      return 0
    }
  }


  override func loadView() {

  }
  

  override func viewDidLoad() {
        // super.viewDidLoad()
        print("viewDidLoad")
  }

  func loadUrl(url:String, id: Int) {

    let myURL = URL(string:url)
    let myRequest = URLRequest(url: myURL!)
    var view = views[id]
    if (view != nil) {
      view?.load(myRequest)
    } else {
      penddingRequests[id] =  myRequest
    }
  }
 
  func executeJs(jscode: String, id: Int) {
    var view = views[id]
    if (view != nil) {
      view?.evaluateJavaScript(jscode, completionHandler: nil)
    }
  }

  func loadWebView( rect: CGRect, id: Int) {

        var view = views[id]
        let mainwindow = NSApplication.shared.mainWindow!
        if (view == nil) {
          view = createWebView(rect: rect, id:id)
          if (view != nil) {
            mainwindow.contentView?.addSubview(view!)
            var req = penddingRequests[id]
            if (req != nil) {
              view!.load(req!)
              penddingRequests.removeValue(forKey: id)
            }
          }
        } else {
          view!.frame = rect
        }
  }

  func hideWebView(id: Int) {
    // 
    let mainwindow = NSApplication.shared.mainWindow
    var view = views[id]
    if (view != nil) {
      view?.removeFromSuperview();
    }
  }

  func showWebView(id: Int) {
    let mainwindow = NSApplication.shared.mainWindow
    var view = views[id]
    if (view != nil && mainwindow != nil) {
      mainwindow?.contentView?.addSubview(view!)
    }
  }
}

public class FlutterDesktopCefWebPlugin: NSObject, FlutterPlugin {
  
  var webViewController: FlutterDesktopWebViewController? = nil
  var parentView: NSView? = nil

  public static var window: NSWindow? = nil

  var controller: FlutterViewController? = nil

  static var channel:FlutterMethodChannel? = nil

  var webConfig:[Int:[String:Any]] = [:]
  
    public static func OnResize(delay: Bool = false) {
    let data: [String:Bool] = ["delay": delay]
    FlutterDesktopCefWebPlugin.channel?.invokeMethod("onResize", arguments: data)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_desktop_cef_web", binaryMessenger: registrar.messenger)
    let instance = FlutterDesktopCefWebPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    instance.webViewController = FlutterDesktopWebViewController()
    instance.webViewController!.window = FlutterDesktopCefWebPlugin.window
    FlutterDesktopCefWebPlugin.channel = channel
  }

  func getInt(argva: Any, key: String) -> Int {
    let val = getString(argva: argva, key: key)
    if (val != "") {
      return Int(val as! String)!
    } else {
      return -1
    }
  }

  func getString(argva: Any, key:String) -> String {
    let argv: [String: Any] =  argva as! [String: Any]
    let val =  argv[key]
    if (val == nil) {
      return "";
    } else {
      return val as! String
    }
  }

  public func ensureWebView(id:Int) -> Bool{
      let mainwindow = NSApplication.shared.mainWindow
      if (mainwindow != nil) {
        let argv = webConfig[id] 
        if (argv != nil) {

          let x = getInt(argva: argv as Any, key:"x")
          var y = getInt(argva: argv as Any, key:"y")
          let width = getInt(argva: argv as Any, key:"width") + 1
          let height = getInt(argva: argv as Any, key:"height") + 1
          let id = getInt(argva: argv as Any, key: "id")

          let titleHeight = webViewController != nil ? webViewController!.getTitleHeight() :0
          // print("ensureWebView with titleHeight :")
          // print(titleHeight)
          y = Int(mainwindow!.frame.height) - y - height - titleHeight
          webViewController?.loadWebView( rect:  CGRect.init(x: x, y: y, width: width, height: height), id: id)
          return true
        }
      }
      return false
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "loadCef":
      let argv:[String:Any] = call.arguments as! [String: Any]
      let id = getInt(argva: argv, key: "id")
      webConfig[id] = argv
      ensureWebView(id:id)
    case "setUrl":
      let argv:[String:Any] = call.arguments as! [String: Any]
      let url = getString(argva:argv, key:"url");
      let id = getInt(argva: argv, key: "id")
      print(call.method + ":" + url)
      ensureWebView(id:id)
      webViewController?.loadUrl(url: url, id: id)
    case "executeJs":

      let argv:[String:Any] = call.arguments as! [String: Any]
      let url = getString(argva:argv, key:"content");
      let id = getInt(argva: argv, key: "id")
      ensureWebView(id:id)
      webViewController?.showWebView(id: id)
      webViewController?.executeJs(jscode: url, id: id)
    case "hide" :
      let argv:[String:Any] = call.arguments as! [String: Any]
      let id = getInt(argva: argv, key: "id")
      webViewController?.hideWebView(id: id)
      
    case "show" :
      let argv:[String:Any] = call.arguments as! [String: Any]
      let id = getInt(argva: argv, key: "id")
      webViewController?.showWebView(id: id)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
