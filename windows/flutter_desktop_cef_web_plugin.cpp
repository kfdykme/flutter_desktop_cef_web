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
    static std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> cef_channle;
    static std::map<int, CefRefPtr<SimpleHandler>> cef_handlers;
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
    std::string default_url{};
  };

  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> FlutterDesktopCefWebPlugin::cef_channle = nullptr;
  std::map<int, CefRefPtr<SimpleHandler>> FlutterDesktopCefWebPlugin::cef_handlers{};
  // static

  void OnContextInitialized(HWND winId, CefRect &rc, int cefid, std::string default_url = "http://www.google.com");

  void FlutterDesktopCefWebPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_desktop_cef_web",
            &flutter::StandardMethodCodec::GetInstance());

    FlutterDesktopCefWebPlugin::cef_channle = channel;
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

  void OnContextInitialized(HWND winId, CefRect &rc, int cefid, std::string default_url)
  {
    CEF_REQUIRE_UI_THREAD();

    CefRefPtr<CefCommandLine> command_line =
        CefCommandLine::GetGlobalCommandLine();

    std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 1" << std::endl;
    // Create the browser using the Views framework if "--use-views" is specified
    // via the command-line. Otherwise, create the browser using the native
    // platform framework.
    // const bool use_views = command_line->HasSwitch("use-views");

    std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 2" << std::endl;
    // SimpleHandler implements browser-level callbacks.
    CefRefPtr<SimpleHandler> handler(new SimpleHandler(true));
    std::cout << "load before 5" << std::endl;
    FlutterDesktopCefWebPlugin::cef_handlers.insert({cefid, handler});
    std::cout << "load before 6" << std::endl;
    std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 3" << std::endl;
    // Specify CEF browser settings here.
    CefBrowserSettings browser_settings;

    std::string url = default_url;

    std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 4" << std::endl;
    // Information used when creating the native window.
    CefWindowInfo window_info;

#if defined(OS_WIN)
    // On Windows we need to specify certain flags that will be passed to
    // CreateWindowEx().

    window_info.SetAsChild(winId, rc);
#endif

    std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 5" << std::endl;
    // Create the first browser window.
    bool is_create_suc = CefBrowserHost::CreateBrowser(window_info, handler, url, browser_settings,
                                                       nullptr, nullptr);

    std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 6, is_create_suc: " << (is_create_suc ? "1" : "0") << std::endl;
    // std::cout << "FlutterDesktopCefWebPlugin::OnContextInitialized 7" << std::endl;
  }

  FlutterDesktopCefWebPlugin::~FlutterDesktopCefWebPlugin() {}

  std::string getString(const flutter::EncodableMap *args, std::string key)
  {
    auto status_it = args->find(flutter::EncodableValue(key));
    std::string res = "";
    if (status_it != args->end())
    {
      auto str = std::get<std::string>(status_it->second);
      std::cout << "get " << key.c_str() << ": " << str.c_str() << std::endl;
      res = str;
    }
    return res;
  }

  int getInt(const flutter::EncodableMap *args, std::string key)
  {
    int res = 0;
    auto res_str = getString(args, key);
    if (!res_str.empty())
    {
      res = std::stoi(res_str);
    }
    return res;
  }




  CefRefPtr<SimpleHandler> getCefClientById(int id)
  {

    auto handler_iterator = FlutterDesktopCefWebPlugin::cef_handlers.find(id);
    if (!FlutterDesktopCefWebPlugin::cef_handlers.empty() && handler_iterator != FlutterDesktopCefWebPlugin::cef_handlers.end())
    {
      std::cout << "load before 2" << std::endl;
      auto handler = handler_iterator->second;
      return handler;
    }
    return nullptr;
  }

  void FlutterDesktopCefWebPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    std::cout << "FlutterDesktopCefWebPlugin::HandleMethodCall" << std::endl;
    if (method_call.method_name().compare("loadCef") == 0)
    {
      const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      std::cout << "load before -2" << std::endl;
      if (arguments)
      {
        std::cout << "load before -1" << std::endl;
        int x = getInt(arguments, "x");
        int y = getInt(arguments, "y");
        int width = getInt(arguments, "width");
        int height = getInt(arguments, "height");
        int id = getInt(arguments, "id");

        auto handler = getCefClientById(id);
        if (handler != nullptr)
        {
          std::cout << "load before 2" << std::endl;
          auto browser = handler->GetBrowser();
          if (browser)
          {
            HWND wid = browser->GetHost()->GetWindowHandle();

            MoveWindow(wid, x, y, width, height, TRUE);
          }
        }
        else
        {
          std::cout << "load before 3" << std::endl;
          CefRect rc(x, y, width, height);
          OnContextInitialized(winId(), rc, id, default_url);
        }
      }
      result->Success(flutter::EncodableValue("ok"));
    }
    else if (method_call.method_name().compare("loadUrl") == 0)
    {

      const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      {
        std::string url = getString(arguments, "url");

        int id = getInt(arguments, "id");
        auto handler = getCefClientById(id);
        if (handler != nullptr)
        {
          auto browser = handler->GetBrowser();
          browser->GetMainFrame()->LoadURL(url);
          result->Success(flutter::EncodableValue("ok"));
        } else {
          result->Success(flutter::EncodableValue("load url error"));
        }
      }
    }
    else  if (method_call.method_name().compare("setUrl") == 0)
    {

      const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      {
        std::string url = getString(arguments, "url");

        default_url = url;
      }
    }
    else if (method_call.method_name().compare("hide") == 0)
    {
       const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      {
        std::string url = getString(arguments, "url");

        int id = getInt(arguments, "id");
        auto handler = getCefClientById(id);
        if (handler != nullptr)
        {
          auto browser = handler->GetBrowser();
          if (browser)
          {
            HWND wid = browser->GetHost()->GetWindowHandle();

            // MoveWindow(wid, 0, 0, 0, height, TRUE);
            ShowWindow(wid, SW_HIDE);
          }
        }
      }
    }
    else if (method_call.method_name().compare("show") == 0)
    {
       const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      {
        std::string url = getString(arguments, "url");

        int id = getInt(arguments, "id");
        auto handler = getCefClientById(id);
        if (handler != nullptr)
        {
          auto browser = handler->GetBrowser();
          if (browser)
          {
            HWND wid = browser->GetHost()->GetWindowHandle();

            // MoveWindow(wid, 0, 0, 0, height, TRUE);
            ShowWindow(wid, SW_SHOW);
          }
        }
      }
    }
    else  if (method_call.method_name().compare("executeJs") == 0)
    {

      const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      {
        std::string content = getString(arguments, "content");
  
        std::cout << "executeJs:" << content << std::endl;
        int id = getInt(arguments, "id");
        auto handler = getCefClientById(id);
        if (handler != nullptr)
        {
          auto browser = handler->GetBrowser();
          browser->GetMainFrame()->ExecuteJavaScript(
            CefString(content),
            browser->GetMainFrame()->GetURL(),
            0
          );
          result->Success(flutter::EncodableValue("ok"));
        } else {
          result->Success(flutter::EncodableValue("executeJs error"));
        } 
      }
    }
    // showDevtools
    else  if (method_call.method_name().compare("showDevtools") == 0)
    { 
      const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments)
      { 

        int id = getInt(arguments, "id");
        auto handler = getCefClientById(id);
        if (handler != nullptr)
        {
          auto browser = handler->GetBrowser(); 
          CefWindowInfo windowInfo;
          CefBrowserSettings settings;
          windowInfo.SetAsPopup(NULL, "DevTools");
          browser->GetHost()->ShowDevTools(windowInfo, handler, settings, CefPoint());
          result->Success(flutter::EncodableValue("ok"));
        } else {
          result->Success(flutter::EncodableValue("showDevtools error"));
        } 
      }
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

void FlutterDesktopCefWebPluginCefOnResize()
{
  if (FlutterDesktopCefWebPlugin::cef_channle)
  {
    FlutterDesktopCefWebPlugin::cef_channle->InvokeMethod("onResize", nullptr);
  }
  else
  {
    std::cout << "FlutterDesktopCefWebPluginCefOnResize but channel is nullptr" << std::endl;
  }
}