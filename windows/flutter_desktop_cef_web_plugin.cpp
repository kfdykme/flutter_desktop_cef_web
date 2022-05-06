#include "include/flutter_desktop_cef_web/flutter_desktop_cef_web_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "include/cef_command_line.h"
#include "include/cef_sandbox_win.h"

#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/wrapper/cef_helpers.h"
// #include "tests/cefsimple/simple_handler.h"

#include "core/simple_app.h"
#include "core/simple_handler.h"

#include <map>
#include <memory>
#include <sstream>

#include <iostream>
namespace
{

  class FlutterDesktopCefWebPlugin : public flutter::Plugin
  {
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    FlutterDesktopCefWebPlugin();

    virtual ~FlutterDesktopCefWebPlugin();

    void setWinId(HWND id)
    {
      winId_ = id;
    }

    HWND winId()
    {
      return winId_;
    }

  private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    HWND winId_ = 0;
  };

  void OnContextInitialized(HWND winId);
  // static
  void FlutterDesktopCefWebPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_desktop_cef_web",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterDesktopCefWebPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    plugin->setWinId(registrar->GetView()->GetNativeWindow());
    registrar->AddPlugin(std::move(plugin));
  }

  FlutterDesktopCefWebPlugin::FlutterDesktopCefWebPlugin()
  {

    // init cef
    std::cout << "FlutterDesktopCefWebPlugin::FlutterDesktopCefWebPlugin()" << std::endl;
    // CefRunMessageLoop();
    // std::thread cef = std::thread(CefRunMessageLoop);
  }

  void OnContextInitialized(HWND winId, CefRect &rc)
  {
    CEF_REQUIRE_UI_THREAD();

    CefRefPtr<CefCommandLine> command_line =
        CefCommandLine::GetGlobalCommandLine();

    // Create the browser using the Views framework if "--use-views" is specified
    // via the command-line. Otherwise, create the browser using the native
    // platform framework.
    const bool use_views = command_line->HasSwitch("use-views");

    // SimpleHandler implements browser-level callbacks.
    CefRefPtr<SimpleHandler> handler(new SimpleHandler(use_views));

    // Specify CEF browser settings here.
    CefBrowserSettings browser_settings;

    std::string url;

    // Check if a "--url=" value was provided via the command-line. If so, use
    // that instead of the default URL.
    url = command_line->GetSwitchValue("url");
    if (url.empty())
      url = "http://www.google.com";

    // Information used when creating the native window.
    CefWindowInfo window_info;

#if defined(OS_WIN)
    // On Windows we need to specify certain flags that will be passed to
    // CreateWindowEx().

    window_info.SetAsChild(winId, rc);
#endif

    // Create the first browser window.
    CefBrowserHost::CreateBrowser(window_info, handler, url, browser_settings,
                                  nullptr, nullptr);
  }

  FlutterDesktopCefWebPlugin::~FlutterDesktopCefWebPlugin() {}

  int getInt(const flutter::EncodableMap *args, std::string key)
  {
    auto status_it = args->find(flutter::EncodableValue(key));
    int res = 0;
    if (status_it != args->end())
    {
      auto str = std::get<std::string>(status_it->second);
      std::cout << "get " << key.c_str() << ": " << str.c_str();
      res = std::stoi(str);
    }
    return res;
  }

  void FlutterDesktopCefWebPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    std::cout << "FlutterDesktopCefWebPlugin::HandleMethodCall" << std::endl;
    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater())
      {
        version_stream << "10+";
      }
      else if (IsWindows8OrGreater())
      {
        version_stream << "8";
      }
      else if (IsWindows7OrGreater())
      {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else if (method_call.method_name().compare("loadCef") == 0)
    {
      const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      {
        int x = getInt(arguments, "x");
        int y = getInt(arguments, "y");
        int width = getInt(arguments, "width");
        int height = getInt(arguments, "height");

        CefRect rc(x, y, width, height);
        OnContextInitialized(winId(), rc);
      }
      result->Success(flutter::EncodableValue("ok"));
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace

void FlutterDesktopCefWebPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
  FlutterDesktopCefWebPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void FlutterDesktopCefWebPluginCefInit(HINSTANCE instance)
{
  std::cout << "FlutterDesktopCefWebPluginCefInit" << std::endl;

  // Enable High-DPI support on Windows 7 or newer.
  CefEnableHighDPISupport();

  void *sandbox_info = nullptr;

#if defined(CEF_USE_SANDBOX)
  // Manage the life span of the sandbox information object. This is necessary
  // for sandbox support on Windows. See cef_sandbox_win.h for complete details.
  CefScopedSandboxInfo scoped_sandbox;
  sandbox_info = scoped_sandbox.sandbox_info();
#endif

  // Provide CEF with command-line arguments.
  CefMainArgs main_args(instance);

  // CEF applications have multiple sub-processes (render, GPU, etc) that share
  // the same executable. This function checks the command-line and, if this is
  // a sub-process, executes the appropriate logic.
  int exit_code = CefExecuteProcess(main_args, nullptr, sandbox_info);
  if (exit_code >= 0)
  {
    // The sub-process has completed so return here.
    return;
  }

  // Parse command-line arguments for use in this method.
  CefRefPtr<CefCommandLine> command_line = CefCommandLine::CreateCommandLine();
  command_line->InitFromString(::GetCommandLineW());

  // Specify CEF global settings here.
  CefSettings settings;

  if (command_line->HasSwitch("enable-chrome-runtime"))
  {
    // Enable experimental Chrome runtime. See issue #2969 for details.
    settings.chrome_runtime = true;
  }

#if !defined(CEF_USE_SANDBOX)
  settings.no_sandbox = true;
#endif

  // SimpleApp implements application-level callbacks for the browser process.
  // It will create the first browser instance in OnContextInitialized() after
  // CEF has initialized.
  CefRefPtr<SimpleApp> app(new SimpleApp);

  // Initialize CEF.
  CefInitialize(main_args, settings, app.get(), sandbox_info);
}
void FlutterDesktopCefWebPluginCefLoopMessage()
{
  CefDoMessageLoopWork();
}
