import Cocoa
import FlutterMacOS
import flutter_desktop_cef_web

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  public  func windowWillResize(
    _ sender: NSWindow,
    to frameSize: NSSize
) -> NSSize {
  // print("windowWillResize")
    FlutterDesktopCefWebPlugin.OnResize()
  return frameSize
}
  func windowDidResize(_ notification: Notification) {
    print(notification)
    
    FlutterDesktopCefWebPlugin.OnResize()
  }
}
